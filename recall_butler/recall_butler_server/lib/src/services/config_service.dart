import 'dart:io';

/// Environment-based configuration service
class ConfigService {
  static final ConfigService _instance = ConfigService._internal();
  factory ConfigService() => _instance;
  ConfigService._internal();

  /// Current environment
  String get environment => 
    Platform.environment['RECALL_BUTLER_ENV'] ?? 'development';

  bool get isProduction => environment == 'production';
  bool get isStaging => environment == 'staging';
  bool get isDevelopment => environment == 'development';
  bool get isTest => environment == 'test';

  /// API Configuration
  String get apiHost => 
    Platform.environment['API_HOST'] ?? 'localhost';
  
  int get apiPort => 
    int.tryParse(Platform.environment['API_PORT'] ?? '8180') ?? 8180;

  String get apiUrl => 
    Platform.environment['API_URL'] ?? 'http://$apiHost:$apiPort';

  /// Database Configuration
  String get dbHost => 
    Platform.environment['DB_HOST'] ?? 'localhost';
  
  int get dbPort => 
    int.tryParse(Platform.environment['DB_PORT'] ?? '5432') ?? 5432;
  
  String get dbName => 
    Platform.environment['DB_NAME'] ?? 'recall_butler';
  
  String get dbUser => 
    Platform.environment['DB_USER'] ?? 'postgres';
  
  String get dbPassword => 
    Platform.environment['DB_PASSWORD'] ?? 'postgres';

  /// OpenRouter AI Configuration
  String? get openRouterApiKey => 
    Platform.environment['OPENROUTER_API_KEY'];
  
  String get openRouterBaseUrl => 
    Platform.environment['OPENROUTER_BASE_URL'] ?? 'https://openrouter.ai/api/v1';
  
  String get defaultAiModel => 
    Platform.environment['DEFAULT_AI_MODEL'] ?? 'anthropic/claude-3-haiku';

  /// Feature Flags
  bool get enableMcp => 
    Platform.environment['ENABLE_MCP'] != 'false';
  
  bool get enableWeb5 => 
    Platform.environment['ENABLE_WEB5'] != 'false';
  
  bool get enableN8n => 
    Platform.environment['ENABLE_N8N'] != 'false';
  
  bool get enableAnalytics => 
    Platform.environment['ENABLE_ANALYTICS'] != 'false';

  /// n8n Integration
  String? get n8nWebhookUrl => 
    Platform.environment['N8N_WEBHOOK_URL'];

  /// Security Configuration
  String get jwtSecret => 
    Platform.environment['JWT_SECRET'] ?? _generateDevSecret();
  
  int get jwtExpirationHours => 
    int.tryParse(Platform.environment['JWT_EXPIRATION_HOURS'] ?? '24') ?? 24;
  
  List<String> get allowedOrigins {
    final origins = Platform.environment['ALLOWED_ORIGINS'];
    if (origins == null || origins.isEmpty) {
      return isDevelopment 
        ? ['http://localhost:3000', 'http://localhost:8180']
        : [];
    }
    return origins.split(',').map((e) => e.trim()).toList();
  }

  /// Rate Limiting
  int get rateLimitPerMinute => 
    int.tryParse(Platform.environment['RATE_LIMIT_PER_MINUTE'] ?? '60') ?? 60;
  
  int get rateLimitPerHour => 
    int.tryParse(Platform.environment['RATE_LIMIT_PER_HOUR'] ?? '1000') ?? 1000;

  /// File Storage
  String get uploadDir => 
    Platform.environment['UPLOAD_DIR'] ?? 'uploads';
  
  int get maxFileSizeMb => 
    int.tryParse(Platform.environment['MAX_FILE_SIZE_MB'] ?? '50') ?? 50;

  /// Logging
  String get logLevel => 
    Platform.environment['LOG_LEVEL'] ?? (isProduction ? 'info' : 'debug');
  
  bool get logToFile => 
    Platform.environment['LOG_TO_FILE'] == 'true';

  /// Get all configuration as map (for debugging, excludes secrets)
  Map<String, dynamic> toSafeMap() => {
    'environment': environment,
    'apiHost': apiHost,
    'apiPort': apiPort,
    'dbHost': dbHost,
    'dbPort': dbPort,
    'dbName': dbName,
    'features': {
      'mcp': enableMcp,
      'web5': enableWeb5,
      'n8n': enableN8n,
      'analytics': enableAnalytics,
    },
    'security': {
      'jwtExpirationHours': jwtExpirationHours,
      'allowedOrigins': allowedOrigins,
      'rateLimitPerMinute': rateLimitPerMinute,
    },
    'hasOpenRouterKey': openRouterApiKey != null,
    'hasN8nWebhook': n8nWebhookUrl != null,
  };

  /// Validate required configuration for production
  List<String> validateForProduction() {
    final errors = <String>[];
    
    if (isProduction) {
      if (jwtSecret == _generateDevSecret()) {
        errors.add('JWT_SECRET must be set in production');
      }
      if (openRouterApiKey == null) {
        errors.add('OPENROUTER_API_KEY is required for AI features');
      }
      if (allowedOrigins.isEmpty) {
        errors.add('ALLOWED_ORIGINS must be set in production');
      }
      if (dbPassword == 'postgres') {
        errors.add('DB_PASSWORD must be changed from default');
      }
    }
    
    return errors;
  }

  String _generateDevSecret() => 'dev-secret-do-not-use-in-production';
}

/// Extension for easy access
extension ConfigExtension on ConfigService {
  /// Check if a feature is enabled
  bool isFeatureEnabled(String feature) {
    switch (feature.toLowerCase()) {
      case 'mcp':
        return enableMcp;
      case 'web5':
        return enableWeb5;
      case 'n8n':
        return enableN8n;
      case 'analytics':
        return enableAnalytics;
      default:
        return false;
    }
  }
}
