import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import 'package:serverpod/serverpod.dart';
import 'config_service.dart';
import 'logger_service.dart';

/// JWT Token payload
class JwtPayload {
  final int userId;
  final String email;
  final String role;
  final DateTime issuedAt;
  final DateTime expiresAt;
  final String? sessionId;

  JwtPayload({
    required this.userId,
    required this.email,
    required this.role,
    required this.issuedAt,
    required this.expiresAt,
    this.sessionId,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
    'sub': userId.toString(),
    'email': email,
    'role': role,
    'iat': issuedAt.millisecondsSinceEpoch ~/ 1000,
    'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
    if (sessionId != null) 'sid': sessionId,
  };

  factory JwtPayload.fromJson(Map<String, dynamic> json) {
    return JwtPayload(
      userId: int.parse(json['sub']),
      email: json['email'],
      role: json['role'] ?? 'user',
      issuedAt: DateTime.fromMillisecondsSinceEpoch((json['iat'] as int) * 1000),
      expiresAt: DateTime.fromMillisecondsSinceEpoch((json['exp'] as int) * 1000),
      sessionId: json['sid'],
    );
  }
}

/// Token pair response
class TokenPair {
  final String accessToken;
  final String refreshToken;
  final DateTime accessExpiresAt;
  final DateTime refreshExpiresAt;

  TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.accessExpiresAt,
    required this.refreshExpiresAt,
  });

  Map<String, dynamic> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'accessExpiresAt': accessExpiresAt.toIso8601String(),
    'refreshExpiresAt': refreshExpiresAt.toIso8601String(),
    'tokenType': 'Bearer',
  };
}

/// User roles for RBAC
enum UserRole {
  user,
  premium,
  admin,
  superAdmin;

  static UserRole fromString(String role) {
    return UserRole.values.firstWhere(
      (r) => r.name == role,
      orElse: () => UserRole.user,
    );
  }

  bool hasPermission(Permission permission) {
    switch (this) {
      case UserRole.superAdmin:
        return true;
      case UserRole.admin:
        return permission != Permission.manageAdmins;
      case UserRole.premium:
        return [
          Permission.read,
          Permission.write,
          Permission.delete,
          Permission.share,
          Permission.export,
          Permission.aiFeatures,
          Permission.unlimitedStorage,
        ].contains(permission);
      case UserRole.user:
        return [
          Permission.read,
          Permission.write,
          Permission.delete,
          Permission.aiFeatures,
        ].contains(permission);
    }
  }
}

/// Permissions for RBAC
enum Permission {
  read,
  write,
  delete,
  share,
  export,
  aiFeatures,
  unlimitedStorage,
  manageUsers,
  manageAdmins,
  viewAnalytics,
}

/// Authentication Service with JWT
class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final _config = ConfigService();
  final _refreshTokens = <String, RefreshTokenData>{};
  final _random = Random.secure();

  /// Hash password with Argon2-like approach (using PBKDF2 for compatibility)
  String hashPassword(String password, {String? salt}) {
    final saltBytes = salt != null 
        ? base64Decode(salt) 
        : _generateSalt();
    
    final key = _pbkdf2(password, saltBytes, 100000, 32);
    final saltB64 = base64Encode(saltBytes);
    final hashB64 = base64Encode(key);
    
    return '$saltB64:$hashB64';
  }

  /// Verify password against hash
  bool verifyPassword(String password, String storedHash) {
    final parts = storedHash.split(':');
    if (parts.length != 2) return false;
    
    final salt = parts[0];
    final expectedHash = hashPassword(password, salt: salt);
    
    return _constantTimeCompare(storedHash, expectedHash);
  }

  /// Generate JWT access token
  String generateAccessToken(JwtPayload payload) {
    final header = {'alg': 'HS256', 'typ': 'JWT'};
    final headerB64 = _base64UrlEncode(jsonEncode(header));
    final payloadB64 = _base64UrlEncode(jsonEncode(payload.toJson()));
    
    final signature = _sign('$headerB64.$payloadB64');
    
    return '$headerB64.$payloadB64.$signature';
  }

  /// Generate refresh token
  String generateRefreshToken() {
    final bytes = List<int>.generate(32, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  /// Verify and decode JWT
  JwtPayload? verifyToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;

      final headerB64 = parts[0];
      final payloadB64 = parts[1];
      final signature = parts[2];

      // Verify signature
      final expectedSignature = _sign('$headerB64.$payloadB64');
      if (!_constantTimeCompare(signature, expectedSignature)) {
        logger.warning('Invalid token signature');
        return null;
      }

      // Decode payload
      final payloadJson = jsonDecode(_base64UrlDecode(payloadB64));
      final payload = JwtPayload.fromJson(payloadJson);

      // Check expiration
      if (payload.isExpired) {
        logger.debug('Token expired');
        return null;
      }

      return payload;
    } catch (e) {
      logger.error('Token verification failed', error: e);
      return null;
    }
  }

  /// Create token pair for user
  TokenPair createTokenPair({
    required int userId,
    required String email,
    required String role,
  }) {
    final now = DateTime.now();
    final accessExpiry = now.add(Duration(hours: _config.jwtExpirationHours));
    final refreshExpiry = now.add(const Duration(days: 30));
    final sessionId = _generateSessionId();

    final payload = JwtPayload(
      userId: userId,
      email: email,
      role: role,
      issuedAt: now,
      expiresAt: accessExpiry,
      sessionId: sessionId,
    );

    final accessToken = generateAccessToken(payload);
    final refreshToken = generateRefreshToken();

    // Store refresh token
    _refreshTokens[refreshToken] = RefreshTokenData(
      userId: userId,
      email: email,
      role: role,
      sessionId: sessionId,
      expiresAt: refreshExpiry,
    );

    logger.audit(
      action: 'TOKEN_ISSUED',
      userId: userId.toString(),
      details: {'sessionId': sessionId},
    );

    return TokenPair(
      accessToken: accessToken,
      refreshToken: refreshToken,
      accessExpiresAt: accessExpiry,
      refreshExpiresAt: refreshExpiry,
    );
  }

  /// Refresh access token
  TokenPair? refreshAccessToken(String refreshToken) {
    final data = _refreshTokens[refreshToken];
    if (data == null || data.isExpired) {
      logger.warning('Invalid or expired refresh token');
      return null;
    }

    // Rotate refresh token (security best practice)
    _refreshTokens.remove(refreshToken);

    return createTokenPair(
      userId: data.userId,
      email: data.email,
      role: data.role,
    );
  }

  /// Revoke refresh token (logout)
  void revokeRefreshToken(String refreshToken) {
    final data = _refreshTokens.remove(refreshToken);
    if (data != null) {
      logger.audit(
        action: 'TOKEN_REVOKED',
        userId: data.userId.toString(),
        details: {'sessionId': data.sessionId},
      );
    }
  }

  /// Revoke all tokens for user (logout everywhere)
  void revokeAllUserTokens(int userId) {
    _refreshTokens.removeWhere((_, data) => data.userId == userId);
    logger.audit(
      action: 'ALL_TOKENS_REVOKED',
      userId: userId.toString(),
    );
  }

  /// Check if user has permission
  bool hasPermission(String role, Permission permission) {
    return UserRole.fromString(role).hasPermission(permission);
  }

  // Private helpers
  Uint8List _generateSalt() {
    return Uint8List.fromList(
      List.generate(16, (_) => _random.nextInt(256)),
    );
  }

  Uint8List _pbkdf2(String password, Uint8List salt, int iterations, int keyLength) {
    final hmac = Hmac(sha256, utf8.encode(password));
    var result = Uint8List(keyLength);
    var block = 1;
    var pos = 0;

    while (pos < keyLength) {
      var u = hmac.convert([...salt, (block >> 24) & 0xff, (block >> 16) & 0xff, (block >> 8) & 0xff, block & 0xff]).bytes;
      var t = Uint8List.fromList(u);

      for (var i = 1; i < iterations; i++) {
        u = hmac.convert(u).bytes;
        for (var j = 0; j < t.length; j++) {
          t[j] ^= u[j];
        }
      }

      for (var i = 0; i < t.length && pos < keyLength; i++, pos++) {
        result[pos] = t[i];
      }
      block++;
    }

    return result;
  }

  String _sign(String data) {
    final hmac = Hmac(sha256, utf8.encode(_config.jwtSecret));
    final digest = hmac.convert(utf8.encode(data));
    return base64UrlEncode(digest.bytes);
  }

  String _base64UrlEncode(String data) {
    return base64UrlEncode(utf8.encode(data)).replaceAll('=', '');
  }

  String _base64UrlDecode(String data) {
    var padded = data;
    while (padded.length % 4 != 0) {
      padded += '=';
    }
    return utf8.decode(base64UrlDecode(padded));
  }

  bool _constantTimeCompare(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  String _generateSessionId() {
    final bytes = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes).substring(0, 22);
  }
}

/// Refresh token storage data
class RefreshTokenData {
  final int userId;
  final String email;
  final String role;
  final String sessionId;
  final DateTime expiresAt;

  RefreshTokenData({
    required this.userId,
    required this.email,
    required this.role,
    required this.sessionId,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// Auth middleware for protected endpoints
class AuthMiddleware {
  static final _auth = AuthService();

  /// Extract and verify token from request
  static JwtPayload? authenticate(Session session) {
    // In Serverpod, we'd extract from method call info
    // For now, this is a helper method
    return null;
  }

  /// Require authentication
  static Future<JwtPayload> requireAuth(Session session, String? authHeader) async {
    if (authHeader == null || !authHeader.startsWith('Bearer ')) {
      throw UnauthorizedException('Missing or invalid authorization header');
    }

    final token = authHeader.substring(7);
    final payload = _auth.verifyToken(token);

    if (payload == null) {
      throw UnauthorizedException('Invalid or expired token');
    }

    return payload;
  }

  /// Require specific permission
  static Future<JwtPayload> requirePermission(
    Session session,
    String? authHeader,
    Permission permission,
  ) async {
    final payload = await requireAuth(session, authHeader);

    if (!_auth.hasPermission(payload.role, permission)) {
      throw ForbiddenException('Insufficient permissions');
    }

    return payload;
  }
}

/// Custom exceptions
class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
  @override
  String toString() => message;
}

class ForbiddenException implements Exception {
  final String message;
  ForbiddenException(this.message);
  @override
  String toString() => message;
}
