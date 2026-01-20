import 'dart:math';
import 'package:serverpod/serverpod.dart';
import 'ai_service.dart';
import 'logger_service.dart';

/// Vector Search Service using pgvector for semantic search
class VectorSearchService {
  static final VectorSearchService _instance = VectorSearchService._internal();
  factory VectorSearchService() => _instance;
  VectorSearchService._internal();

  final _aiService = AiService();

  // In-memory vector store (replace with pgvector in production)
  final List<VectorDocument> _vectorStore = [];

  /// Index a document chunk with its embedding
  Future<void> indexDocument({
    required Session session,
    required int documentId,
    required int chunkIndex,
    required String content,
    required String title,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // Generate embedding
      final embedding = await _aiService.generateEmbedding(content);

      // Store in vector index
      _vectorStore.add(VectorDocument(
        documentId: documentId,
        chunkIndex: chunkIndex,
        content: content,
        title: title,
        embedding: embedding,
        metadata: metadata ?? {},
        indexedAt: DateTime.now(),
      ));

      logger.debug('Indexed document chunk', context: {
        'documentId': documentId,
        'chunkIndex': chunkIndex,
        'embeddingDim': embedding.length,
      });

      // In production with pgvector:
      // await session.db.query('''
      //   INSERT INTO document_embeddings (document_id, chunk_index, content, embedding, metadata)
      //   VALUES (\$1, \$2, \$3, \$4::vector, \$5)
      //   ON CONFLICT (document_id, chunk_index) DO UPDATE SET
      //     content = EXCLUDED.content,
      //     embedding = EXCLUDED.embedding,
      //     metadata = EXCLUDED.metadata,
      //     updated_at = NOW()
      // ''', [documentId, chunkIndex, content, embedding, metadata]);

    } catch (e) {
      logger.error('Failed to index document', error: e, context: {
        'documentId': documentId,
        'chunkIndex': chunkIndex,
      });
      rethrow;
    }
  }

  /// Semantic search using vector similarity
  Future<List<SearchResult>> semanticSearch({
    required Session session,
    required String query,
    int limit = 10,
    double threshold = 0.7,
    Map<String, dynamic>? filters,
  }) async {
    try {
      // Generate query embedding
      final queryEmbedding = await _aiService.generateEmbedding(query);

      // Calculate similarities
      final results = <SearchResult>[];
      
      for (final doc in _vectorStore) {
        // Apply filters
        if (filters != null) {
          bool passesFilter = true;
          filters.forEach((key, value) {
            if (doc.metadata[key] != value) {
              passesFilter = false;
            }
          });
          if (!passesFilter) continue;
        }

        final similarity = _cosineSimilarity(queryEmbedding, doc.embedding);
        
        if (similarity >= threshold) {
          results.add(SearchResult(
            documentId: doc.documentId,
            chunkIndex: doc.chunkIndex,
            title: doc.title,
            content: doc.content,
            score: similarity,
            metadata: doc.metadata,
          ));
        }
      }

      // Sort by similarity score (descending)
      results.sort((a, b) => b.score.compareTo(a.score));

      // Limit results
      final limitedResults = results.take(limit).toList();

      logger.info('Semantic search completed', context: {
        'query': query.substring(0, min(50, query.length)),
        'resultsFound': limitedResults.length,
        'threshold': threshold,
      });

      return limitedResults;

      // In production with pgvector:
      // final results = await session.db.query('''
      //   SELECT 
      //     document_id,
      //     chunk_index,
      //     content,
      //     metadata,
      //     1 - (embedding <=> \$1::vector) as similarity
      //   FROM document_embeddings
      //   WHERE 1 - (embedding <=> \$1::vector) >= \$2
      //   ORDER BY embedding <=> \$1::vector
      //   LIMIT \$3
      // ''', [queryEmbedding, threshold, limit]);

    } catch (e) {
      logger.error('Semantic search failed', error: e, context: {'query': query});
      rethrow;
    }
  }

  /// Hybrid search combining keyword and semantic search
  Future<List<SearchResult>> hybridSearch({
    required Session session,
    required String query,
    int limit = 10,
    double semanticWeight = 0.7,
    double keywordWeight = 0.3,
    Map<String, dynamic>? filters,
  }) async {
    try {
      // Semantic search
      final semanticResults = await semanticSearch(
        session: session,
        query: query,
        limit: limit * 2,
        threshold: 0.5,
        filters: filters,
      );

      // Keyword search (simple TF-IDF-like scoring)
      final keywordResults = _keywordSearch(query, limit * 2, filters);

      // Merge and re-rank results
      final mergedScores = <String, double>{};
      final mergedResults = <String, SearchResult>{};

      for (final result in semanticResults) {
        final key = '${result.documentId}_${result.chunkIndex}';
        mergedScores[key] = (mergedScores[key] ?? 0) + result.score * semanticWeight;
        mergedResults[key] = result;
      }

      for (final result in keywordResults) {
        final key = '${result.documentId}_${result.chunkIndex}';
        mergedScores[key] = (mergedScores[key] ?? 0) + result.score * keywordWeight;
        mergedResults[key] ??= result;
      }

      // Sort by combined score
      final sortedKeys = mergedScores.keys.toList()
        ..sort((a, b) => mergedScores[b]!.compareTo(mergedScores[a]!));

      final finalResults = sortedKeys.take(limit).map((key) {
        final result = mergedResults[key]!;
        return SearchResult(
          documentId: result.documentId,
          chunkIndex: result.chunkIndex,
          title: result.title,
          content: result.content,
          score: mergedScores[key]!,
          metadata: result.metadata,
        );
      }).toList();

      logger.info('Hybrid search completed', context: {
        'query': query.substring(0, min(50, query.length)),
        'semanticResults': semanticResults.length,
        'keywordResults': keywordResults.length,
        'finalResults': finalResults.length,
      });

      return finalResults;
    } catch (e) {
      logger.error('Hybrid search failed', error: e);
      // Fallback to keyword search
      return _keywordSearch(query, limit, filters);
    }
  }

  /// Find similar documents
  Future<List<SearchResult>> findSimilar({
    required Session session,
    required int documentId,
    int limit = 5,
  }) async {
    try {
      // Find the document's embedding
      final doc = _vectorStore.firstWhere(
        (d) => d.documentId == documentId && d.chunkIndex == 0,
        orElse: () => throw Exception('Document not found'),
      );

      final results = <SearchResult>[];
      
      for (final otherDoc in _vectorStore) {
        if (otherDoc.documentId == documentId) continue;
        if (otherDoc.chunkIndex != 0) continue; // Only compare main chunks

        final similarity = _cosineSimilarity(doc.embedding, otherDoc.embedding);
        
        if (similarity > 0.5) {
          results.add(SearchResult(
            documentId: otherDoc.documentId,
            chunkIndex: otherDoc.chunkIndex,
            title: otherDoc.title,
            content: otherDoc.content,
            score: similarity,
            metadata: otherDoc.metadata,
          ));
        }
      }

      results.sort((a, b) => b.score.compareTo(a.score));
      return results.take(limit).toList();
    } catch (e) {
      logger.error('Find similar failed', error: e);
      return [];
    }
  }

  /// Remove document from index
  Future<void> removeDocument(Session session, int documentId) async {
    _vectorStore.removeWhere((doc) => doc.documentId == documentId);
    
    logger.info('Removed document from index', context: {'documentId': documentId});

    // In production with pgvector:
    // await session.db.query(
    //   'DELETE FROM document_embeddings WHERE document_id = \$1',
    //   [documentId],
    // );
  }

  /// Get index statistics
  Map<String, dynamic> getStats() {
    final uniqueDocs = _vectorStore.map((d) => d.documentId).toSet().length;
    final totalChunks = _vectorStore.length;
    final avgEmbeddingDim = _vectorStore.isEmpty 
        ? 0 
        : _vectorStore.map((d) => d.embedding.length).reduce((a, b) => a + b) ~/ _vectorStore.length;

    return {
      'totalDocuments': uniqueDocs,
      'totalChunks': totalChunks,
      'averageEmbeddingDimension': avgEmbeddingDim,
      'indexSizeMb': (totalChunks * avgEmbeddingDim * 4) / (1024 * 1024), // Approximate
    };
  }

  // Private helper methods

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0;
    
    double dotProduct = 0;
    double normA = 0;
    double normB = 0;

    for (int i = 0; i < a.length; i++) {
      dotProduct += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }

    if (normA == 0 || normB == 0) return 0;
    return dotProduct / (sqrt(normA) * sqrt(normB));
  }

  List<SearchResult> _keywordSearch(String query, int limit, Map<String, dynamic>? filters) {
    final queryTerms = query.toLowerCase().split(RegExp(r'\s+'));
    final results = <SearchResult>[];

    for (final doc in _vectorStore) {
      // Apply filters
      if (filters != null) {
        bool passesFilter = true;
        filters.forEach((key, value) {
          if (doc.metadata[key] != value) {
            passesFilter = false;
          }
        });
        if (!passesFilter) continue;
      }

      final contentLower = doc.content.toLowerCase();
      final titleLower = doc.title.toLowerCase();
      
      int matchCount = 0;
      for (final term in queryTerms) {
        if (contentLower.contains(term)) matchCount++;
        if (titleLower.contains(term)) matchCount += 2; // Title matches weighted higher
      }

      if (matchCount > 0) {
        final score = matchCount / (queryTerms.length * 3); // Normalize
        results.add(SearchResult(
          documentId: doc.documentId,
          chunkIndex: doc.chunkIndex,
          title: doc.title,
          content: doc.content,
          score: score,
          metadata: doc.metadata,
        ));
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList();
  }
}

/// Vector document in the index
class VectorDocument {
  final int documentId;
  final int chunkIndex;
  final String content;
  final String title;
  final List<double> embedding;
  final Map<String, dynamic> metadata;
  final DateTime indexedAt;

  VectorDocument({
    required this.documentId,
    required this.chunkIndex,
    required this.content,
    required this.title,
    required this.embedding,
    required this.metadata,
    required this.indexedAt,
  });
}

/// Search result
class SearchResult {
  final int documentId;
  final int chunkIndex;
  final String title;
  final String content;
  final double score;
  final Map<String, dynamic> metadata;

  SearchResult({
    required this.documentId,
    required this.chunkIndex,
    required this.title,
    required this.content,
    required this.score,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
    'documentId': documentId,
    'chunkIndex': chunkIndex,
    'title': title,
    'content': content,
    'score': score,
    'metadata': metadata,
  };
}
