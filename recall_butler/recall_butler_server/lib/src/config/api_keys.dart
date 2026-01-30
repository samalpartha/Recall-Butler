import 'dart:io';

/// API Keys configuration
/// Loaded from environment variables in production
class ApiKeys {
  // Helper to retrieve from env with fallback
  static String _env(String key, String fallback) => Platform.environment[key] ?? fallback;

  // Groq - Ultra-fast inference (Llama 3)
  static String get groq => _env('GROQ_API_KEY', '');
  
  // Cerebras - Wafer-scale engine speed
  static String get cerebras => _env('CEREBRAS_API_KEY', '');
  
  // OpenRouter - Aggregator for everything else (Gemini, Claude, etc.)
  static String get openRouter => _env('OPENROUTER_API_KEY', '');
  
  // TMDB - Movie/TV Metadata
  static String get tmdbMsg => _env('TMDB_API_KEY', '');
  static String get tmdbReadToken => _env('TMDB_READ_TOKEN', '');
  
  // Google - Maps / Gemini direct
  static String get google => _env('GOOGLE_API_KEY', '');
  
  // Mistral - Mistral models
  static String get mistral => _env('MISTRAL_API_KEY', '');
}
