import 'dart:io';
import 'package:serverpod/serverpod.dart';
import 'logger_service.dart';

/// CSRF Protection Middleware
/// Prevents Cross-Site Request Forgery attacks
class CsrfMiddleware {
  final Session session;
  final LoggerService logger;
  static const String _csrfTokenKey = 'csrf_token';
  static const String _csrfHeaderName = 'X-CSRF-Token';

  CsrfMiddleware(this.session) : logger = LoggerService(session);

  /// Generate CSRF token for session
  String generateToken() {
    final token = _generateSecureToken();
    session.setString(_csrfTokenKey, token);
    return token;
  }

  /// Verify CSRF token from request
  Future<bool> verifyToken(String? providedToken) async {
    if (providedToken == null || providedToken.isEmpty) {
      logger.warn('CSRF token missing from request');
      return false;
    }

    final sessionToken = session.getString(_csrfTokenKey);
    if (sessionToken == null) {
      logger.warn('No CSRF token in session');
      return false;
    }

    // Constant-time comparison to prevent timing attacks
    if (!_constantTimeCompare(providedToken, sessionToken)) {
      logger.warn('CSRF token mismatch', {'provided': providedToken});
      return false;
    }

    return true;
  }

  /// Middleware to protect state-changing operations
  Future<void> protect() async {
    // Only check CSRF for state-changing methods
    if (_isStateMutatingMethod(session.httpRequest.method)) {
      final csrfToken = session.httpRequest.headers.value(_csrfHeaderName)
          ?? session.httpRequest.uri.queryParameters['csrf_token'];

      if (!await verifyToken(csrfToken)) {
        throw ForbiddenException('Invalid CSRF token');
      }
    }
  }

  bool _isStateMutatingMethod(String method) {
    return ['POST', 'PUT', 'PATCH', 'DELETE'].contains(method.toUpperCase());
  }

  String _generateSecureToken() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }

  bool _constantTimeCompare(String a, String b) {
    if (a.length != b.length) return false;
    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}

/// Input Sanitization Middleware
class SanitizationMiddleware {
  final Session session;
  final LoggerService logger;

  SanitizationMiddleware(this.session) : logger = LoggerService(session);

  /// Sanitize request input
  Map<String, dynamic> sanitizeInput(Map<String, dynamic> input) {
    final sanitized = <String, dynamic>{};

    input.forEach((key, value) {
      sanitized[key] = _sanitizeValue(value, key);
    });

    return sanitized;
  }

  dynamic _sanitizeValue(dynamic value, String fieldName) {
    if (value == null) return null;

    if (value is String) {
      return _sanitizeString(value, fieldName);
    } else if (value is Map) {
      return sanitizeInput(value as Map<String, dynamic>);
    } else if (value is List) {
      return value.map((item) => _sanitizeValue(item, fieldName)).toList();
    }

    return value;
  }

  String _sanitizeString(String input, String fieldName) {
    var sanitized = input;

    // Remove null bytes
    sanitized = sanitized.replaceAll('\u0000', '');

    // Trim whitespace
    sanitized = sanitized.trim();

    // Check length limits
    const maxLength = 10000;
    if (sanitized.length > maxLength) {
      logger.warn('Input exceeds max length', {
        'field': fieldName,
        'length': sanitized.length,
      });
      sanitized = sanitized.substring(0, maxLength);
    }

    // Detect SQL injection attempts
    if (_containsSqlInjection(sanitized)) {
      logger.warn('Possible SQL injection attempt', {
        'field': fieldName,
        'input': sanitized.substring(0, min(100, sanitized.length)),
      });
      throw BadRequestException('Invalid input detected');
    }

    // Detect XSS attempts
    if (_containsXss(sanitized)) {
      logger.warn('Possible XSS attempt', {
        'field': fieldName,
        'input': sanitized.substring(0, min(100, sanitized.length)),
      });
      // Escape HTML entities
      sanitized = _escapeHtml(sanitized);
    }

    return sanitized;
  }

  bool _containsSqlInjection(String input) {
    final sqlPatterns = [
      RegExp(r"(\bOR\b|\bAND\b).*?=.*?", caseSensitive: false),
      RegExp(r"';.*?--", caseSensitive: false),
      RegExp(r"\bDROP\b|\bDELETE\b|\bINSERT\b|\bUPDATE\b",
          caseSensitive: false),
      RegExp(r"UNION.*?SELECT", caseSensitive: false),
    ];

    return sqlPatterns.any((pattern) => pattern.hasMatch(input));
  }

  bool _containsXss(String input) {
    final xssPatterns = [
      RegExp(r"<script[^>]*>.*?</script>", caseSensitive: false),
      RegExp(r"javascript:", caseSensitive: false),
      RegExp(r"on\w+\s*=", caseSensitive: false), // Event handlers
    ];

    return xssPatterns.any((pattern) => pattern.hasMatch(input));
  }

  String _escapeHtml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;');
  }
}

/// Security Headers Middleware
class SecurityHeadersMiddleware {
  static void apply(HttpResponse response) {
    // Prevent clickjacking
    response.headers.set('X-Frame-Options', 'DENY');

    // Prevent MIME sniffing
    response.headers.set('X-Content-Type-Options', 'nosniff');

    // Enable XSS filtering
    response.headers.set('X-XSS-Protection', '1; mode=block');

    // HSTS: Force HTTPS
    response.headers.set(
      'Strict-Transport-Security',
      'max-age=31536000; includeSubDomains; preload',
    );

    // Content Security Policy
    response.headers.set(
      'Content-Security-Policy',
      "default-src 'self'; "
      "script-src 'self' 'unsafe-inline' 'unsafe-eval'; "
      "style-src 'self' 'unsafe-inline'; "
      "img-src 'self' data: https:; "
      "font-src 'self' data:; "
      "connect-src 'self' https://*.openrouter.ai; "
      "frame-ancestors 'none';",
    );

    // Referrer Policy
    response.headers.set('Referrer-Policy', 'strict-origin-when-cross-origin');

    // Permissions Policy
    response.headers.set(
      'Permissions-Policy',
      'geolocation=(), microphone=(), camera=()',
    );
  }
}

/// Rate Limiting Middleware
class RateLimitMiddleware {
  final Session session;
  final LoggerService logger;
  final Map<String, List<DateTime>> _requestLog = {};
  final int _maxRequests;
  final Duration _timeWindow;

  RateLimitMiddleware(
    this.session, {
    int maxRequests = 100,
    Duration timeWindow = const Duration(minutes: 1),
  })  : _maxRequests = maxRequests,
        _timeWindow = timeWindow,
        logger = LoggerService(session);

  /// Check if request is within rate limit
  Future<bool> isAllowed() async {
    final identifier = _getClientIdentifier();
    final now = DateTime.now();
    final windowStart = now.subtract(_timeWindow);

    // Get or create request log for this identifier
    final requests = _requestLog.putIfAbsent(identifier, () => []);

    // Remove old requests outside the time window
    requests.removeWhere((time) => time.isBefore(windowStart));

    // Check if limit exceeded
    if (requests.length >= _maxRequests) {
      logger.warn('Rate limit exceeded', {
        'identifier': identifier,
        'requests': requests.length,
      });
      return false;
    }

    // Record this request
    requests.add(now);
    return true;
  }

  /// Get remaining requests in current window
  int getRemainingRequests() {
    final identifier = _getClientIdentifier();
    final requests = _requestLog[identifier] ?? [];
    return max(0, _maxRequests - requests.length);
  }

  /// Get time until rate limit resets
  Duration getTimeUntilReset() {
    final identifier = _getClientIdentifier();
    final requests = _requestLog[identifier] ?? [];
    
    if (requests.isEmpty) return Duration.zero;
    
    final oldestRequest = requests.first;
    final resetTime = oldestRequest.add(_timeWindow);
    final now = DateTime.now();
    
    return resetTime.isAfter(now) ? resetTime.difference(now) : Duration.zero;
  }

  String _getClientIdentifier() {
    // Use IP address + User-Agent for identification
    final ipAddress = session.httpRequest.connectionInfo?.remoteAddress.address ?? 'unknown';
    final userAgent = session.httpRequest.headers.value('user-agent') ?? 'unknown';
    return '$ipAddress:${userAgent.hashCode}';
  }

  /// Apply rate limiting with proper headers
  Future<void> apply() async {
    if (!await isAllowed()) {
      final resetTime = getTimeUntilReset();
      throw TooManyRequestsException(
        'Rate limit exceeded. Try again in ${resetTime.inSeconds} seconds.',
        retryAfter: resetTime.inSeconds,
      );
    }

    // Add rate limit headers to response
    final remaining = getRemainingRequests();
    final resetTime = getTimeUntilReset();
    
    session.httpRequest.response.headers.set('X-RateLimit-Limit', _maxRequests.toString());
    session.httpRequest.response.headers.set('X-RateLimit-Remaining', remaining.toString());
    session.httpRequest.response.headers.set('X-RateLimit-Reset', resetTime.inSeconds.toString());
  }
}

// Custom Exceptions
class ForbiddenException implements Exception {
  final String message;
  ForbiddenException(this.message);
  
  @override
  String toString() => 'ForbiddenException: $message';
}

class BadRequestException implements Exception {
  final String message;
  BadRequestException(this.message);
  
  @override
  String toString() => 'BadRequestException: $message';
}

class TooManyRequestsException implements Exception {
  final String message;
  final int retryAfter;
  
  TooManyRequestsException(this.message, {required this.retryAfter});
  
  @override
  String toString() => 'TooManyRequestsException: $message (retry after $retryAfter seconds)';
}
