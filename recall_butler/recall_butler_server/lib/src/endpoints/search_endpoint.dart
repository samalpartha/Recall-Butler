import 'dart:convert';
import 'dart:math';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import '../services/ai_service.dart';
import '../services/vector_search_service.dart' as vss;

class SearchEndpoint extends Endpoint {
  final AIService _ai = AIService();
  final vss.VectorSearchService _vectorSearch = vss.VectorSearchService();

  /// Semantic search across documents (now Hybrid)
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

    // Perform Hybrid Search
    final hybridResults = await _vectorSearch.hybridSearch(
      session: session,
      query: query,
      userId: userId,
      limit: topK,
    );

    if (hybridResults.isEmpty) {
      return SearchResponse(
        query: query,
        answer: 'No documents found for your query. Try adding some memories!',
        results: [],
        totalResults: 0,
      );
    }
    
    // Map to Protocol SearchResult
    final results = hybridResults.map((r) {
      return SearchResult(
        documentId: r.documentId,
        chunkId: r.chunkIndex, // We map chunkIndex to chunkId for now
        title: r.title,
        snippet: r.content.substring(0, min(r.content.length, 300)),
        sourceType: r.metadata['sourceType'] as String? ?? 'unknown',
        similarity: r.score,
      );
    }).toList();
    
    // Generate AI answer using the top chunks
    // We construct the context from the hybrid results
    final contextChunks = hybridResults.map((r) => r.content).toList();
    final answer = await _ai.generateAnswer(
      query: query,
      contextChunks: contextChunks,
    );
    
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
}
