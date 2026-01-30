import 'dart:math';
import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'ai_service.dart';
import 'logger_service.dart';

/// Vector Search Service using pgvector for semantic search
/// and hybrid retrieval with Reciprocal Rank Fusion (RRF).
class VectorSearchService {
  static final VectorSearchService _instance = VectorSearchService._internal();
  factory VectorSearchService() => _instance;
  VectorSearchService._internal();

  final _aiService = AIService();

  /// Index a document chunk (stores logic for when we write to DB)
  /// Note: The actual insertion usually happens in the endpoint/manager, 
  /// but this helper can compute the metadata/embedding.
  Future<List<double>> generateEmbedding(String content) async {
    return _aiService.generateEmbedding(content);
  }

  /// Semantic search using pgvector via Raw SQL
  Future<List<SearchResult>> semanticSearch({
    required Session session,
    required String query,
    int? userId,
    int limit = 10,
    double threshold = 0.5,
  }) async {
    try {
      final queryEmbedding = await _aiService.generateEmbedding(query);
      final embeddingStr = '[${queryEmbedding.join(',')}]';

      // SQL Query: Join document_chunks with documents to get title/metadata
      // Use pgvector cosine distance operator (<=>). Similarity = 1 - distance.
      // We cast embeddingJson (text) to vector.
      final sql = '''
        SELECT 
          dc."documentId",
          dc."chunkIndex",
          dc."text",
          d."title",
          d."sourceType",
          d."sourceUrl",
          d."mimeType",
          1 - (dc."embeddingJson"::vector <=> '$embeddingStr'::vector) as score
        FROM document_chunks dc
        JOIN documents d ON dc."documentId" = d.id
        WHERE d."userId" = $userId
          AND dc."embeddingJson" IS NOT NULL
        ORDER BY score DESC
        LIMIT $limit;
      ''';

      final result = await session.db.unsafeQuery(sql);

      return result.map((row) {
        final r = row as List; // Serverpod row result is a list or map depending on driver, usually List in raw query
        // Mapped columns: 0:docId, 1:chunkIdx, 2:text, 3:title, 4:sourceType, 5:sourceUrl, 6:mimeType, 7:score
        return SearchResult(
          documentId: r[0] as int,
          chunkIndex: r[1] as int,
          title: r[3] as String,
          content: r[2] as String,
          score: (r[7] as num).toDouble(),
          metadata: {
            'sourceType': r[4],
            'sourceUrl': r[5],
            'mimeType': r[6],
          },
        );
      }).where((r) => r.score >= threshold).toList();

    } catch (e) {
      logger.error('Semantic search failed (SQL)', error: e, context: {'query': query});
      // Fallback: Fetch all and compute in-memory (Slow, but safe for dev without pgvector)
      return _fallbackInMemSemanticSearch(session, query, userId, limit, threshold);
    }
  }

  /// Keyword search using Postgres Full-Text Search
  Future<List<SearchResult>> keywordSearch({
    required Session session,
    required String query,
    int? userId,
    int limit = 10,
  }) async {
    try {
      // Clean query for tsquery
      final cleanQuery = query.replaceAll(RegExp(r'[^\w\s]'), '').trim().split(' ').join(' & ');
      if (cleanQuery.isEmpty) return [];

      final sql = '''
        SELECT 
          dc."documentId",
          dc."chunkIndex",
          dc."text",
          d."title",
          d."sourceType",
          d."sourceUrl",
          d."mimeType",
          ts_rank_cd(
            setweight(to_tsvector('english', d."title"), 'A') || 
            setweight(to_tsvector('english', dc."text"), 'B'),
            to_tsquery('english', '$cleanQuery')
          ) as score
        FROM document_chunks dc
        JOIN documents d ON dc."documentId" = d.id
        WHERE d."userId" = $userId
          AND (
            to_tsvector('english', d."title") @@ to_tsquery('english', '$cleanQuery') OR
            to_tsvector('english', dc."text") @@ to_tsquery('english', '$cleanQuery')
          )
        ORDER BY score DESC
        LIMIT $limit;
      ''';

      final result = await session.db.unsafeQuery(sql);

      return result.map((row) {
        final r = row as List;
        return SearchResult(
          documentId: r[0] as int,
          chunkIndex: r[1] as int,
          title: r[3] as String,
          content: r[2] as String,
          score: (r[7] as num).toDouble(),
          metadata: {
            'sourceType': r[4],
            'sourceUrl': r[5],
            'mimeType': r[6],
          },
        );
      }).toList();

    } catch (e) {
      logger.error('Keyword search failed', error: e);
      return []; // Return empty on keyword failure (formatting error usually)
    }
  }

  /// Hybrid search combining Vector + Keyword with RRF
  Future<List<SearchResult>> hybridSearch({
    required Session session,
    required String query,
    int? userId,
    int limit = 10,
  }) async {
    final semanticLimit = limit * 2;
    final keywordLimit = limit * 2;

    // Run parallel searches
    final results = await Future.wait([
      semanticSearch(session: session, query: query, userId: userId, limit: semanticLimit),
      keywordSearch(session: session, query: query, userId: userId, limit: keywordLimit),
    ]);

    final semanticRes = results[0];
    final keywordRes = results[1];

    // RRF Constants
    const k = 60;
    final rrfScores = <String, double>{};
    final mergedResults = <String, SearchResult>{};

    // Process Semantic Ranks
    for (int i = 0; i < semanticRes.length; i++) {
      final item = semanticRes[i];
      final key = '${item.documentId}_${item.chunkIndex}';
      mergedResults[key] = item;
      rrfScores[key] = (rrfScores[key] ?? 0.0) + (1.0 / (k + i + 1));
    }

    // Process Keyword Ranks
    for (int i = 0; i < keywordRes.length; i++) {
      final item = keywordRes[i];
      final key = '${item.documentId}_${item.chunkIndex}';
      // If present, we already updated the score, but we should add the keyword rank contribution
      // If new, add it.
      if (!mergedResults.containsKey(key)) {
        mergedResults[key] = item;
      }
      rrfScores[key] = (rrfScores[key] ?? 0.0) + (1.0 / (k + i + 1));
    }

    // Sort by RRF score
    final sortedKeys = rrfScores.keys.toList()
      ..sort((a, b) => rrfScores[b]!.compareTo(rrfScores[a]!)); // Descending

    return sortedKeys.take(limit).map((key) {
      final result = mergedResults[key]!;
      // We return the RRF score as the final score for debugging/ranking
      return SearchResult(
        documentId: result.documentId,
        chunkIndex: result.chunkIndex,
        title: result.title,
        content: result.content,
        score: rrfScores[key]!,
        metadata: result.metadata,
      );
    }).toList();
  }

  // --- Fallback In-Memory Implementation (For Dev/No-pgvector) ---

  Future<List<SearchResult>> _fallbackInMemSemanticSearch(
    Session session,
    String query,
    int? userId,
    int limit,
    double threshold,
  ) async {
    logger.info('Using fallback in-memory semantic search');
    
    final queryEmbedding = await _aiService.generateEmbedding(query);
    
    // Fetch all chunks (Expensive!)
    final chunks = await DocumentChunk.db.find(
      session,
      // Ideally we filter by userId via JOIN, but Serverpod ODM is limited here without relations loaded
      // We'll fetch all and filter in memory if needed, or rely on calling code
    );
     
    // Fetch docs to check userId
    final docs = await Document.db.find(session, where: (t) => t.userId.equals(userId));
    final userDocIds = docs.map((d) => d.id!).toSet();

    final results = <SearchResult>[];

    for (final chunk in chunks) {
      if (!userDocIds.contains(chunk.documentId)) continue;
      
      if (chunk.embeddingJson == null) continue;
      
      final chunkEmbedding = (jsonDecode(chunk.embeddingJson!) as List).cast<double>();
      final score = _cosineSimilarity(queryEmbedding, chunkEmbedding);

      if (score >= threshold) {
        final doc = docs.firstWhere((d) => d.id == chunk.documentId);
        results.add(SearchResult(
          documentId: chunk.documentId!,
          chunkIndex: chunk.chunkIndex,
          title: doc.title,
          content: chunk.text,
          score: score,
          metadata: {
            'sourceType': doc.sourceType,
            'sourceUrl': doc.sourceUrl,
            'mimeType': doc.mimeType,
          },
        ));
      }
    }

    results.sort((a, b) => b.score.compareTo(a.score));
    return results.take(limit).toList();
  }

  double _cosineSimilarity(List<double> a, List<double> b) {
    if (a.length != b.length) return 0;
    double dot = 0, normA = 0, normB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    return (normA == 0 || normB == 0) ? 0 : dot / (sqrt(normA) * sqrt(normB));
  }
}

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
