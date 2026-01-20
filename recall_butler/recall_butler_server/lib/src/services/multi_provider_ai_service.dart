import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';

/// Multi-Provider AI Service
/// Supports Groq, Cerebras, OpenRouter, and Mistral
class MultiProviderAIService {
  final Session session;
  late final String _defaultProvider;
  
  // API Keys
  late final String? _groqApiKey;
  late final String? _cerebrasApiKey;
  late final String? _openrouterApiKey;
  late final String? _mistralApiKey;
  
  // Default models
  late final String _groqModel;
  late final String _cerebrasModel;
  late final String _openrouterModel;
  late final String _mistralModel;

  MultiProviderAIService(this.session) {
    _loadConfiguration();
  }

  void _loadConfiguration() {
    // Load API keys
    _groqApiKey = Platform.environment['GROQ_API_KEY'];
    _cerebrasApiKey = Platform.environment['CEREBRAS_API_KEY'];
    _openrouterApiKey = Platform.environment['OPENROUTER_API_KEY'];
    _mistralApiKey = Platform.environment['MISTRAL_API_KEY'];
    
    // Default provider
    _defaultProvider = Platform.environment['DEFAULT_AI_PROVIDER'] ?? 'groq';
    
    // Default models
    _groqModel = Platform.environment['GROQ_DEFAULT_MODEL'] ?? 'llama-3.3-70b-versatile';
    _cerebrasModel = Platform.environment['CEREBRAS_DEFAULT_MODEL'] ?? 'llama3.1-70b';
    _openrouterModel = Platform.environment['OPENROUTER_DEFAULT_MODEL'] ?? 'anthropic/claude-3.5-sonnet';
    _mistralModel = Platform.environment['MISTRAL_DEFAULT_MODEL'] ?? 'mistral-large-latest';
  }

  /// Generate AI response with automatic provider failover
  Future<AIResponse> generateResponse({
    required String prompt,
    String? provider,
    String? model,
    double temperature = 0.7,
    int maxTokens = 1000,
    List<String>? fallbackProviders,
  }) async {
    final primaryProvider = provider ?? _defaultProvider;
    final providers = [
      primaryProvider,
      ...?fallbackProviders,
      // Auto-failover order
      if (primaryProvider != 'groq') 'groq',
      if (primaryProvider != 'cerebras') 'cerebras',
      if (primaryProvider != 'openrouter') 'openrouter',
      if (primaryProvider != 'mistral') 'mistral',
    ].toSet().toList();

    Exception? lastError;

    for (final currentProvider in providers) {
      try {
        final response = await _callProvider(
          provider: currentProvider,
          prompt: prompt,
          model: model,
          temperature: temperature,
          maxTokens: maxTokens,
        );
        
        return response;
        
      } catch (e) {
        lastError = e as Exception;
        print('Provider $currentProvider failed: $e. Trying next...');
        continue;
      }
    }

    throw lastError ?? Exception('All AI providers failed');
  }

  /// Call specific AI provider
  Future<AIResponse> _callProvider({
    required String provider,
    required String prompt,
    String? model,
    required double temperature,
    required int maxTokens,
  }) async {
    switch (provider) {
      case 'groq':
        return await _callGroq(prompt, model ?? _groqModel, temperature, maxTokens);
      case 'cerebras':
        return await _callCerebras(prompt, model ?? _cerebrasModel, temperature, maxTokens);
      case 'openrouter':
        return await _callOpenRouter(prompt, model ?? _openrouterModel, temperature, maxTokens);
      case 'mistral':
        return await _callMistral(prompt, model ?? _mistralModel, temperature, maxTokens);
      default:
        throw Exception('Unknown provider: $provider');
    }
  }

  /// Groq API (Fast inference)
  Future<AIResponse> _callGroq(String prompt, String model, double temperature, int maxTokens) async {
    if (_groqApiKey == null) throw Exception('GROQ_API_KEY not set');

    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_groqApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'temperature': temperature,
        'max_tokens': maxTokens,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Groq API error: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return AIResponse(
      content: data['choices'][0]['message']['content'],
      provider: 'groq',
      model: model,
      tokensUsed: data['usage']['total_tokens'],
    );
  }

  /// Cerebras API (Ultra-fast inference)
  Future<AIResponse> _callCerebras(String prompt, String model, double temperature, int maxTokens) async {
    if (_cerebrasApiKey == null) throw Exception('CEREBRAS_API_KEY not set');

    final response = await http.post(
      Uri.parse('https://api.cerebras.ai/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_cerebrasApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'temperature': temperature,
        'max_tokens': maxTokens,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Cerebras API error: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return AIResponse(
      content: data['choices'][0]['message']['content'],
      provider: 'cerebras',
      model: model,
      tokensUsed: data['usage']['total_tokens'],
    );
  }

  /// OpenRouter API (Multi-model access)
  Future<AIResponse> _callOpenRouter(String prompt, String model, double temperature, int maxTokens) async {
    if (_openrouterApiKey == null) throw Exception('OPENROUTER_API_KEY not set');

    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_openrouterApiKey',
        'Content-Type': 'application/json',
        'HTTP-Referer': 'https://recallbutler.com',
        'X-Title': 'Recall Butler',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'temperature': temperature,
        'max_tokens': maxTokens,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenRouter API error: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return AIResponse(
      content: data['choices'][0]['message']['content'],
      provider: 'openrouter',
      model: model,
      tokensUsed: data['usage']['total_tokens'],
    );
  }

  /// Mistral API
  Future<AIResponse> _callMistral(String prompt, String model, double temperature, int maxTokens) async {
    if (_mistralApiKey == null) throw Exception('MISTRAL_API_KEY not set');

    final response = await http.post(
      Uri.parse('https://api.mistral.ai/v1/chat/completions'),
      headers: {
        'Authorization': 'Bearer $_mistralApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': model,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'temperature': temperature,
        'max_tokens': maxTokens,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Mistral API error: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return AIResponse(
      content: data['choices'][0]['message']['content'],
      provider: 'mistral',
      model: model,
      tokensUsed: data['usage']['total_tokens'],
    );
  }

  /// Generate embeddings (using fastest provider)
  Future<List<double>> generateEmbedding(String text) async {
    // Groq is fastest for embeddings
    if (_groqApiKey != null) {
      return await _generateGroqEmbedding(text);
    } else if (_openrouterApiKey != null) {
      return await _generateOpenRouterEmbedding(text);
    } else {
      throw Exception('No embedding provider available');
    }
  }

  Future<List<double>> _generateGroqEmbedding(String text) async {
    final response = await http.post(
      Uri.parse('https://api.groq.com/openai/v1/embeddings'),
      headers: {
        'Authorization': 'Bearer $_groqApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'text-embedding-3-small',
        'input': text,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Groq embedding error: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return List<double>.from(data['data'][0]['embedding']);
  }

  Future<List<double>> _generateOpenRouterEmbedding(String text) async {
    final response = await http.post(
      Uri.parse('https://openrouter.ai/api/v1/embeddings'),
      headers: {
        'Authorization': 'Bearer $_openrouterApiKey',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'model': 'text-embedding-3-small',
        'input': text,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('OpenRouter embedding error: ${response.body}');
    }

    final data = jsonDecode(response.body);
    return List<double>.from(data['data'][0]['embedding']);
  }

  /// Get available providers
  List<String> getAvailableProviders() {
    return [
      if (_groqApiKey != null) 'groq',
      if (_cerebrasApiKey != null) 'cerebras',
      if (_openrouterApiKey != null) 'openrouter',
      if (_mistralApiKey != null) 'mistral',
    ];
  }
}

class AIResponse {
  final String content;
  final String provider;
  final String model;
  final int tokensUsed;

  AIResponse({
    required this.content,
    required this.provider,
    required this.model,
    required this.tokensUsed,
  });
}
