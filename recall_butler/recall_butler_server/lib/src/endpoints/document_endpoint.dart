import 'dart:convert';
import 'dart:io' show Platform;
import 'package:serverpod/serverpod.dart';
import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as html_parser;
import '../generated/protocol.dart';
import '../services/ai_service.dart';

import 'package:crypto/crypto.dart';

class DocumentEndpoint extends Endpoint {
  // Cerebras API configuration
  static const String _cerebrasApiUrl = 'https://api.cerebras.ai/v1/chat/completions';
  
  String get _cerebrasApiKey => Platform.environment['CEREBRAS_API_KEY'] ?? '';

  /// Calculate SHA-256 hash of content to ensure idempotency
  String _calculateHash(String content) {
    var bytes = utf8.encode(content);
    var digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// Check if document with hash already exists
  Future<Document?> _findDuplicate(Session session, int userId, String hash) async {
    return await Document.db.findFirstRow(
      session,
      where: (t) => t.userId.equals(userId) & t.contentHash.equals(hash),
    );
  }

  /// Create a new document from text
  Future<Document> createFromText(
    Session session, {
    required String title,
    required String text,
    int userId = 1,
  }) async {
    // IDEMPOTENCY CHECK
    final hash = _calculateHash(text);
    final existing = await _findDuplicate(session, userId, hash);
    if (existing != null) {
      print('Returning existing document for hash: $hash');
      return existing;
    }

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
      contentHash: hash,
      status: 'READY',
    );
    
    final doc = await Document.db.insertRow(session, document);
    
    // Create chunk with embedding
    final embedding = await _generateEmbedding(text.substring(0, text.length.clamp(0, 2000)));
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
    // IDEMPOTENCY CHECK (using URL as the unique key for now, or fetch content first)
    // Better to fetch content then hash it, but URL is also a strong proxy.
    // Let's use URL hash for initial check to avoid fetch if possible? 
    // No, content can change. Let's fetch first.
    
    // Extract text from URL
    final text = await _extractFromUrl(url);
    
    // Hash the extracted text
    final hash = _calculateHash(text);
    final existing = await _findDuplicate(session, userId, hash);
    if (existing != null) {
      return existing;
    }
    
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
      contentHash: hash,
      status: 'READY',
    );
    
    final doc = await Document.db.insertRow(session, document);
    
    // Create chunk with embedding
    final embedding = await _generateEmbedding(text.substring(0, text.length.clamp(0, 2000)));
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

  /// Create a new document from image (base64)
  Future<Document> createFromImage(
    Session session, {
    required String title,
    required String imageBase64,
    required String type, // 'receipt', 'invoice', etc.
    int userId = 1,
  }) async {
    // IDEMPOTENCY CHECK
    // Hash the base64 image content itself to avoid re-processing same image
    final hash = _calculateHash(imageBase64);
    final existing = await _findDuplicate(session, userId, hash);
    if (existing != null) {
      return existing;
    }

    print('DEBUG: createFromImage called. Title: $title, Type: $type, ImageLength: ${imageBase64.length}');
    final aiService = AIService();
    
    // 1. Extract text using AI Vision
    final prompt = 'Transcribe all text from this $type exactly as it appears. preserves structure.';
    final text = await aiService.chatWithVision(
      prompt: prompt,
      imageBase64: imageBase64,
      model: 'openai/gpt-4o', // Use high quality for OCR
    );
    
    // 2. Normalize and fix common OCR errors if needed (optional)
    
    // 3. Generate summary of extracted text
    final summary = await _generateSummary(text);
    
    // 4. Extract key fields
    final keyFields = await _extractFields(text);
    
    // 5. Create document
    final document = Document(
      userId: userId,
      sourceType: 'image',
      title: title,
      extractedText: text,
      summary: summary,
      keyFieldsJson: jsonEncode(keyFields),
      contentHash: hash, // Storing hash of Image Base64, or Text? Let's store Image Hash for strict file dup detection.
      status: 'READY',
      mimeType: 'image/jpeg', // Assuming jpeg for now
    );
    
    final doc = await Document.db.insertRow(session, document);
    
    // 6. Create chunk with embedding
    final embedding = await _generateEmbedding(text.substring(0, text.length.clamp(0, 2000)));
    final chunk = DocumentChunk(
      documentId: doc.id!,
      chunkIndex: 0,
      text: text.substring(0, text.length.clamp(0, 4000)),
      embeddingJson: jsonEncode(embedding),
    );
    await DocumentChunk.db.insertRow(session, chunk);
    
    // 7. Generate suggestion
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
    if (text.isEmpty) return 'No text extracted.';
    
    final aiService = AIService();
    // Use AIService wrapper instead of direct Cerebras implementation
    // This unifies our AI calls
    return aiService.summarize(text: text);
  }

  Future<Map<String, dynamic>> _extractFields(String text) async {
    if (text.isEmpty) return {};
    
    final aiService = AIService();
    return aiService.extractKeyFields(text: text, documentType: 'document');
  }

  Future<List<double>> _generateEmbedding(String text) async {
    final aiService = AIService();
    return aiService.generateEmbedding(text);
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
