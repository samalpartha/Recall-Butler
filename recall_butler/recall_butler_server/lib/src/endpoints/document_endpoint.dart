import 'dart:convert';
import 'dart:io' show Platform;
import 'package:serverpod/serverpod.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../generated/protocol.dart';

class DocumentEndpoint extends Endpoint {
  // Cerebras API configuration
  static const String _cerebrasApiUrl = 'https://api.cerebras.ai/v1/chat/completions';
  
  String get _cerebrasApiKey => Platform.environment['CEREBRAS_API_KEY'] ?? '';

  /// Create a new document from text
  Future<Document> createFromText(
    Session session, {
    required String title,
    required String text,
    int userId = 1,
  }) async {
    // Generate AI summary
    final summary = await _generateSummary(text);
    
    // Extract key fields
    final keyFields = await _extractFields(text);
    
    // Create document
    final document = Document(
      userId: userId,
      sourceType: 'text',
      title: title,
      extractedText: text,
      summary: summary,
      keyFieldsJson: jsonEncode(keyFields),
      status: 'READY',
    );
    
    final doc = await Document.db.insertRow(session, document);
    
    // Create chunk with embedding
    final embedding = _generateEmbedding(text.substring(0, text.length.clamp(0, 2000)));
    final chunk = DocumentChunk(
      documentId: doc.id!,
      chunkIndex: 0,
      text: text.substring(0, text.length.clamp(0, 4000)),
      embeddingJson: jsonEncode(embedding),
    );
    await DocumentChunk.db.insertRow(session, chunk);
    
    // Generate suggestion
    await _generateSuggestion(session, doc, summary, keyFields);
    
    return doc;
  }

  /// Create a new document from URL
  Future<Document> createFromUrl(
    Session session, {
    required String title,
    required String url,
    int userId = 1,
  }) async {
    // Extract text from URL
    final text = await _extractFromUrl(url);
    
    // Generate AI summary
    final summary = await _generateSummary(text);
    
    // Extract key fields
    final keyFields = await _extractFields(text);
    
    // Create document
    final document = Document(
      userId: userId,
      sourceType: 'url',
      title: title,
      sourceUrl: url,
      extractedText: text,
      summary: summary,
      keyFieldsJson: jsonEncode(keyFields),
      status: 'READY',
    );
    
    final doc = await Document.db.insertRow(session, document);
    
    // Create chunk with embedding
    final embedding = _generateEmbedding(text.substring(0, text.length.clamp(0, 2000)));
    final chunk = DocumentChunk(
      documentId: doc.id!,
      chunkIndex: 0,
      text: text.substring(0, text.length.clamp(0, 4000)),
      embeddingJson: jsonEncode(embedding),
    );
    await DocumentChunk.db.insertRow(session, chunk);
    
    // Generate suggestion
    await _generateSuggestion(session, doc, summary, keyFields);
    
    return doc;
  }

  /// Get all documents for a user
  Future<List<Document>> getDocuments(Session session, {int userId = 1, int limit = 50}) async {
    return await Document.db.find(
      session,
      where: (t) => t.userId.equals(userId),
      orderBy: (t) => t.id,
      orderDescending: true,
      limit: limit,
    );
  }

  /// Get a single document by ID
  Future<Document?> getDocument(Session session, int id) async {
    return await Document.db.findById(session, id);
  }

  /// Delete a document
  Future<bool> deleteDocument(Session session, int id) async {
    // Delete chunks first
    await DocumentChunk.db.deleteWhere(
      session,
      where: (t) => t.documentId.equals(id),
    );
    // Delete suggestions
    await Suggestion.db.deleteWhere(
      session,
      where: (t) => t.documentId.equals(id),
    );
    // Delete document
    final deletedDocs = await Document.db.deleteWhere(
      session,
      where: (t) => t.id.equals(id),
    );
    return deletedDocs.isNotEmpty;
  }

  /// Get document statistics
  Future<Map<String, int>> getStats(Session session, {int userId = 1}) async {
    final all = await Document.db.find(session, where: (t) => t.userId.equals(userId));
    return {
      'total': all.length,
      'ready': all.where((d) => d.status == 'READY').length,
      'processing': all.where((d) => d.status == 'PROCESSING').length,
      'failed': all.where((d) => d.status == 'FAILED').length,
    };
  }

  // AI Helper Methods
  Future<String> _generateSummary(String text) async {
    if (_cerebrasApiKey.isEmpty) {
      return 'Summary: ${text.substring(0, text.length.clamp(0, 200))}...';
    }
    
    try {
      final response = await http.post(
        Uri.parse(_cerebrasApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_cerebrasApiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b',
          'messages': [
            {'role': 'user', 'content': 'Summarize this in 2-3 sentences:\n\n$text'}
          ],
          'max_completion_tokens': 150,
          'temperature': 0.3,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      }
    } catch (e) {
      print('Summary error: $e');
    }
    
    return 'Summary: ${text.substring(0, text.length.clamp(0, 200))}...';
  }

  Future<Map<String, dynamic>> _extractFields(String text) async {
    if (_cerebrasApiKey.isEmpty) return {};
    
    try {
      final response = await http.post(
        Uri.parse(_cerebrasApiUrl),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_cerebrasApiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.3-70b',
          'messages': [
            {'role': 'user', 'content': 'Extract key fields (dates, amounts, names, locations) from this text as a JSON object. Return ONLY valid JSON:\n\n$text'}
          ],
          'max_completion_tokens': 200,
          'temperature': 0.1,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final content = data['choices'][0]['message']['content'];
        final jsonMatch = RegExp(r'\{[^}]+\}').firstMatch(content);
        if (jsonMatch != null) {
          return jsonDecode(jsonMatch.group(0)!);
        }
      }
    } catch (e) {
      print('Field extraction error: $e');
    }
    
    return {};
  }

  List<double> _generateEmbedding(String text) {
    // Simple hash-based pseudo-embedding for demo
    final hash = text.hashCode;
    return List.generate(1536, (i) => ((hash * (i + 1)) % 10000) / 10000.0);
  }

  Future<String> _extractFromUrl(String url) async {
    try {
      final response = await http.get(
        Uri.parse(url),
        headers: {'User-Agent': 'RecallButler/1.0'},
      );
      
      if (response.statusCode != 200) {
        return 'Failed to fetch URL';
      }
      
      final document = html_parser.parse(response.body);
      document.querySelectorAll('script, style, nav, footer, header').forEach((e) => e.remove());
      
      final mainContent = document.querySelector('main') ??
          document.querySelector('article') ??
          document.body;
      
      final title = document.querySelector('title')?.text ?? '';
      final text = mainContent?.text ?? '';
      
      return '$title\n\n${text.replaceAll(RegExp(r'\s+'), ' ').trim()}';
    } catch (e) {
      return 'Error extracting from URL: $e';
    }
  }

  Future<void> _generateSuggestion(
    Session session,
    Document doc,
    String summary,
    Map<String, dynamic> fields,
  ) async {
    final lowerSummary = summary.toLowerCase();
    
    String type;
    String title;
    String description;
    Map<String, dynamic> payload;
    
    if (lowerSummary.contains('invoice') || lowerSummary.contains('payment') || fields.containsKey('amount')) {
      type = 'reminder';
      title = 'Payment Reminder';
      description = 'Set a reminder for this invoice payment';
      payload = {
        'action': 'Set payment reminder',
        'message': 'Remind me to pay this invoice',
        'dueDate': fields['date'] ?? DateTime.now().add(Duration(days: 7)).toIso8601String(),
      };
    } else if (lowerSummary.contains('meeting') || lowerSummary.contains('appointment')) {
      type = 'calendar';
      title = 'Calendar Event';
      description = 'Add this meeting to your calendar';
      payload = {
        'action': 'Add to calendar',
        'message': 'Schedule this meeting',
      };
    } else if (lowerSummary.contains('travel') || lowerSummary.contains('flight') || lowerSummary.contains('hotel')) {
      type = 'reminder';
      title = 'Travel Reminder';
      description = 'Set a reminder for your travel itinerary';
      payload = {
        'action': 'Travel reminder',
        'message': 'Set reminder for travel itinerary',
      };
    } else {
      type = 'followup';
      title = 'Follow Up';
      description = 'Review this document later';
      payload = {
        'action': 'Review later',
        'message': 'Follow up on this document',
      };
    }
    
    final suggestion = Suggestion(
      documentId: doc.id!,
      userId: doc.userId,
      type: type,
      title: title,
      description: description,
      payloadJson: jsonEncode(payload),
      state: 'PROPOSED',
    );
    
    await Suggestion.db.insertRow(session, suggestion);
  }
}
