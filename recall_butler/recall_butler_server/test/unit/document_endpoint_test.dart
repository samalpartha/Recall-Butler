import 'package:test/test.dart';
import 'package:recall_butler_server/src/generated/protocol.dart';

void main() {
  group('Document Model', () {
    test('creates document with required fields', () {
      final doc = Document(
        userId: 1,
        sourceType: 'text',
        title: 'Test Document',
        status: 'QUEUED',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(doc.userId, equals(1));
      expect(doc.sourceType, equals('text'));
      expect(doc.title, equals('Test Document'));
      expect(doc.status, equals('QUEUED'));
    });

    test('creates document with optional fields', () {
      final doc = Document(
        userId: 1,
        sourceType: 'url',
        title: 'Web Article',
        sourceUrl: 'https://example.com',
        extractedText: 'Some extracted text',
        summary: 'A summary',
        keyFieldsJson: '{"key": "value"}',
        status: 'READY',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      expect(doc.sourceUrl, equals('https://example.com'));
      expect(doc.extractedText, isNotNull);
      expect(doc.summary, equals('A summary'));
    });

    test('copyWith creates modified copy', () {
      final original = Document(
        id: 1,
        userId: 1,
        sourceType: 'text',
        title: 'Original',
        status: 'QUEUED',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final modified = original.copyWith(
        title: 'Modified',
        status: 'READY',
      );

      expect(original.title, equals('Original'));
      expect(modified.title, equals('Modified'));
      expect(modified.status, equals('READY'));
      expect(modified.userId, equals(1)); // Unchanged
    });

    test('validates status values', () {
      final validStatuses = ['QUEUED', 'PROCESSING', 'EMBEDDING', 'READY', 'FAILED'];
      
      for (final status in validStatuses) {
        final doc = Document(
          userId: 1,
          sourceType: 'text',
          title: 'Test',
          status: status,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(doc.status, equals(status));
      }
    });

    test('validates sourceType values', () {
      final validTypes = ['text', 'url', 'file', 'image', 'voice'];
      
      for (final type in validTypes) {
        final doc = Document(
          userId: 1,
          sourceType: type,
          title: 'Test',
          status: 'READY',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        expect(doc.sourceType, equals(type));
      }
    });
  });

  group('DocumentChunk Model', () {
    test('creates chunk with required fields', () {
      final chunk = DocumentChunk(
        documentId: 1,
        text: 'Chunk content here',
        createdAt: DateTime.now(),
      );

      expect(chunk.documentId, equals(1));
      expect(chunk.text, equals('Chunk content here'));
    });

    test('handles embedding data', () {
      final chunk = DocumentChunk(
        documentId: 1,
        text: 'Content',
        embedding: 'base64-encoded-embedding',
        createdAt: DateTime.now(),
      );

      expect(chunk.embedding, isNotNull);
    });
  });

  group('Suggestion Model', () {
    test('creates suggestion with required fields', () {
      final suggestion = Suggestion(
        documentId: 1,
        userId: 1,
        type: 'reminder',
        title: 'Test Reminder',
        description: 'Description',
        payloadJson: '{}',
        state: 'PROPOSED',
        createdAt: DateTime.now(),
      );

      expect(suggestion.type, equals('reminder'));
      expect(suggestion.state, equals('PROPOSED'));
    });

    test('validates suggestion types', () {
      final validTypes = ['reminder', 'followup', 'checkin', 'summary'];
      
      for (final type in validTypes) {
        final suggestion = Suggestion(
          documentId: 1,
          userId: 1,
          type: type,
          title: 'Test',
          description: 'Desc',
          payloadJson: '{}',
          state: 'PROPOSED',
          createdAt: DateTime.now(),
        );
        expect(suggestion.type, equals(type));
      }
    });

    test('validates suggestion states', () {
      final validStates = ['PROPOSED', 'ACCEPTED', 'DISMISSED'];
      
      for (final state in validStates) {
        final suggestion = Suggestion(
          documentId: 1,
          userId: 1,
          type: 'reminder',
          title: 'Test',
          description: 'Desc',
          payloadJson: '{}',
          state: state,
          createdAt: DateTime.now(),
        );
        expect(suggestion.state, equals(state));
      }
    });

    test('handles scheduled date', () {
      final scheduledAt = DateTime.now().add(const Duration(days: 7));
      final suggestion = Suggestion(
        documentId: 1,
        userId: 1,
        type: 'reminder',
        title: 'Test',
        description: 'Desc',
        payloadJson: '{}',
        state: 'PROPOSED',
        scheduledAt: scheduledAt,
        createdAt: DateTime.now(),
      );

      expect(suggestion.scheduledAt, equals(scheduledAt));
    });
  });

  group('SearchResult Model', () {
    test('creates search result', () {
      final result = SearchResult(
        documentId: 1,
        title: 'Found Document',
        snippet: 'Matching text...',
        sourceType: 'text',
        similarity: 0.95,
      );

      expect(result.documentId, equals(1));
      expect(result.similarity, closeTo(0.95, 0.001));
    });

    test('handles optional chunk ID', () {
      final resultWithChunk = SearchResult(
        documentId: 1,
        chunkId: 5,
        title: 'Found',
        snippet: 'Text',
        sourceType: 'text',
        similarity: 0.8,
      );

      final resultWithoutChunk = SearchResult(
        documentId: 1,
        title: 'Found',
        snippet: 'Text',
        sourceType: 'text',
        similarity: 0.8,
      );

      expect(resultWithChunk.chunkId, equals(5));
      expect(resultWithoutChunk.chunkId, isNull);
    });
  });

  group('SearchResponse Model', () {
    test('creates response with results', () {
      final results = [
        SearchResult(
          documentId: 1,
          title: 'Doc 1',
          snippet: 'Text',
          sourceType: 'text',
          similarity: 0.9,
        ),
        SearchResult(
          documentId: 2,
          title: 'Doc 2',
          snippet: 'Text',
          sourceType: 'url',
          similarity: 0.8,
        ),
      ];

      final response = SearchResponse(
        query: 'test query',
        answer: 'AI generated answer',
        results: results,
        totalResults: 2,
      );

      expect(response.query, equals('test query'));
      expect(response.answer, isNotNull);
      expect(response.results.length, equals(2));
      expect(response.totalResults, equals(2));
    });

    test('handles empty results', () {
      final response = SearchResponse(
        query: 'no matches',
        answer: 'No relevant information found.',
        results: [],
        totalResults: 0,
      );

      expect(response.results, isEmpty);
      expect(response.totalResults, equals(0));
    });
  });
}
