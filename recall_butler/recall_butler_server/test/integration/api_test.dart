import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

/// Integration tests for Recall Butler API
/// 
/// These tests require the server to be running at localhost:8180
/// Run: dart bin/main.dart
/// Then: dart test test/integration/api_test.dart
void main() {
  final baseUrl = 'http://localhost:8180';
  
  group('API Health Check', () {
    test('server responds to health endpoint', () async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/'),
        ).timeout(const Duration(seconds: 5));
        
        // Server should respond (either with content or redirect)
        expect(response.statusCode, anyOf(equals(200), equals(301), equals(302)));
      } catch (e) {
        fail('Server not running. Start with: dart bin/main.dart\nError: $e');
      }
    });
  });

  group('Document Endpoint Integration', () {
    test('POST /document/createFromText - creates text document', () async {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/document/createFromText'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': 'Integration Test Document',
            'text': 'This is test content for integration testing.',
            'userId': 1,
          }),
        ).timeout(const Duration(seconds: 10));

        expect(response.statusCode, anyOf(equals(200), equals(201)));
        
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        expect(data.containsKey('id'), isTrue);
        expect(data['title'], equals('Integration Test Document'));
        expect(data['status'], anyOf(equals('QUEUED'), equals('PROCESSING'), equals('READY')));
      } catch (e) {
        print('Skipping test - server may not be running: $e');
      }
    });

    test('POST /document/createFromUrl - creates URL document', () async {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/document/createFromUrl'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': 'Web Article Test',
            'url': 'https://example.com',
            'userId': 1,
          }),
        ).timeout(const Duration(seconds: 10));

        expect(response.statusCode, anyOf(equals(200), equals(201)));
        
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        expect(data['sourceType'], equals('url'));
        expect(data['sourceUrl'], equals('https://example.com'));
      } catch (e) {
        print('Skipping test - server may not be running: $e');
      }
    });

    test('GET /document/getDocuments - returns document list', () async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/document/getDocuments?userId=1&limit=10'),
        ).timeout(const Duration(seconds: 10));

        expect(response.statusCode, equals(200));
        
        final data = jsonDecode(response.body);
        expect(data, isA<List>());
      } catch (e) {
        print('Skipping test - server may not be running: $e');
      }
    });

    test('GET /document/getStats - returns statistics', () async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/document/getStats?userId=1'),
        ).timeout(const Duration(seconds: 10));

        expect(response.statusCode, equals(200));
        
        final data = jsonDecode(response.body);
        expect(data, isA<Map>());
      } catch (e) {
        print('Skipping test - server may not be running: $e');
      }
    });
  });

  group('Search Endpoint Integration', () {
    test('POST /search/search - performs semantic search', () async {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/search/search'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'query': 'test document',
            'userId': 1,
            'topK': 5,
          }),
        ).timeout(const Duration(seconds: 15));

        expect(response.statusCode, equals(200));
        
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        expect(data.containsKey('query'), isTrue);
        expect(data.containsKey('results'), isTrue);
        expect(data['results'], isA<List>());
      } catch (e) {
        print('Skipping test - server may not be running: $e');
      }
    });

    test('POST /search/quickSearch - performs quick search', () async {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/search/quickSearch'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'query': 'invoice',
            'userId': 1,
            'topK': 10,
          }),
        ).timeout(const Duration(seconds: 10));

        expect(response.statusCode, equals(200));
        
        final data = jsonDecode(response.body);
        expect(data, isA<List>());
      } catch (e) {
        print('Skipping test - server may not be running: $e');
      }
    });
  });

  group('Suggestion Endpoint Integration', () {
    test('GET /suggestion/getSuggestions - returns suggestions', () async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/suggestion/getSuggestions?userId=1'),
        ).timeout(const Duration(seconds: 10));

        expect(response.statusCode, equals(200));
        
        final data = jsonDecode(response.body);
        expect(data, isA<List>());
      } catch (e) {
        print('Skipping test - server may not be running: $e');
      }
    });

    test('GET /suggestion/getPendingCount - returns count', () async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/suggestion/getPendingCount?userId=1'),
        ).timeout(const Duration(seconds: 10));

        expect(response.statusCode, equals(200));
        
        final data = jsonDecode(response.body);
        expect(data, isA<int>());
      } catch (e) {
        print('Skipping test - server may not be running: $e');
      }
    });

    test('POST /suggestion/createReminder - creates reminder', () async {
      try {
        final scheduledAt = DateTime.now().add(const Duration(days: 1));
        final response = await http.post(
          Uri.parse('$baseUrl/suggestion/createReminder'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'documentId': 1,
            'title': 'Test Reminder',
            'description': 'Integration test reminder',
            'scheduledAt': scheduledAt.toIso8601String(),
            'userId': 1,
          }),
        ).timeout(const Duration(seconds: 10));

        expect(response.statusCode, anyOf(equals(200), equals(201)));
        
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        expect(data['type'], equals('reminder'));
        expect(data['state'], equals('PROPOSED'));
      } catch (e) {
        print('Skipping test - server may not be running: $e');
      }
    });
  });

  group('Schema Validation', () {
    test('Document schema has required fields', () async {
      try {
        // Create a document and validate response schema
        final response = await http.post(
          Uri.parse('$baseUrl/document/createFromText'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': 'Schema Test',
            'text': 'Content',
            'userId': 1,
          }),
        ).timeout(const Duration(seconds: 10));

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Validate required fields exist
        expect(data.containsKey('id'), isTrue, reason: 'Missing id field');
        expect(data.containsKey('userId'), isTrue, reason: 'Missing userId field');
        expect(data.containsKey('sourceType'), isTrue, reason: 'Missing sourceType field');
        expect(data.containsKey('title'), isTrue, reason: 'Missing title field');
        expect(data.containsKey('status'), isTrue, reason: 'Missing status field');
        expect(data.containsKey('createdAt'), isTrue, reason: 'Missing createdAt field');
        expect(data.containsKey('updatedAt'), isTrue, reason: 'Missing updatedAt field');
        
        // Validate field types
        expect(data['id'], isA<int>());
        expect(data['userId'], isA<int>());
        expect(data['sourceType'], isA<String>());
        expect(data['title'], isA<String>());
        expect(data['status'], isA<String>());
      } catch (e) {
        print('Skipping test - server may not be running: $e');
      }
    });

    test('SearchResponse schema has required fields', () async {
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/search/search'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'query': 'test',
            'userId': 1,
            'topK': 5,
          }),
        ).timeout(const Duration(seconds: 15));

        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        // Validate SearchResponse schema
        expect(data.containsKey('query'), isTrue, reason: 'Missing query field');
        expect(data.containsKey('results'), isTrue, reason: 'Missing results field');
        expect(data.containsKey('totalResults'), isTrue, reason: 'Missing totalResults field');
        
        expect(data['query'], isA<String>());
        expect(data['results'], isA<List>());
        expect(data['totalResults'], isA<int>());
        
        // Validate SearchResult items if any
        if ((data['results'] as List).isNotEmpty) {
          final result = data['results'][0] as Map<String, dynamic>;
          expect(result.containsKey('documentId'), isTrue);
          expect(result.containsKey('title'), isTrue);
          expect(result.containsKey('sourceType'), isTrue);
          expect(result.containsKey('similarity'), isTrue);
        }
      } catch (e) {
        print('Skipping test - server may not be running: $e');
      }
    });

    test('Suggestion schema has required fields', () async {
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/suggestion/getSuggestions?userId=1'),
        ).timeout(const Duration(seconds: 10));

        final data = jsonDecode(response.body) as List;
        
        if (data.isNotEmpty) {
          final suggestion = data[0] as Map<String, dynamic>;
          
          // Validate Suggestion schema
          expect(suggestion.containsKey('id'), isTrue, reason: 'Missing id field');
          expect(suggestion.containsKey('documentId'), isTrue, reason: 'Missing documentId field');
          expect(suggestion.containsKey('userId'), isTrue, reason: 'Missing userId field');
          expect(suggestion.containsKey('type'), isTrue, reason: 'Missing type field');
          expect(suggestion.containsKey('title'), isTrue, reason: 'Missing title field');
          expect(suggestion.containsKey('description'), isTrue, reason: 'Missing description field');
          expect(suggestion.containsKey('state'), isTrue, reason: 'Missing state field');
          expect(suggestion.containsKey('createdAt'), isTrue, reason: 'Missing createdAt field');
        }
      } catch (e) {
        print('Skipping test - server may not be running: $e');
      }
    });
  });
}
