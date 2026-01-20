import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;

/// AI Service using OpenRouter API
/// Provides access to multiple LLMs through a unified API
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  static const String _openRouterApiUrl = 'https://openrouter.ai/api/v1/chat/completions';
  
  /// Get the API key from environment or passwords
  String get _apiKey => 
      Platform.environment['OPENROUTER_API_KEY'] ?? 
      Platform.environment['OPENROUTER_KEY'] ?? '';

  /// Available models on OpenRouter
  static const Map<String, String> models = {
    'default': 'anthropic/claude-3.5-sonnet',
    'fast': 'anthropic/claude-3-haiku',
    'powerful': 'anthropic/claude-3-opus',
    'gpt4': 'openai/gpt-4-turbo',
    'gpt4o': 'openai/gpt-4o',
    'llama': 'meta-llama/llama-3.1-70b-instruct',
    'mistral': 'mistralai/mistral-large',
    'gemini': 'google/gemini-pro-1.5',
    'free': 'nousresearch/nous-capybara-7b:free',
  };

  /// Generate a chat completion using OpenRouter
  Future<String> chat({
    required String prompt,
    String? systemPrompt,
    String model = 'default',
    int maxTokens = 500,
    double temperature = 0.7,
    Map<String, dynamic>? metadata,
  }) async {
    if (_apiKey.isEmpty) {
      return _getFallbackResponse(prompt);
    }

    final selectedModel = models[model] ?? models['default']!;
    
    final messages = <Map<String, String>>[];
    
    if (systemPrompt != null) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    
    messages.add({'role': 'user', 'content': prompt});

    try {
      final response = await http.post(
        Uri.parse(_openRouterApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
          'HTTP-Referer': 'https://recall-butler.app',
          'X-Title': 'Recall Butler',
        },
        body: jsonEncode({
          'model': selectedModel,
          'messages': messages,
          'max_tokens': maxTokens,
          'temperature': temperature,
          if (metadata != null) ...metadata,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? '';
      } else {
        print('OpenRouter API error: ${response.statusCode} - ${response.body}');
        return _getFallbackResponse(prompt);
      }
    } catch (e) {
      print('OpenRouter API exception: $e');
      return _getFallbackResponse(prompt);
    }
  }

  /// Generate an answer based on context (RAG-style)
  Future<String> generateAnswer({
    required String query,
    required List<String> contextChunks,
    String model = 'fast',
  }) async {
    if (contextChunks.isEmpty) {
      return 'No relevant context found for your query.';
    }

    final context = contextChunks.join('\n\n---\n\n');
    
    return chat(
      prompt: '''Based on the following context, answer the question.
Be concise, accurate, and cite sources when possible.

Context:
$context

Question: $query

Answer:''',
      systemPrompt: '''You are Recall Butler, an intelligent memory assistant.
Your job is to help users find and understand information from their stored memories.
Be helpful, concise, and accurate. If the context doesn't contain relevant information, say so.''',
      model: model,
      maxTokens: 400,
      temperature: 0.3,
    );
  }

  /// Extract key fields from document text
  Future<Map<String, dynamic>> extractKeyFields({
    required String text,
    required String documentType,
    String model = 'fast',
  }) async {
    final prompt = '''Extract key information from this $documentType.
Return a JSON object with relevant fields.

Text:
$text

Extract and return as JSON:''';

    final response = await chat(
      prompt: prompt,
      systemPrompt: 'You are a data extraction assistant. Extract key fields and return valid JSON only.',
      model: model,
      maxTokens: 500,
      temperature: 0.1,
    );

    try {
      // Try to parse the response as JSON
      final jsonStr = _extractJsonFromResponse(response);
      return jsonDecode(jsonStr);
    } catch (e) {
      return {'raw_text': text, 'extraction_error': true};
    }
  }

  /// Generate a document summary
  Future<String> summarize({
    required String text,
    int maxLength = 200,
    String model = 'fast',
  }) async {
    return chat(
      prompt: '''Summarize the following text in about $maxLength characters:

$text

Summary:''',
      systemPrompt: 'You are a summarization assistant. Create concise, informative summaries.',
      model: model,
      maxTokens: maxLength ~/ 2,
      temperature: 0.3,
    );
  }

  /// Generate proactive suggestions based on document content
  Future<List<Map<String, dynamic>>> generateSuggestions({
    required String documentContent,
    required String documentTitle,
    String model = 'fast',
  }) async {
    final response = await chat(
      prompt: '''Based on this document, suggest 1-3 helpful actions the user might want to take.

Document Title: $documentTitle
Content: $documentContent

Return suggestions as a JSON array with objects containing:
- type: "reminder", "action", or "insight"
- title: short title
- description: brief description
- priority: "high", "medium", or "low"

JSON:''',
      systemPrompt: '''You are Recall Butler, a proactive assistant.
Generate helpful, actionable suggestions based on document content.
Return valid JSON only.''',
      model: model,
      maxTokens: 400,
      temperature: 0.5,
    );

    try {
      final jsonStr = _extractJsonFromResponse(response);
      final List<dynamic> suggestions = jsonDecode(jsonStr);
      return suggestions.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  /// Generate embeddings for semantic search (simplified version)
  /// Note: For production, use a dedicated embedding model
  Future<List<double>> generateEmbedding(String text) async {
    // OpenRouter doesn't directly support embeddings
    // Using a hash-based approach as fallback
    // For production, integrate with OpenAI embeddings API
    final hash = text.hashCode;
    return List.generate(1536, (i) => ((hash * (i + 1)) % 10000) / 10000.0);
  }

  /// Check if the service is configured and available
  Future<bool> isAvailable() async {
    if (_apiKey.isEmpty) return false;
    
    try {
      final response = await http.get(
        Uri.parse('https://openrouter.ai/api/v1/models'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Get available models from OpenRouter
  Future<List<String>> getAvailableModels() async {
    if (_apiKey.isEmpty) return [];
    
    try {
      final response = await http.get(
        Uri.parse('https://openrouter.ai/api/v1/models'),
        headers: {'Authorization': 'Bearer $_apiKey'},
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return (data['data'] as List)
            .map((m) => m['id'] as String)
            .toList();
      }
    } catch (e) {
      print('Error fetching models: $e');
    }
    return [];
  }

  String _getFallbackResponse(String prompt) {
    if (prompt.toLowerCase().contains('summary') || 
        prompt.toLowerCase().contains('summarize')) {
      return 'Document content processed. Configure OpenRouter API key for AI summaries.';
    }
    return 'AI response unavailable. Set OPENROUTER_API_KEY environment variable.';
  }

  String _extractJsonFromResponse(String response) {
    // Try to find JSON in the response
    final jsonMatch = RegExp(r'\[[\s\S]*\]|\{[\s\S]*\}').firstMatch(response);
    if (jsonMatch != null) {
      return jsonMatch.group(0)!;
    }
    return response;
  }
}
