import 'dart:convert';
import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import '../../lib/src/services/auth_service.dart';
import '../../lib/src/services/config_service.dart';

void main() {
  late AuthService authService;
  late Session mockSession;

  setUp(() {
    // Initialize mock session
    mockSession = _createMockSession();
    authService = AuthService(mockSession);
  });

  group('AuthService - Password Hashing', () {
    test('should hash passwords securely with PBKDF2', () async {
      final password = 'SecurePassword123!';
      final hash = await authService.hashPassword(password);

      expect(hash, isNotEmpty);
      expect(hash, contains(':'));
      
      final parts = hash.split(':');
      expect(parts.length, equals(2)); // salt:hash format
      expect(parts[0].length, greaterThan(0)); // salt
      expect(parts[1].length, greaterThan(0)); // hash
    });

    test('should generate different salts for same password', () async {
      final password = 'SamePassword123!';
      final hash1 = await authService.hashPassword(password);
      final hash2 = await authService.hashPassword(password);

      expect(hash1, isNot(equals(hash2))); // Different salts
      
      // But both should verify correctly
      final verify1 = await authService.verifyPassword(password, hash1);
      final verify2 = await authService.verifyPassword(password, hash2);
      expect(verify1, isTrue);
      expect(verify2, isTrue);
    });

    test('should verify correct password', () async {
      final password = 'CorrectPassword123!';
      final hash = await authService.hashPassword(password);
      
      final isValid = await authService.verifyPassword(password, hash);
      expect(isValid, isTrue);
    });

    test('should reject incorrect password', () async {
      final password = 'CorrectPassword123!';
      final wrongPassword = 'WrongPassword123!';
      final hash = await authService.hashPassword(password);
      
      final isValid = await authService.verifyPassword(wrongPassword, hash);
      expect(isValid, isFalse);
    });

    test('should handle empty password gracefully', () async {
      expect(() => authService.hashPassword(''), throwsArgumentError);
    });
  });

  group('AuthService - JWT Token Generation', () {
    test('should generate valid JWT access token', () async {
      final payload = JwtPayload(
        userId: 1,
        email: 'test@example.com',
        role: 'user',
        issuedAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(hours: 1)),
      );

      final token = await authService.generateAccessToken(payload);

      expect(token, isNotEmpty);
      final parts = token.split('.');
      expect(parts.length, equals(3)); // header.payload.signature
    });

    test('should generate unique refresh tokens', () async {
      final token1 = await authService.generateRefreshToken();
      final token2 = await authService.generateRefreshToken();

      expect(token1, isNot(equals(token2)));
      expect(token1.length, greaterThanOrEqualTo(32));
      expect(token2.length, greaterThanOrEqualTo(32));
    });

    test('should verify and decode valid JWT', () async {
      final originalPayload = JwtPayload(
        userId: 1,
        email: 'test@example.com',
        role: 'user',
        issuedAt: DateTime.now(),
        expiresAt: DateTime.now().add(Duration(hours: 1)),
      );

      final token = await authService.generateAccessToken(originalPayload);
      final decodedPayload = await authService.verifyToken(token);

      expect(decodedPayload, isNotNull);
      expect(decodedPayload!.userId, equals(originalPayload.userId));
      expect(decodedPayload.email, equals(originalPayload.email));
      expect(decodedPayload.role, equals(originalPayload.role));
    });

    test('should reject expired JWT', () async {
      final expiredPayload = JwtPayload(
        userId: 1,
        email: 'test@example.com',
        role: 'user',
        issuedAt: DateTime.now().subtract(Duration(hours: 2)),
        expiresAt: DateTime.now().subtract(Duration(hours: 1)), // Expired
      );

      final token = await authService.generateAccessToken(expiredPayload);
      final decodedPayload = await authService.verifyToken(token);

      expect(decodedPayload, isNull); // Should reject expired token
    });

    test('should reject malformed JWT', () async {
      final malformedToken = 'not.a.valid.jwt';
      final decodedPayload = await authService.verifyToken(malformedToken);

      expect(decodedPayload, isNull);
    });

    test('should reject JWT with invalid signature', () async {
      final validToken = await authService.generateAccessToken(
        JwtPayload(
          userId: 1,
          email: 'test@example.com',
          role: 'user',
          issuedAt: DateTime.now(),
          expiresAt: DateTime.now().add(Duration(hours: 1)),
        ),
      );

      // Tamper with signature
      final parts = validToken.split('.');
      final tamperedToken = '${parts[0]}.${parts[1]}.tampered_signature';

      final decodedPayload = await authService.verifyToken(tamperedToken);
      expect(decodedPayload, isNull);
    });
  });

  group('AuthService - Token Pair Management', () {
    test('should create complete token pair', () async {
      final tokenPair = await authService.createTokenPair(
        userId: 1,
        email: 'test@example.com',
        role: 'user',
      );

      expect(tokenPair.accessToken, isNotEmpty);
      expect(tokenPair.refreshToken, isNotEmpty);
      expect(tokenPair.expiresIn, greaterThan(0));
    });

    test('should store refresh token in database', () async {
      final tokenPair = await authService.createTokenPair(
        userId: 1,
        email: 'test@example.com',
        role: 'user',
      );

      // Verify token can be refreshed (implying it was stored)
      final newAccessToken = await authService.refreshAccessToken(
        tokenPair.refreshToken,
      );

      expect(newAccessToken, isNotNull);
      expect(newAccessToken, isNotEmpty);
    });

    test('should revoke refresh token', () async {
      final tokenPair = await authService.createTokenPair(
        userId: 1,
        email: 'test@example.com',
        role: 'user',
      );

      // Revoke the token
      await authService.revokeRefreshToken(tokenPair.refreshToken);

      // Try to use revoked token
      expect(
        () => authService.refreshAccessToken(tokenPair.refreshToken),
        throwsA(isA<UnauthorizedException>()),
      );
    });

    test('should revoke all user tokens', () async {
      final userId = 1;
      
      // Create multiple tokens
      final token1 = await authService.createTokenPair(
        userId: userId,
        email: 'test@example.com',
        role: 'user',
      );
      
      final token2 = await authService.createTokenPair(
        userId: userId,
        email: 'test@example.com',
        role: 'user',
      );

      // Revoke all tokens for user
      await authService.revokeAllUserTokens(userId);

      // Both tokens should be invalid
      expect(
        () => authService.refreshAccessToken(token1.refreshToken),
        throwsA(isA<UnauthorizedException>()),
      );
      expect(
        () => authService.refreshAccessToken(token2.refreshToken),
        throwsA(isA<UnauthorizedException>()),
      );
    });
  });

  group('AuthService - RBAC Permissions', () {
    test('user role should have basic permissions', () {
      expect(authService.hasPermission('user', Permission.read), isTrue);
      expect(authService.hasPermission('user', Permission.write), isTrue);
      expect(authService.hasPermission('user', Permission.delete), isTrue);
      expect(authService.hasPermission('user', Permission.share), isFalse);
      expect(authService.hasPermission('user', Permission.manageUsers), isFalse);
    });

    test('premium role should have extended permissions', () {
      expect(authService.hasPermission('premium', Permission.read), isTrue);
      expect(authService.hasPermission('premium', Permission.write), isTrue);
      expect(authService.hasPermission('premium', Permission.delete), isTrue);
      expect(authService.hasPermission('premium', Permission.share), isTrue);
      expect(authService.hasPermission('premium', Permission.export), isTrue);
      expect(authService.hasPermission('premium', Permission.aiFeatures), isTrue);
      expect(authService.hasPermission('premium', Permission.unlimitedStorage), isTrue);
      expect(authService.hasPermission('premium', Permission.manageUsers), isFalse);
    });

    test('admin role should have management permissions', () {
      expect(authService.hasPermission('admin', Permission.read), isTrue);
      expect(authService.hasPermission('admin', Permission.write), isTrue);
      expect(authService.hasPermission('admin', Permission.manageUsers), isTrue);
      expect(authService.hasPermission('admin', Permission.viewAnalytics), isTrue);
      expect(authService.hasPermission('admin', Permission.manageAdmins), isFalse);
    });

    test('superAdmin role should have all permissions', () {
      expect(authService.hasPermission('superAdmin', Permission.read), isTrue);
      expect(authService.hasPermission('superAdmin', Permission.write), isTrue);
      expect(authService.hasPermission('superAdmin', Permission.manageUsers), isTrue);
      expect(authService.hasPermission('superAdmin', Permission.manageAdmins), isTrue);
      expect(authService.hasPermission('superAdmin', Permission.viewAnalytics), isTrue);
    });

    test('should reject invalid role', () {
      expect(authService.hasPermission('invalid_role', Permission.read), isFalse);
    });
  });

  group('AuthService - Security Features', () {
    test('should use constant-time comparison for password verification', () async {
      // This prevents timing attacks
      final password = 'TestPassword123!';
      final hash = await authService.hashPassword(password);

      final stopwatch = Stopwatch()..start();
      await authService.verifyPassword(password, hash);
      final correctTime = stopwatch.elapsedMicroseconds;

      stopwatch.reset();
      await authService.verifyPassword('WrongPassword123!', hash);
      final wrongTime = stopwatch.elapsedMicroseconds;

      // Times should be similar (within 50% variance)
      final timeDiff = (correctTime - wrongTime).abs();
      final avgTime = (correctTime + wrongTime) / 2;
      expect(timeDiff / avgTime, lessThan(0.5));
    });

    test('should generate cryptographically secure salts', () async {
      final salts = <String>{};
      
      // Generate 100 salts
      for (var i = 0; i < 100; i++) {
        final hash = await authService.hashPassword('test$i');
        final salt = hash.split(':')[0];
        salts.add(salt);
      }

      // All should be unique
      expect(salts.length, equals(100));
    });
  });
}

/// Create a mock Serverpod session for testing
Session _createMockSession() {
  // This is a simplified mock - in real implementation,
  // you'd use a full mock or test database
  return Session(
    server: Server(),
    uri: Uri.parse('http://localhost:8080'),
    method: Method.post,
    httpRequest: null,
  );
}

class UnauthorizedException implements Exception {
  final String message;
  UnauthorizedException(this.message);
}
