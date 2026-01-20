import 'package:serverpod/serverpod.dart';

/// Health check endpoint for monitoring and orchestration
class HealthEndpoint extends Endpoint {
  /// Basic health check - returns 200 if service is running
  Future<Map<String, dynamic>> check(Session session) async {
    return {
      'status': 'healthy',
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'service': 'recall-butler-api',
    };
  }

  /// Detailed health check with dependencies
  Future<Map<String, dynamic>> detailed(Session session) async {
    final checks = <String, Map<String, dynamic>>{};
    var overallHealthy = true;

    // Database check
    try {
      final dbStart = DateTime.now();
      await session.db.query('SELECT 1');
      final dbLatency = DateTime.now().difference(dbStart).inMilliseconds;
      
      checks['database'] = {
        'status': 'healthy',
        'latency_ms': dbLatency,
        'type': 'postgresql',
      };
    } catch (e) {
      overallHealthy = false;
      checks['database'] = {
        'status': 'unhealthy',
        'error': e.toString(),
      };
    }

    // Memory check
    checks['memory'] = {
      'status': 'healthy',
      // In production, would include actual memory metrics
      'note': 'Memory metrics available in production',
    };

    // Cache check (if Redis is configured)
    checks['cache'] = {
      'status': 'healthy',
      'type': 'in-memory',
      'note': 'Using in-memory cache',
    };

    return {
      'status': overallHealthy ? 'healthy' : 'degraded',
      'timestamp': DateTime.now().toIso8601String(),
      'version': '1.0.0',
      'uptime_seconds': _getUptime(),
      'checks': checks,
      'environment': _getEnvironment(),
    };
  }

  /// Readiness probe for Kubernetes/orchestration
  Future<Map<String, dynamic>> ready(Session session) async {
    try {
      // Check database connection
      await session.db.query('SELECT 1');
      
      return {
        'ready': true,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {
        'ready': false,
        'error': 'Database not available',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
  }

  /// Liveness probe
  Future<Map<String, dynamic>> live(Session session) async {
    return {
      'alive': true,
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Get service metrics
  Future<Map<String, dynamic>> metrics(Session session) async {
    return {
      'timestamp': DateTime.now().toIso8601String(),
      'uptime_seconds': _getUptime(),
      'requests': {
        'note': 'Request metrics would be collected here',
      },
      'errors': {
        'note': 'Error metrics would be collected here',
      },
      'performance': {
        'note': 'Performance metrics would be collected here',
      },
    };
  }

  static final _startTime = DateTime.now();
  
  int _getUptime() {
    return DateTime.now().difference(_startTime).inSeconds;
  }

  String _getEnvironment() {
    // Would read from environment in production
    return 'development';
  }
}
