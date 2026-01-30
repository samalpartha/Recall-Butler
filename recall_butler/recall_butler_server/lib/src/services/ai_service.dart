import 'dart:convert';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'package:serverpod/serverpod.dart';
import '../config/api_keys.dart';

/// AI Service handling multi-provider routing (Groq, OpenRouter, etc.)
class AIService {
  static final AIService _instance = AIService._internal();
  factory AIService() => _instance;
  AIService._internal();

  static const String _openRouterUrl = 'https://openrouter.ai/api/v1/chat/completions';
  static const String _groqUrl = 'https://api.groq.com/openai/v1/chat/completions';
  
  /// Routing configuration
  static const Map<String, String> models = {
    // OpenRouter Models
    'claude-sonnet': 'anthropic/claude-3.5-sonnet',
    'gemini-flash': 'google/gemini-2.0-flash-exp:free',
    'qwen-vision': 'qwen/qwen-2.5-vl-72b-instruct:free', // Backup Vision
    'gpt4o': 'openai/gpt-4o',
    
    // Groq Models (Direct Speed)
    'llama-fast': 'llama-3.1-8b-instant',
    'llama-strong': 'llama-3.3-70b-versatile', // Upgraded from 3.1
    'llama-vision': 'llama-3.2-90b-vision-preview', // Stronger vision model 
  };

  /// Smart Routing: Decides which provider to use based on the model requested
  String _getProviderUrl(String model) {
    if (model.startsWith('llama')) return _groqUrl;
    return _openRouterUrl;
  }

  /// Get appropriate API Key
  String _getApiKey(String model) {
    if (model.startsWith('llama')) return ApiKeys.groq;
    return ApiKeys.openRouter;
  }

  /// Standard Chat Completion
  Future<String> chat({
    required String prompt,
    String? systemPrompt,
    String model = 'llama-strong', // Default to Groq Llama 70B (Fast & Smart)
    int maxTokens = 1000,
    double temperature = 0.7,
  }) async {
    final selectedModel = models[model] ?? models['llama-strong']!;
    final url = _getProviderUrl(model);
    final apiKey = _getApiKey(model);

    final messages = <Map<String, dynamic>>[];
    if (systemPrompt != null) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }
    messages.add({'role': 'user', 'content': prompt});

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          if (url == _openRouterUrl) ...{
             'HTTP-Referer': 'https://recall-butler.app',
             'X-Title': 'Recall Butler',
          }
        },
        body: jsonEncode({
          'model': selectedModel,
          'messages': messages,
          'max_tokens': maxTokens,
          'temperature': temperature,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'] ?? '';
      } else {
        print('AI API Error ($model): ${response.statusCode} - ${response.body}');
        return 'AI Service unavailable ($model)';
      }
    } catch (e) {
      print('AI API Exception ($model): $e');
      return 'AI Error: $e';
    }
  }

  /// Vision Chat (Multi-modal)
  /// Priority:
  /// 1. Gemini 2.0 Flash (via OpenRouter) - Free, Fast, Good
  /// 2. Llama 3.2 Vision (via Groq) - Ultra Fast
  Future<String> chatWithVision({
    required String prompt,
    required String imageBase64,
    String? systemPrompt,
    String model = 'gemini-flash', // Default Primary
  }) async {
    // 1. Try Primary (Gemini Flash)
    var result = await _performVisionRequest(
      prompt: prompt,
      imageBase64: imageBase64,
      systemPrompt: systemPrompt,
      modelKey: 'gemini-flash',
    );

    if (result.success) return result.content;

    // 2. Fallback to Groq Llama Vision (90B)
    print('Primary vision failed (${result.code}). Failing over to Groq Llama Vision...');
    result = await _performVisionRequest(
      prompt: prompt,
      imageBase64: imageBase64,
      systemPrompt: systemPrompt,
      modelKey: 'llama-vision',
    );
    
    if (result.success) return result.content;

    // 3. Last Resort: Qwen VL (OpenRouter)
    print('Groq vision failed (${result.code}). Failing over to Qwen VL...');
    result = await _performVisionRequest(
      prompt: prompt,
      imageBase64: imageBase64,
      systemPrompt: systemPrompt,
      modelKey: 'qwen-vision',
    );

    if (result.success) return result.content;

    return 'Vision analysis failed. Please try again.';
  }

  Future<({bool success, String content, int code})> _performVisionRequest({
    required String prompt,
    required String imageBase64,
    String? systemPrompt,
    required String modelKey,
  }) async {
    final selectedModel = models[modelKey]!;
    final url = _getProviderUrl(modelKey);
    final apiKey = _getApiKey(modelKey);

    final messages = <Map<String, dynamic>>[];
    if (systemPrompt != null) {
      messages.add({'role': 'system', 'content': systemPrompt});
    }

    // Ensure base64 string is properly formatted as a data URI
    final imageUrl = imageBase64.startsWith('data:image') 
        ? imageBase64 
        : 'data:image/jpeg;base64,$imageBase64';

    messages.add({
      'role': 'user',
      'content': [
        {'type': 'text', 'text': prompt},
        {
          'type': 'image_url',
          'image_url': {
            'url': imageUrl,
          }
        }
      ]
    });

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
          if (url == _openRouterUrl) ...{
             'HTTP-Referer': 'https://recall-butler.app',
             'X-Title': 'Recall Butler',
          }
        },
        body: jsonEncode({
          'model': selectedModel,
          'messages': messages,
          'max_tokens': 1000,
          'temperature': 0.1,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'] ?? '';
        return (success: true, content: content.toString(), code: 200);
      }
      print('AI API Error ($modelKey): ${response.statusCode} - ${response.body}');
      return (success: false, content: '', code: response.statusCode);
    } catch (e) {
      print('Vision Exception ($modelKey): $e');
      return (success: false, content: '', code: 500);
    }
  }

  // --- Helpers for existing codebase compatibility ---

  Future<String> generateAnswer({
    required String query,
    required List<String> contextChunks,
  }) async {
    if (contextChunks.isEmpty) return 'No context found.';
    final context = contextChunks.join('\n\n');
    return chat(
      prompt: 'Context:\n$context\n\nQuestion: $query',
      systemPrompt: 'You are Recall Butler. Answer based on context only.',
      model: 'llama-strong', // Groq 70B for RAG
    );
  }

  Future<List<double>> generateEmbedding(String text) async {
    // Simple hash fallback (Groq doesn't do embeddings yet)
    // Production should use a dedicated embedding service
    final hash = text.hashCode;
    return List.generate(1536, (i) => ((hash * (i + 1)) % 10000) / 10000.0);
  }

  Future<String> summarize({required String text}) async {
    return chat(
      prompt: 'Summarize this concisely:\n\n$text',
      model: 'llama-fast', // Use Groq 8B for instant summaries
    );
  }

  Future<Map<String, dynamic>> extractKeyFields({
    required String text, 
    required String documentType
  }) async {
    final jsonStr = await chat(
      prompt: 'Extract key fields from this $documentType as JSON:\n$text',
      model: 'llama-strong', // Use Groq 70B for reasoning
      systemPrompt: 'Return ONLY valid JSON.',
    );
    try {
      final jsonMatch = RegExp(r'\{[\s\S]*\}').firstMatch(jsonStr);
      if (jsonMatch != null) return jsonDecode(jsonMatch.group(0)!);
    } catch (_) {}
    return {};
  }

  Future<List<Map<String, dynamic>>> generateSuggestions({
    required String documentContent,
    required String documentTitle,
  }) async {
     final jsonStr = await chat(
      prompt: 'Generate 3 proactive suggestions (json list) for: $documentTitle\n$documentContent',
      model: 'llama-strong',
      systemPrompt: 'Return ONLY valid JSON array.',
    );
    try {
       final jsonMatch = RegExp(r'\[[\s\S]*\]').firstMatch(jsonStr);
      if (jsonMatch != null) return List<Map<String, dynamic>>.from(jsonDecode(jsonMatch.group(0)!));
    } catch (_) {}
    return [];
  }
}
