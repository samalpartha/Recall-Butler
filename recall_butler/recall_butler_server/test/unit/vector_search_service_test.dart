import 'package:test/test.dart';
import 'package:serverpod/serverpod.dart';
import '../../lib/src/services/vector_search_service.dart';
import '../../lib/src/generated/protocol.dart';

void main() {
  late VectorSearchService vectorSearchService;
  late Session mockSession;

  setUp(() {
    mockSession = _createMockSession();
    vectorSearchService = VectorSearchService(mockSession);
  });

  group('VectorSearchService - Similarity Search', () {
    test('should calculate cosine similarity correctly', () {
      final vec1 = [1.0, 0.0, 0.0];
      final vec2 = [1.0, 0.0, 0.0];
      final vec3 = [0.0, 1.0, 0.0];

      final similarity12 = vectorSearchService.cosineSimilarity(vec1, vec2);
      final similarity13 = vectorSearchService.cosineSimilarity(vec1, vec3);

      expect(similarity12, closeTo(1.0, 0.001)); // Same direction
      expect(similarity13, closeTo(0.0, 0.001)); // Perpendicular
    });

    test('should handle zero vectors', () {
      final vec1 = [0.0, 0.0, 0.0];
      final vec2 = [1.0, 1.0, 1.0];

      final similarity = vectorSearchService.cosineSimilarity(vec1, vec2);
      expect(similarity, equals(0.0));
    });

    test('should normalize vectors correctly', () {
      final vec = [3.0, 4.0]; // Length = 5
      final normalized = vectorSearchService.normalizeVector(vec);

      expect(normalized[0], closeTo(0.6, 0.001));
      expect(normalized[1], closeTo(0.8, 0.001));

      // Check unit length
      final length = vectorSearchService.vectorLength(normalized);
      expect(length, closeTo(1.0, 0.001));
    });
  });

  group('VectorSearchService - Embedding Generation', () {
    test('should generate embeddings for text', () async {
      final text = 'This is a test document about AI and machine learning.';
      final embedding = await vectorSearchService.generateEmbedding(text);

      expect(embedding, isNotEmpty);
      expect(embedding.length, equals(1536)); // text-embedding-3-small dimension
      expect(embedding.every((val) => val.isFinite), isTrue);
    });

    test('should handle long text by chunking', () async {
      final longText = 'word ' * 2000; // ~2000 words
      final embeddings = await vectorSearchService.generateEmbeddingsWithChunking(
        longText,
        chunkSize: 500,
      );

      expect(embeddings.length, greaterThan(1)); // Multiple chunks
      expect(embeddings.every((emb) => emb.length == 1536), isTrue);
    });

    test('should cache embeddings for identical text', () async {
      final text = 'Repeated text for caching test';
      
      final stopwatch = Stopwatch()..start();
      await vectorSearchService.generateEmbedding(text);
      final firstCallTime = stopwatch.elapsedMilliseconds;

      stopwatch.reset();
      await vectorSearchService.generateEmbedding(text);
      final secondCallTime = stopwatch.elapsedMilliseconds;

      // Second call should be significantly faster (cached)
      expect(secondCallTime, lessThan(firstCallTime * 0.5));
    });
  });

  group('VectorSearchService - Semantic Search', () {
    test('should search documents by query', () async {
      final query = 'machine learning algorithms';
      final results = await vectorSearchService.searchDocuments(
        query: query,
        userId: 1,
        limit: 10,
      );

      expect(results, isA<List<SearchResult>>());
      expect(results.length, lessThanOrEqualTo(10));
      
      // Results should be sorted by score descending
      for (var i = 0; i < results.length - 1; i++) {
        expect(results[i].score, greaterThanOrEqualTo(results[i + 1].score));
      }
    });

    test('should filter results by threshold', () async {
      final query = 'artificial intelligence';
      final threshold = 0.8;
      
      final results = await vectorSearchService.searchDocuments(
        query: query,
        userId: 1,
        threshold: threshold,
      );

      expect(results.every((r) => r.score >= threshold), isTrue);
    });

    test('should return empty list for no matches', () async {
      final query = 'xyzabc123nonexistentquery';
      final results = await vectorSearchService.searchDocuments(
        query: query,
        userId: 1,
        threshold: 0.9,
      );

      expect(results, isEmpty);
    });
  });

  group('VectorSearchService - Hybrid Search', () {
    test('should combine keyword and semantic search', () async {
      final query = 'machine learning tutorial';
      final results = await vectorSearchService.hybridSearch(
        query: query,
        userId: 1,
        semanticWeight: 0.7,
        keywordWeight: 0.3,
      );

      expect(results, isNotEmpty);
      expect(results.first.hybridScore, isNotNull);
    });

    test('should prioritize exact keyword matches', () async {
      final query = 'invoice payment';
      final results = await vectorSearchService.hybridSearch(
        query: query,
        userId: 1,
        keywordWeight: 0.8, // High keyword weight
      );

      // Top results should contain query keywords
      expect(
        results.first.title.toLowerCase().contains('invoice') ||
        results.first.content.toLowerCase().contains('invoice'),
        isTrue,
      );
    });
  });

  group('VectorSearchService - Similar Documents', () {
    test('should find similar documents to given document', () async {
      final documentId = 1;
      final similarDocs = await vectorSearchService.findSimilarDocuments(
        documentId: documentId,
        limit: 5,
      );

      expect(similarDocs.length, lessThanOrEqualTo(5));
      expect(similarDocs.any((doc) => doc.id == documentId), isFalse); // Exclude self
    });

    test('should use document embedding for similarity', () async {
      final documentId = 1;
      final similarDocs = await vectorSearchService.findSimilarDocuments(
        documentId: documentId,
        threshold: 0.75,
      );

      expect(similarDocs.every((doc) => doc.similarity >= 0.75), isTrue);
    });
  });

  group('VectorSearchService - Index Management', () {
    test('should create HNSW index for fast search', () async {
      final indexCreated = await vectorSearchService.createHNSWIndex(
        tableName: 'document_chunks',
        columnName: 'embedding',
      );

      expect(indexCreated, isTrue);
    });

    test('should update index after document insertion', () async {
      final document = Document(
        id: null,
        userId: 1,
        title: 'Test Document',
        content: 'Test content for indexing',
        sourceType: 'text',
        createdAt: DateTime.now(),
      );

      await vectorSearchService.indexDocument(document);

      // Document should be searchable immediately
      final results = await vectorSearchService.searchDocuments(
        query: 'test content',
        userId: 1,
      );

      expect(results.any((r) => r.title == 'Test Document'), isTrue);
    });
  });

  group('VectorSearchService - Performance', () {
    test('should handle large result sets efficiently', () async {
      final stopwatch = Stopwatch()..start();
      
      await vectorSearchService.searchDocuments(
        query: 'test query',
        userId: 1,
        limit: 1000,
      );
      
      stopwatch.stop();

      // Should complete within 1 second
      expect(stopwatch.elapsedMilliseconds, lessThan(1000));
    });

    test('should batch process embeddings', () async {
      final texts = List.generate(50, (i) => 'Text document number $i');
      
      final stopwatch = Stopwatch()..start();
      await vectorSearchService.batchGenerateEmbeddings(texts);
      stopwatch.stop();

      // Batch should be faster than individual calls
      final batchTime = stopwatch.elapsedMilliseconds;
      expect(batchTime, lessThan(texts.length * 100)); // Less than 100ms per text
    });
  });
}

Session _createMockSession() {
  return Session(
    server: Server(),
    uri: Uri.parse('http://localhost:8080'),
    method: Method.post,
    httpRequest: null,
  );
}

class SearchResult {
  final int id;
  final String title;
  final String content;
  final double score;
  final double? hybridScore;
  final double? similarity;

  SearchResult({
    required this.id,
    required this.title,
    required this.content,
    required this.score,
    this.hybridScore,
    this.similarity,
  });
}
