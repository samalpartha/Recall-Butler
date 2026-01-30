import 'package:serverpod/serverpod.dart';

/// Structured error response
class ApiError {
  final String code;
  final String message;
  final String? details;
  final int statusCode;
  final DateTime timestamp;
  final String? traceId;

  ApiError({
    required this.code,
    required this.message,
    this.details,
    this.statusCode = 500,
    String? traceId,
  }) : timestamp = DateTime.now(),
       traceId = traceId ?? _generateTraceId();

  static String _generateTraceId() {
    return 'rb_${DateTime.now().millisecondsSinceEpoch}_${_randomSuffix()}';
  }

  static String _randomSuffix() {
    const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
    return List.generate(6, (i) => chars[(DateTime.now().microsecond + i) % chars.length]).join();
  }

  Map<String, dynamic> toJson() => {
    'error': {
      'code': code,
      'message': message,
      'details': details,
      'statusCode': statusCode,
      'timestamp': timestamp.toIso8601String(),
      'traceId': traceId,
    }
  };
}

/// Error codes
class ErrorCodes {
  static const String unauthorized = 'UNAUTHORIZED';
  static const String forbidden = 'FORBIDDEN';
  static const String notFound = 'NOT_FOUND';
  static const String validationError = 'VALIDATION_ERROR';
  static const String serverError = 'INTERNAL_ERROR';
  static const String serviceUnavailable = 'SERVICE_UNAVAILABLE';
  static const String rateLimited = 'RATE_LIMITED';
  static const String documentProcessingFailed = 'DOCUMENT_PROCESSING_FAILED';
  static const String searchFailed = 'SEARCH_FAILED';
  static const String aiServiceError = 'AI_SERVICE_ERROR';
}

/// Global error handler service
class ErrorHandler {
  static final ErrorHandler _instance = ErrorHandler._internal();
  factory ErrorHandler() => _instance;
  ErrorHandler._internal();

  /// Log and create structured error
  ApiError handleError(
    dynamic error, 
    Session session, {
    String? operation,
    Map<String, dynamic>? context,
  }) {
    final traceId = ApiError._generateTraceId();
    
    // Log with context
    session.log(
      '[$traceId] Error in ${operation ?? 'unknown'}: $error',
      level: LogLevel.error,
    );
    
    if (context != null) {
      session.log('[$traceId] Context: $context', level: LogLevel.debug);
    }

    // Determine error type and create appropriate response
    /*
    if (error is ServerpodClientException) {
      return ApiError(
        code: ErrorCodes.serverError,
        message: 'Service communication error',
        details: error.message,
        statusCode: 503,
        traceId: traceId,
      );
    }
    */

    if (error is FormatException) {
      return ApiError(
        code: ErrorCodes.validationError,
        message: 'Invalid data format',
        details: error.message,
        statusCode: 400,
        traceId: traceId,
      );
    }

    if (error is ArgumentError) {
      return ApiError(
        code: ErrorCodes.validationError,
        message: 'Invalid argument',
        details: error.message,
        statusCode: 400,
        traceId: traceId,
      );
    }

    // Generic error
    return ApiError(
      code: ErrorCodes.serverError,
      message: 'An unexpected error occurred',
      details: error.toString(),
      statusCode: 500,
      traceId: traceId,
    );
  }

  /// Validate required fields
  void validateRequired(Map<String, dynamic> fields) {
    final missing = <String>[];
    
    fields.forEach((name, value) {
      if (value == null || (value is String && value.trim().isEmpty)) {
        missing.add(name);
      }
    });

    if (missing.isNotEmpty) {
      throw ValidationException(
        'Missing required fields: ${missing.join(', ')}',
      );
    }
  }

  /// Validate string length
  void validateLength(String value, String fieldName, {int? min, int? max}) {
    if (min != null && value.length < min) {
      throw ValidationException(
        '$fieldName must be at least $min characters',
      );
    }
    if (max != null && value.length > max) {
      throw ValidationException(
        '$fieldName must not exceed $max characters',
      );
    }
  }
}

/// Custom validation exception
class ValidationException implements Exception {
  final String message;
  ValidationException(this.message);
  
  @override
  String toString() => message;
}

/// Rate limiter for API protection
class RateLimiter {
  static final RateLimiter _instance = RateLimiter._internal();
  factory RateLimiter() => _instance;
  RateLimiter._internal();

  final Map<String, List<DateTime>> _requestLog = {};
  
  static const int maxRequestsPerMinute = 60;
  static const int maxRequestsPerHour = 1000;

  /// Check if request is allowed
  bool isAllowed(String clientId) {
    final now = DateTime.now();
    final requests = _requestLog[clientId] ?? [];
    
    // Clean old requests
    requests.removeWhere((time) => now.difference(time).inHours > 1);
    
    // Check limits
    final lastMinute = requests.where(
      (time) => now.difference(time).inMinutes < 1
    ).length;
    
    if (lastMinute >= maxRequestsPerMinute) {
      return false;
    }
    
    if (requests.length >= maxRequestsPerHour) {
      return false;
    }
    
    // Log request
    requests.add(now);
    _requestLog[clientId] = requests;
    
    return true;
  }

  /// Get remaining requests
  Map<String, int> getRemainingRequests(String clientId) {
    final now = DateTime.now();
    final requests = _requestLog[clientId] ?? [];
    
    final lastMinute = requests.where(
      (time) => now.difference(time).inMinutes < 1
    ).length;
    
    return {
      'remainingPerMinute': maxRequestsPerMinute - lastMinute,
      'remainingPerHour': maxRequestsPerHour - requests.length,
    };
  }
}
