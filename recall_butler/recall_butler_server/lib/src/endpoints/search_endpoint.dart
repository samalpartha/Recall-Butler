import 'dart:convert';
import 'dart:math';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/ai_service.dart';

class SearchEndpoint extends Endpoint {
  final AIService _ai = AIService();

  /// Semantic search across documents
  Future<SearchResponse> search(
    Session session, {
    required String query,
    int userId = 1,
    int topK = 5,
  }) async {
    if (query.trim().isEmpty) {
      return SearchResponse(
        query: query,
        answer: '',
        results: [],
        totalResults: 0,
      );
    }
    
    // Get query embedding
    final queryEmbedding = _generateEmbedding(query);
    
    // Get all chunks for user's documents
    final documents = await Document.db.find(
      session,
      where: (t) => t.userId.equals(userId),
    );
    
    final docIds = documents.map((d) => d.id!).toList();
    if (docIds.isEmpty) {
      return SearchResponse(
        query: query,
        answer: 'No documents found. Add some memories first!',
        results: [],
        totalResults: 0,
      );
    }
    
    // Get chunks and calculate similarity
    final chunks = <Map<String, dynamic>>[];
    for (final docId in docIds) {
      final docChunks = await DocumentChunk.db.find(
        session,
        where: (t) => t.documentId.equals(docId),
      );
      
      final doc = documents.firstWhere((d) => d.id == docId);
      
      for (final chunk in docChunks) {
        final chunkEmbedding = chunk.embeddingJson != null 
            ? List<double>.from(jsonDecode(chunk.embeddingJson!))
            : <double>[];
        
        final similarity = _cosineSimilarity(queryEmbedding, chunkEmbedding);
        
        chunks.add({
          'chunk': chunk,
          'document': doc,
          'similarity': similarity,
        });
      }
    }
    
    // Sort by similarity and take top K
    chunks.sort((a, b) => (b['similarity'] as double).compareTo(a['similarity'] as double));
    final topChunks = chunks.take(topK).toList();
    
    // Build search results
    final results = topChunks.map((c) {
      final chunk = c['chunk'] as DocumentChunk;
      final doc = c['document'] as Document;
      return SearchResult(
        documentId: doc.id!,
        chunkId: chunk.id!,
        title: doc.title,
        snippet: chunk.text.substring(0, chunk.text.length.clamp(0, 300)),
        sourceType: doc.sourceType,
        similarity: c['similarity'] as double,
      );
    }).toList();
    
    // Generate AI answer
    final answer = await _generateAnswer(query, topChunks);
    
    return SearchResponse(
      query: query,
      answer: answer,
      results: results,
      totalResults: results.length,
    );
  }

  /// Quick search returning just results
  Future<List<SearchResult>> quickSearch(
    Session session, {
    required String query,
    int userId = 1,
    int topK = 10,
  }) async {
    final response = await search(session, query: query, userId: userId, topK: topK);
    return response.results;
  }

  // Helper methods
  List<double> _generateEmbedding(String text) {
    final hash = text.hashCode;
    return List.generate(1536, (i) => ((hash * (i + 1)) % 10000) / 10000.0);
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0.0;
    
    double dotProduct = 0;
    double normA = 0;
    double normB = 0;
    
    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    
    if (normA == 0 || normB == 0) return 0.0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  Future<String> _generateAnswer(String query, List<Map<String, dynamic>> chunks) async {
    if (chunks.isEmpty) {
      return 'No relevant documents found for your query.';
    }
    
    final contextChunks = chunks.map((c) {
      final chunk = c['chunk'] as DocumentChunk;
      return chunk.text;
    }).toList();
    
    return _ai.generateAnswer(
      query: query,
      contextChunks: contextChunks,
      model: 'fast', // Use Claude Haiku for speed
    );
  }
}
