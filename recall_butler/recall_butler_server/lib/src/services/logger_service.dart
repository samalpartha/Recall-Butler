import 'dart:convert';
import 'dart:io';
import 'config_service.dart';

/// Structured logging service
class LoggerService {
  static final LoggerService _instance = LoggerService._internal();
  factory LoggerService() => _instance;
  LoggerService._internal();

  final _config = ConfigService();
  IOSink? _fileSink;

  /// Log levels
  static const int levelDebug = 0;
  static const int levelInfo = 1;
  static const int levelWarning = 2;
  static const int levelError = 3;

  int get _currentLevel {
    switch (_config.logLevel.toLowerCase()) {
      case 'debug':
        return levelDebug;
      case 'info':
        return levelInfo;
      case 'warning':
        return levelWarning;
      case 'error':
        return levelError;
      default:
        return levelInfo;
    }
  }

  /// Initialize file logging if enabled
  Future<void> initialize() async {
    if (_config.logToFile) {
      final logDir = Directory('logs');
      if (!await logDir.exists()) {
        await logDir.create(recursive: true);
      }
      
      final logFile = File('logs/recall_butler_${DateTime.now().toIso8601String().split('T')[0]}.log');
      _fileSink = logFile.openWrite(mode: FileMode.append);
    }
  }

  /// Debug log
  void debug(String message, {String? component, Map<String, dynamic>? context}) {
    _log(levelDebug, 'DEBUG', message, component: component, context: context);
  }

  /// Info log
  void info(String message, {String? component, Map<String, dynamic>? context}) {
    _log(levelInfo, 'INFO', message, component: component, context: context);
  }

  /// Warning log
  void warning(String message, {String? component, Map<String, dynamic>? context}) {
    _log(levelWarning, 'WARN', message, component: component, context: context);
  }

  /// Error log
  void error(String message, {String? component, Map<String, dynamic>? context, dynamic error, StackTrace? stackTrace}) {
    final ctx = context ?? {};
    if (error != null) ctx['error'] = error.toString();
    if (stackTrace != null) ctx['stackTrace'] = stackTrace.toString().split('\n').take(5).toList();
    
    _log(levelError, 'ERROR', message, component: component, context: ctx);
  }

  /// Request log
  void request({
    required String method,
    required String path,
    required int statusCode,
    required int durationMs,
    String? userId,
    String? traceId,
  }) {
    _log(levelInfo, 'REQUEST', '$method $path', context: {
      'method': method,
      'path': path,
      'statusCode': statusCode,
      'durationMs': durationMs,
      if (userId != null) 'userId': userId,
      if (traceId != null) 'traceId': traceId,
    });
  }

  /// Audit log for important actions
  void audit({
    required String action,
    required String userId,
    String? resourceType,
    String? resourceId,
    Map<String, dynamic>? details,
  }) {
    _log(levelInfo, 'AUDIT', action, context: {
      'userId': userId,
      if (resourceType != null) 'resourceType': resourceType,
      if (resourceId != null) 'resourceId': resourceId,
      if (details != null) ...details,
    });
  }

  void _log(int level, String levelStr, String message, {String? component, Map<String, dynamic>? context}) {
    if (level < _currentLevel) return;

    final timestamp = DateTime.now().toUtc().toIso8601String();
    
    final logEntry = {
      'timestamp': timestamp,
      'level': levelStr,
      'message': message,
      'service': 'recall-butler',
      if (component != null) 'component': component,
      if (context != null && context.isNotEmpty) 'context': context,
    };

    final jsonLine = jsonEncode(logEntry);
    
    // Console output
    if (_config.isDevelopment) {
      // Pretty print in development
      final emoji = _getEmoji(levelStr);
      final color = _getColor(levelStr);
      print('$color$emoji [$levelStr] $message${context != null ? ' $context' : ''}\x1B[0m');
    } else {
      // JSON in production
      print(jsonLine);
    }

    // File output
    _fileSink?.writeln(jsonLine);
  }

  String _getEmoji(String level) {
    switch (level) {
      case 'DEBUG':
        return '🔍';
      case 'INFO':
        return '📘';
      case 'WARN':
        return '⚠️';
      case 'ERROR':
        return '❌';
      default:
        return '📝';
    }
  }

  String _getColor(String level) {
    switch (level) {
      case 'DEBUG':
        return '\x1B[36m'; // Cyan
      case 'INFO':
        return '\x1B[32m'; // Green
      case 'WARN':
        return '\x1B[33m'; // Yellow
      case 'ERROR':
        return '\x1B[31m'; // Red
      default:
        return '\x1B[0m'; // Reset
    }
  }

  /// Close file sink
  Future<void> close() async {
    await _fileSink?.close();
  }
}

/// Global logger instance
final logger = LoggerService();
