import 'package:serverpod/serverpod.dart';
import '../services/auth_service.dart';
import '../services/logger_service.dart';
import '../services/error_handler.dart';

/// Authentication Endpoint - Handles user auth flows
class AuthEndpoint extends Endpoint {
  final _auth = AuthService();
  final _errorHandler = ErrorHandler();

  // In-memory user store (replace with database in production)
  static final _users = <int, UserData>{
    1: UserData(
      id: 1,
      email: 'demo@recallbutler.ai',
      passwordHash: '', // Will be set on first run
      name: 'Demo User',
      role: 'user',
      createdAt: DateTime.now(),
    ),
  };
  static var _nextUserId = 2;
  static var _initialized = false;

  void _ensureInitialized() {
    if (!_initialized) {
      // Set demo user password
      _users[1] = _users[1]!.copyWith(
        passwordHash: _auth.hashPassword('demo123'),
      );
      _initialized = true;
    }
  }

  /// Register a new user
  Future<Map<String, dynamic>> register(
    Session session, {
    required String email,
    required String password,
    required String name,
  }) async {
    _ensureInitialized();
    
    try {
      // Validate input
      _errorHandler.validateRequired({
        'email': email,
        'password': password,
        'name': name,
      });
      _errorHandler.validateLength(password, 'password', min: 8, max: 128);
      _errorHandler.validateLength(name, 'name', min: 2, max: 100);

      // Check email format
      if (!_isValidEmail(email)) {
        return {
          'success': false,
          'error': {'code': 'INVALID_EMAIL', 'message': 'Invalid email format'},
        };
      }

      // Check if email exists
      if (_users.values.any((u) => u.email.toLowerCase() == email.toLowerCase())) {
        return {
          'success': false,
          'error': {'code': 'EMAIL_EXISTS', 'message': 'Email already registered'},
        };
      }

      // Create user
      final userId = _nextUserId++;
      final passwordHash = _auth.hashPassword(password);
      
      _users[userId] = UserData(
        id: userId,
        email: email.toLowerCase(),
        passwordHash: passwordHash,
        name: name,
        role: 'user',
        createdAt: DateTime.now(),
      );

      // Generate tokens
      final tokens = _auth.createTokenPair(
        userId: userId,
        email: email.toLowerCase(),
        role: 'user',
      );

      logger.audit(
        action: 'USER_REGISTERED',
        userId: userId.toString(),
        details: {'email': email},
      );

      return {
        'success': true,
        'user': {
          'id': userId,
          'email': email.toLowerCase(),
          'name': name,
          'role': 'user',
        },
        'tokens': tokens.toJson(),
      };
    } catch (e) {
      final error = _errorHandler.handleError(e, session, operation: 'register');
      return {'success': false, 'error': error.toJson()['error']};
    }
  }

  /// Login with email and password
  Future<Map<String, dynamic>> login(
    Session session, {
    required String email,
    required String password,
  }) async {
    _ensureInitialized();
    
    try {
      // Find user
      final user = _users.values.firstWhere(
        (u) => u.email.toLowerCase() == email.toLowerCase(),
        orElse: () => throw ValidationException('Invalid credentials'),
      );

      // Verify password
      if (!_auth.verifyPassword(password, user.passwordHash)) {
        logger.warning('Failed login attempt', 
          component: 'auth',
          context: {'email': email},
        );
        return {
          'success': false,
          'error': {'code': 'INVALID_CREDENTIALS', 'message': 'Invalid email or password'},
        };
      }

      // Update last login
      _users[user.id] = user.copyWith(lastLoginAt: DateTime.now());

      // Generate tokens
      final tokens = _auth.createTokenPair(
        userId: user.id,
        email: user.email,
        role: user.role,
      );

      logger.audit(
        action: 'USER_LOGIN',
        userId: user.id.toString(),
      );

      return {
        'success': true,
        'user': {
          'id': user.id,
          'email': user.email,
          'name': user.name,
          'role': user.role,
          'avatarUrl': user.avatarUrl,
        },
        'tokens': tokens.toJson(),
      };
    } catch (e) {
      final error = _errorHandler.handleError(e, session, operation: 'login');
      return {'success': false, 'error': error.toJson()['error']};
    }
  }

  /// Refresh access token
  Future<Map<String, dynamic>> refresh(
    Session session, {
    required String refreshToken,
  }) async {
    try {
      final tokens = _auth.refreshAccessToken(refreshToken);
      
      if (tokens == null) {
        return {
          'success': false,
          'error': {'code': 'INVALID_TOKEN', 'message': 'Invalid or expired refresh token'},
        };
      }

      return {
        'success': true,
        'tokens': tokens.toJson(),
      };
    } catch (e) {
      final error = _errorHandler.handleError(e, session, operation: 'refresh');
      return {'success': false, 'error': error.toJson()['error']};
    }
  }

  /// Logout (revoke refresh token)
  Future<Map<String, dynamic>> logout(
    Session session, {
    required String refreshToken,
  }) async {
    try {
      _auth.revokeRefreshToken(refreshToken);
      return {'success': true, 'message': 'Logged out successfully'};
    } catch (e) {
      final error = _errorHandler.handleError(e, session, operation: 'logout');
      return {'success': false, 'error': error.toJson()['error']};
    }
  }

  /// Logout from all devices
  Future<Map<String, dynamic>> logoutAll(
    Session session, {
    required String authHeader,
  }) async {
    try {
      final payload = await AuthMiddleware.requireAuth(session, authHeader);
      _auth.revokeAllUserTokens(payload.userId);
      return {'success': true, 'message': 'Logged out from all devices'};
    } catch (e) {
      final error = _errorHandler.handleError(e, session, operation: 'logoutAll');
      return {'success': false, 'error': error.toJson()['error']};
    }
  }

  /// Get current user profile
  Future<Map<String, dynamic>> me(
    Session session, {
    required String authHeader,
  }) async {
    _ensureInitialized();
    
    try {
      final payload = await AuthMiddleware.requireAuth(session, authHeader);
      final user = _users[payload.userId];

      if (user == null) {
        return {
          'success': false,
          'error': {'code': 'USER_NOT_FOUND', 'message': 'User not found'},
        };
      }

      return {
        'success': true,
        'user': {
          'id': user.id,
          'email': user.email,
          'name': user.name,
          'role': user.role,
          'avatarUrl': user.avatarUrl,
          'createdAt': user.createdAt.toIso8601String(),
          'lastLoginAt': user.lastLoginAt?.toIso8601String(),
        },
      };
    } catch (e) {
      if (e is UnauthorizedException) {
        return {
          'success': false,
          'error': {'code': 'UNAUTHORIZED', 'message': e.message},
        };
      }
      final error = _errorHandler.handleError(e, session, operation: 'me');
      return {'success': false, 'error': error.toJson()['error']};
    }
  }

  /// Update user profile
  Future<Map<String, dynamic>> updateProfile(
    Session session, {
    required String authHeader,
    String? name,
    String? avatarUrl,
  }) async {
    _ensureInitialized();
    
    try {
      final payload = await AuthMiddleware.requireAuth(session, authHeader);
      final user = _users[payload.userId];

      if (user == null) {
        return {
          'success': false,
          'error': {'code': 'USER_NOT_FOUND', 'message': 'User not found'},
        };
      }

      _users[payload.userId] = user.copyWith(
        name: name ?? user.name,
        avatarUrl: avatarUrl ?? user.avatarUrl,
      );

      logger.audit(
        action: 'PROFILE_UPDATED',
        userId: payload.userId.toString(),
      );

      return {
        'success': true,
        'user': {
          'id': user.id,
          'email': user.email,
          'name': name ?? user.name,
          'role': user.role,
          'avatarUrl': avatarUrl ?? user.avatarUrl,
        },
      };
    } catch (e) {
      final error = _errorHandler.handleError(e, session, operation: 'updateProfile');
      return {'success': false, 'error': error.toJson()['error']};
    }
  }

  /// Change password
  Future<Map<String, dynamic>> changePassword(
    Session session, {
    required String authHeader,
    required String currentPassword,
    required String newPassword,
  }) async {
    _ensureInitialized();
    
    try {
      final payload = await AuthMiddleware.requireAuth(session, authHeader);
      final user = _users[payload.userId];

      if (user == null) {
        return {
          'success': false,
          'error': {'code': 'USER_NOT_FOUND', 'message': 'User not found'},
        };
      }

      // Verify current password
      if (!_auth.verifyPassword(currentPassword, user.passwordHash)) {
        return {
          'success': false,
          'error': {'code': 'INVALID_PASSWORD', 'message': 'Current password is incorrect'},
        };
      }

      // Validate new password
      _errorHandler.validateLength(newPassword, 'password', min: 8, max: 128);

      // Update password
      _users[payload.userId] = user.copyWith(
        passwordHash: _auth.hashPassword(newPassword),
      );

      // Revoke all tokens to force re-login
      _auth.revokeAllUserTokens(payload.userId);

      logger.audit(
        action: 'PASSWORD_CHANGED',
        userId: payload.userId.toString(),
      );

      return {'success': true, 'message': 'Password changed. Please login again.'};
    } catch (e) {
      final error = _errorHandler.handleError(e, session, operation: 'changePassword');
      return {'success': false, 'error': error.toJson()['error']};
    }
  }

  /// OAuth2 callback handler (for Google/Apple sign-in)
  Future<Map<String, dynamic>> oauthCallback(
    Session session, {
    required String provider,
    required String code,
    String? state,
  }) async {
    _ensureInitialized();
    
    try {
      // In production, exchange code for tokens with provider
      // For demo, create/login user based on provider info
      
      logger.info('OAuth callback', context: {'provider': provider});

      // Simulated OAuth user info
      final email = 'oauth_user_${DateTime.now().millisecondsSinceEpoch}@example.com';
      final name = 'OAuth User';

      // Check if user exists
      var user = _users.values.firstWhere(
        (u) => u.email == email,
        orElse: () {
          // Create new user
          final userId = _nextUserId++;
          final newUser = UserData(
            id: userId,
            email: email,
            passwordHash: '', // No password for OAuth users
            name: name,
            role: 'user',
            createdAt: DateTime.now(),
            oauthProvider: provider,
          );
          _users[userId] = newUser;
          return newUser;
        },
      );

      final tokens = _auth.createTokenPair(
        userId: user.id,
        email: user.email,
        role: user.role,
      );

      return {
        'success': true,
        'user': {
          'id': user.id,
          'email': user.email,
          'name': user.name,
          'role': user.role,
        },
        'tokens': tokens.toJson(),
      };
    } catch (e) {
      final error = _errorHandler.handleError(e, session, operation: 'oauthCallback');
      return {'success': false, 'error': error.toJson()['error']};
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(email);
  }
}

/// User data model
class UserData {
  final int id;
  final String email;
  final String passwordHash;
  final String name;
  final String role;
  final String? avatarUrl;
  final DateTime createdAt;
  final DateTime? lastLoginAt;
  final String? oauthProvider;

  UserData({
    required this.id,
    required this.email,
    required this.passwordHash,
    required this.name,
    required this.role,
    this.avatarUrl,
    required this.createdAt,
    this.lastLoginAt,
    this.oauthProvider,
  });

  UserData copyWith({
    String? email,
    String? passwordHash,
    String? name,
    String? role,
    String? avatarUrl,
    DateTime? lastLoginAt,
  }) {
    return UserData(
      id: id,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      name: name ?? this.name,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      oauthProvider: oauthProvider,
    );
  }
}
