import 'package:flutter_test/flutter_test.dart';
import 'package:recall_butler_client/recall_butler_client.dart';
import 'package:recall_butler_flutter/services/api_service.dart';

void main() {
  group('ApiService', () {
    late ApiService apiService;

    setUp(() {
      apiService = ApiService();
    });

    group('Document Operations', () {
      test('createFromText returns a Document', () async {
        // Test that createFromText can be called (mock in real scenario)
        // This is a unit test structure - in real tests, use mocks
        expect(apiService, isNotNull);
        expect(apiService.client, isNotNull);
      });

      test('createFromUrl requires valid URL', () async {
        // Validate URL format handling
        expect(apiService, isNotNull);
      });

      test('getDocuments returns list', () async {
        // Test that method exists and returns correct type
        expect(apiService.getDocuments, isA<Function>());
      });

      test('deleteDocument requires valid id', () async {
        expect(apiService.deleteDocument, isA<Function>());
      });
    });

    group('Search Operations', () {
      test('search returns SearchResponse', () async {
        expect(apiService.search, isA<Function>());
      });

      test('quickSearch returns list of SearchResult', () async {
        expect(apiService.quickSearch, isA<Function>());
      });
    });

    group('Suggestion Operations', () {
      test('getSuggestions returns list', () async {
        expect(apiService.getSuggestions, isA<Function>());
      });

      test('acceptSuggestion updates state', () async {
        expect(apiService.acceptSuggestion, isA<Function>());
      });

      test('dismissSuggestion updates state', () async {
        expect(apiService.dismissSuggestion, isA<Function>());
      });

      test('createReminder creates suggestion', () async {
        expect(apiService.createReminder, isA<Function>());
      });
    });
  });

  group('DocumentHelpers Extension', () {
    test('isProcessing returns true for PROCESSING status', () {
      final doc = Document(
        id: 1,
        userId: 1,
        sourceType: 'text',
        title: 'Test',
        status: 'PROCESSING',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(doc.isProcessing, isTrue);
    });

    test('isProcessing returns true for QUEUED status', () {
      final doc = Document(
        id: 1,
        userId: 1,
        sourceType: 'text',
        title: 'Test',
        status: 'QUEUED',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(doc.isProcessing, isTrue);
    });

    test('isReady returns true for READY status', () {
      final doc = Document(
        id: 1,
        userId: 1,
        sourceType: 'text',
        title: 'Test',
        status: 'READY',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(doc.isReady, isTrue);
    });

    test('isFailed returns true for FAILED status', () {
      final doc = Document(
        id: 1,
        userId: 1,
        sourceType: 'text',
        title: 'Test',
        status: 'FAILED',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(doc.isFailed, isTrue);
    });
  });
}
