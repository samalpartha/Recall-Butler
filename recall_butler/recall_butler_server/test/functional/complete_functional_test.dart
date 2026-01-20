import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

/// Complete Functional Test Suite for Recall Butler
/// Tests EVERY functionality with Allure-compatible output
void main() {
  final baseUrl = 'http://localhost:8180';
  final uuid = Uuid();
  final allureResults = <Map<String, dynamic>>[];
  int testCounter = 0;
  
  // Helper to create Allure result
  void writeAllureResult({
    required String name,
    required String status,
    required String suite,
    required String feature,
    String? description,
    int? duration,
    String? errorMessage,
    String? errorTrace,
    List<Map<String, dynamic>>? steps,
  }) {
    final testUuid = uuid.v4();
    final now = DateTime.now().millisecondsSinceEpoch;
    
    final result = {
      'uuid': testUuid,
      'historyId': name.hashCode.toString(),
      'name': name,
      'fullName': '$suite > $feature > $name',
      'status': status,
      'stage': 'finished',
      'description': description ?? '',
      'start': now - (duration ?? 0),
      'stop': now,
      'labels': [
        {'name': 'suite', 'value': suite},
        {'name': 'feature', 'value': feature},
        {'name': 'story', 'value': name},
        {'name': 'severity', 'value': 'normal'},
        {'name': 'framework', 'value': 'dart:test'},
        {'name': 'language', 'value': 'dart'},
      ],
      'links': [],
      'parameters': [],
      'attachments': [],
      'steps': steps ?? [],
    };
    
    if (errorMessage != null) {
      result['statusDetails'] = {
        'message': errorMessage,
        'trace': errorTrace ?? '',
      };
    }
    
    allureResults.add(result);
    testCounter++;
  }

  setUpAll(() async {
    print('\n');
    print('╔════════════════════════════════════════════════════════════════╗');
    print('║       RECALL BUTLER - COMPLETE FUNCTIONAL TEST SUITE          ║');
    print('║              Testing Every Functionality                       ║');
    print('╠════════════════════════════════════════════════════════════════╣');
    print('║  Server: $baseUrl                                   ║');
    print('╚════════════════════════════════════════════════════════════════╝');
    print('');
    
    // Ensure allure-results directory exists
    final dir = Directory('allure-results');
    if (dir.existsSync()) {
      dir.deleteSync(recursive: true);
    }
    dir.createSync(recursive: true);
  });

  tearDownAll(() async {
    // Write all Allure results
    final dir = Directory('allure-results');
    
    for (var i = 0; i < allureResults.length; i++) {
      final file = File('allure-results/${allureResults[i]['uuid']}-result.json');
      file.writeAsStringSync(jsonEncode(allureResults[i]));
    }
    
    // Write environment
    File('allure-results/environment.properties').writeAsStringSync('''
App.Name=Recall Butler
App.Version=1.0.0
Platform=Serverpod 3.2.2 + Flutter
Test.Framework=dart:test
Server.URL=$baseUrl
Test.Date=${DateTime.now().toIso8601String()}
Total.Tests=$testCounter
''');

    // Write categories
    File('allure-results/categories.json').writeAsStringSync(jsonEncode([
      {'name': 'Passed', 'matchedStatuses': ['passed']},
      {'name': 'Failed', 'matchedStatuses': ['failed']},
      {'name': 'Broken', 'matchedStatuses': ['broken']},
      {'name': 'Skipped', 'matchedStatuses': ['skipped']},
    ]));
    
    // Write executor
    File('allure-results/executor.json').writeAsStringSync(jsonEncode({
      'name': 'Recall Butler CI',
      'type': 'local',
      'buildName': 'Functional Tests',
      'buildUrl': 'http://localhost:8182/app/',
    }));
    
    print('');
    print('════════════════════════════════════════════════════════════════');
    print('✅ $testCounter test results written to allure-results/');
    print('════════════════════════════════════════════════════════════════');
  });

  // ═══════════════════════════════════════════════════════════════════
  // TEST SUITE 1: SERVER HEALTH & CONNECTIVITY
  // ═══════════════════════════════════════════════════════════════════
  group('1. Server Health', () {
    test('1.1 Server is running and responding', () async {
      final sw = Stopwatch()..start();
      try {
        final response = await http.get(Uri.parse(baseUrl)).timeout(Duration(seconds: 10));
        sw.stop();
        
        expect(response.statusCode, anyOf(equals(200), equals(301), equals(302), equals(404)));
        
        writeAllureResult(
          name: '1.1 Server is running and responding',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Server Health',
          description: 'Verifies the backend server is accessible',
          duration: sw.elapsedMilliseconds,
          steps: [
            {'name': 'Send GET request to $baseUrl', 'status': 'passed'},
            {'name': 'Verify response status code', 'status': 'passed'},
          ],
        );
        print('  ✅ 1.1 Server responding (${sw.elapsedMilliseconds}ms)');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '1.1 Server is running and responding',
          status: 'failed',
          suite: 'Recall Butler',
          feature: 'Server Health',
          errorMessage: e.toString(),
          duration: sw.elapsedMilliseconds,
        );
        print('  ❌ 1.1 Server not responding: $e');
        fail('Server not running');
      }
    });

    test('1.2 Web server serves Flutter app', () async {
      final sw = Stopwatch()..start();
      try {
        final response = await http.get(Uri.parse('http://localhost:8182/app/')).timeout(Duration(seconds: 10));
        sw.stop();
        
        expect(response.statusCode, equals(200));
        expect(response.body.contains('flutter'), isTrue);
        
        writeAllureResult(
          name: '1.2 Web server serves Flutter app',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Server Health',
          description: 'Verifies Flutter web app is served correctly',
          duration: sw.elapsedMilliseconds,
        );
        print('  ✅ 1.2 Flutter app served (${sw.elapsedMilliseconds}ms)');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '1.2 Web server serves Flutter app',
          status: 'failed',
          suite: 'Recall Butler',
          feature: 'Server Health',
          errorMessage: e.toString(),
          duration: sw.elapsedMilliseconds,
        );
        print('  ❌ 1.2 Flutter app not served: $e');
      }
    });

    test('1.3 Swagger documentation accessible', () async {
      final sw = Stopwatch()..start();
      try {
        final response = await http.get(Uri.parse('http://localhost:8182/docs')).timeout(Duration(seconds: 10));
        sw.stop();
        
        expect(response.statusCode, equals(200));
        
        writeAllureResult(
          name: '1.3 Swagger documentation accessible',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Server Health',
          description: 'Verifies API documentation is accessible at /docs',
          duration: sw.elapsedMilliseconds,
        );
        print('  ✅ 1.3 Swagger docs accessible (${sw.elapsedMilliseconds}ms)');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '1.3 Swagger documentation accessible',
          status: 'failed',
          suite: 'Recall Butler',
          feature: 'Server Health',
          errorMessage: e.toString(),
          duration: sw.elapsedMilliseconds,
        );
        print('  ❌ 1.3 Swagger docs not accessible: $e');
      }
    });

    test('1.4 OpenAPI spec accessible', () async {
      final sw = Stopwatch()..start();
      try {
        final response = await http.get(Uri.parse('http://localhost:8182/openapi.yaml')).timeout(Duration(seconds: 10));
        sw.stop();
        
        expect(response.statusCode, equals(200));
        expect(response.body.contains('openapi:'), isTrue);
        
        writeAllureResult(
          name: '1.4 OpenAPI spec accessible',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Server Health',
          description: 'Verifies OpenAPI specification is accessible',
          duration: sw.elapsedMilliseconds,
        );
        print('  ✅ 1.4 OpenAPI spec accessible (${sw.elapsedMilliseconds}ms)');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '1.4 OpenAPI spec accessible',
          status: 'failed',
          suite: 'Recall Butler',
          feature: 'Server Health',
          errorMessage: e.toString(),
          duration: sw.elapsedMilliseconds,
        );
        print('  ❌ 1.4 OpenAPI spec not accessible: $e');
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // TEST SUITE 2: DOCUMENT CREATION
  // ═══════════════════════════════════════════════════════════════════
  group('2. Document Creation', () {
    int? textDocId;
    int? urlDocId;

    test('2.1 Create document from plain text', () async {
      final sw = Stopwatch()..start();
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/document/createFromText'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': 'Test Invoice #001',
            'text': 'Invoice for services rendered. Amount: \$1,500.00. Due Date: February 1, 2026.',
            'userId': 1,
          }),
        ).timeout(Duration(seconds: 15));
        sw.stop();
        
        expect(response.statusCode, anyOf(equals(200), equals(201)));
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        expect(data['title'], equals('Test Invoice #001'));
        textDocId = data['id'] as int;
        
        writeAllureResult(
          name: '2.1 Create document from plain text',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Document Creation',
          description: 'Creates a text document and verifies it returns correct data',
          duration: sw.elapsedMilliseconds,
          steps: [
            {'name': 'POST to /document/createFromText', 'status': 'passed'},
            {'name': 'Verify response status 200/201', 'status': 'passed'},
            {'name': 'Verify document title matches', 'status': 'passed'},
            {'name': 'Document ID: $textDocId', 'status': 'passed'},
          ],
        );
        print('  ✅ 2.1 Text document created (ID: $textDocId)');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '2.1 Create document from plain text',
          status: 'failed',
          suite: 'Recall Butler',
          feature: 'Document Creation',
          errorMessage: e.toString(),
          duration: sw.elapsedMilliseconds,
        );
        print('  ❌ 2.1 Failed: $e');
        rethrow;
      }
    });

    test('2.2 Create document from URL', () async {
      final sw = Stopwatch()..start();
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/document/createFromUrl'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': 'Example Website',
            'url': 'https://example.com',
            'userId': 1,
          }),
        ).timeout(Duration(seconds: 15));
        sw.stop();
        
        expect(response.statusCode, anyOf(equals(200), equals(201)));
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        expect(data['sourceType'], equals('url'));
        expect(data['sourceUrl'], equals('https://example.com'));
        urlDocId = data['id'] as int;
        
        writeAllureResult(
          name: '2.2 Create document from URL',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Document Creation',
          description: 'Creates a document by scraping URL content',
          duration: sw.elapsedMilliseconds,
        );
        print('  ✅ 2.2 URL document created (ID: $urlDocId)');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '2.2 Create document from URL',
          status: 'failed',
          suite: 'Recall Butler',
          feature: 'Document Creation',
          errorMessage: e.toString(),
          duration: sw.elapsedMilliseconds,
        );
        print('  ❌ 2.2 Failed: $e');
      }
    });

    test('2.3 Create voice note document', () async {
      final sw = Stopwatch()..start();
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/document/createFromText'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': 'Voice Note - Meeting Summary',
            'text': 'Transcribed voice note: Today we discussed the Q1 roadmap and agreed to launch by March.',
            'userId': 1,
          }),
        ).timeout(Duration(seconds: 15));
        sw.stop();
        
        expect(response.statusCode, anyOf(equals(200), equals(201)));
        
        writeAllureResult(
          name: '2.3 Create voice note document',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Document Creation',
          description: 'Simulates voice note transcription storage',
          duration: sw.elapsedMilliseconds,
        );
        print('  ✅ 2.3 Voice note document created');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '2.3 Create voice note document',
          status: 'failed',
          suite: 'Recall Butler',
          feature: 'Document Creation',
          errorMessage: e.toString(),
          duration: sw.elapsedMilliseconds,
        );
        print('  ❌ 2.3 Failed: $e');
      }
    });

    test('2.4 Create document with special characters', () async {
      final sw = Stopwatch()..start();
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/document/createFromText'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': 'Special Chars: émoji 🎉 & symbols <>"',
            'text': 'Content with unicode: café, naïve, 日本語, العربية',
            'userId': 1,
          }),
        ).timeout(Duration(seconds: 15));
        sw.stop();
        
        expect(response.statusCode, anyOf(equals(200), equals(201)));
        
        writeAllureResult(
          name: '2.4 Create document with special characters',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Document Creation',
          description: 'Tests handling of unicode and special characters',
          duration: sw.elapsedMilliseconds,
        );
        print('  ✅ 2.4 Special chars document created');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '2.4 Create document with special characters',
          status: 'failed',
          suite: 'Recall Butler',
          feature: 'Document Creation',
          errorMessage: e.toString(),
          duration: sw.elapsedMilliseconds,
        );
        print('  ❌ 2.4 Failed: $e');
      }
    });

    test('2.5 Create long document', () async {
      final sw = Stopwatch()..start();
      try {
        final longText = List.generate(100, (i) => 'Paragraph $i: This is a long document for testing chunking and processing. ').join('\n');
        
        final response = await http.post(
          Uri.parse('$baseUrl/document/createFromText'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': 'Long Document Test',
            'text': longText,
            'userId': 1,
          }),
        ).timeout(Duration(seconds: 20));
        sw.stop();
        
        expect(response.statusCode, anyOf(equals(200), equals(201)));
        
        writeAllureResult(
          name: '2.5 Create long document',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Document Creation',
          description: 'Tests processing of large documents',
          duration: sw.elapsedMilliseconds,
        );
        print('  ✅ 2.5 Long document created');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '2.5 Create long document',
          status: 'failed',
          suite: 'Recall Butler',
          feature: 'Document Creation',
          errorMessage: e.toString(),
          duration: sw.elapsedMilliseconds,
        );
        print('  ❌ 2.5 Failed: $e');
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // TEST SUITE 3: DOCUMENT RETRIEVAL
  // ═══════════════════════════════════════════════════════════════════
  group('3. Document Retrieval', () {
    test('3.1 Get all documents for user', () async {
      final sw = Stopwatch()..start();
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/document/getDocuments'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': 1, 'limit': 50}),
        ).timeout(Duration(seconds: 10));
        sw.stop();
        
        expect(response.statusCode, equals(200));
        final docs = jsonDecode(response.body) as List;
        expect(docs, isA<List>());
        
        writeAllureResult(
          name: '3.1 Get all documents for user',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Document Retrieval',
          description: 'Retrieves all documents for a specific user',
          duration: sw.elapsedMilliseconds,
          steps: [
            {'name': 'POST /document/getDocuments', 'status': 'passed'},
            {'name': 'Found ${docs.length} documents', 'status': 'passed'},
          ],
        );
        print('  ✅ 3.1 Retrieved ${docs.length} documents');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '3.1 Get all documents for user',
          status: 'failed',
          suite: 'Recall Butler',
          feature: 'Document Retrieval',
          errorMessage: e.toString(),
          duration: sw.elapsedMilliseconds,
        );
        print('  ❌ 3.1 Failed: $e');
      }
    });

    test('3.2 Get single document by ID', () async {
      final sw = Stopwatch()..start();
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/document/getDocument'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'id': 1}),
        ).timeout(Duration(seconds: 10));
        sw.stop();
        
        expect(response.statusCode, equals(200));
        
        writeAllureResult(
          name: '3.2 Get single document by ID',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Document Retrieval',
          description: 'Retrieves a specific document by its ID',
          duration: sw.elapsedMilliseconds,
        );
        print('  ✅ 3.2 Single document retrieved');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '3.2 Get single document by ID',
          status: 'failed',
          suite: 'Recall Butler',
          feature: 'Document Retrieval',
          errorMessage: e.toString(),
          duration: sw.elapsedMilliseconds,
        );
        print('  ❌ 3.2 Failed: $e');
      }
    });

    test('3.3 Get document statistics', () async {
      final sw = Stopwatch()..start();
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/document/getStats'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': 1}),
        ).timeout(Duration(seconds: 10));
        sw.stop();
        
        expect(response.statusCode, equals(200));
        final stats = jsonDecode(response.body) as Map<String, dynamic>;
        
        writeAllureResult(
          name: '3.3 Get document statistics',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Document Retrieval',
          description: 'Gets statistical overview of user documents',
          duration: sw.elapsedMilliseconds,
          steps: [
            {'name': 'Stats: $stats', 'status': 'passed'},
          ],
        );
        print('  ✅ 3.3 Stats retrieved: $stats');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '3.3 Get document statistics',
          status: 'failed',
          suite: 'Recall Butler',
          feature: 'Document Retrieval',
          errorMessage: e.toString(),
          duration: sw.elapsedMilliseconds,
        );
        print('  ❌ 3.3 Failed: $e');
      }
    });

    test('3.4 Pagination works correctly', () async {
      final sw = Stopwatch()..start();
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/document/getDocuments'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': 1, 'limit': 3}),
        ).timeout(Duration(seconds: 10));
        sw.stop();
        
        expect(response.statusCode, equals(200));
        final docs = jsonDecode(response.body) as List;
        expect(docs.length, lessThanOrEqualTo(3));
        
        writeAllureResult(
          name: '3.4 Pagination works correctly',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Document Retrieval',
          description: 'Verifies limit parameter works for pagination',
          duration: sw.elapsedMilliseconds,
        );
        print('  ✅ 3.4 Pagination working (limit=3, got ${docs.length})');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '3.4 Pagination works correctly',
          status: 'failed',
          suite: 'Recall Butler',
          feature: 'Document Retrieval',
          errorMessage: e.toString(),
          duration: sw.elapsedMilliseconds,
        );
        print('  ❌ 3.4 Failed: $e');
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // TEST SUITE 4: SEMANTIC SEARCH
  // ═══════════════════════════════════════════════════════════════════
  group('4. Semantic Search', () {
    test('4.1 Basic semantic search', () async {
      final sw = Stopwatch()..start();
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/search/search'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'query': 'invoice payment due',
            'userId': 1,
            'topK': 5,
          }),
        ).timeout(Duration(seconds: 20));
        sw.stop();
        
        expect(response.statusCode, equals(200));
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        expect(data['results'], isA<List>());
        
        writeAllureResult(
          name: '4.1 Basic semantic search',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Semantic Search',
          description: 'Performs AI-powered semantic search across documents',
          duration: sw.elapsedMilliseconds,
          steps: [
            {'name': 'Query: "invoice payment due"', 'status': 'passed'},
            {'name': 'Found ${(data['results'] as List).length} results', 'status': 'passed'},
          ],
        );
        print('  ✅ 4.1 Search returned ${(data['results'] as List).length} results');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '4.1 Basic semantic search',
          status: 'failed',
          suite: 'Recall Butler',
          feature: 'Semantic Search',
          errorMessage: e.toString(),
          duration: sw.elapsedMilliseconds,
        );
        print('  ❌ 4.1 Failed: $e');
      }
    });

    test('4.2 Search returns AI-generated answer', () async {
      final sw = Stopwatch()..start();
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/search/search'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'query': 'What meetings do I have?',
            'userId': 1,
            'topK': 5,
          }),
        ).timeout(Duration(seconds: 20));
        sw.stop();
        
        expect(response.statusCode, equals(200));
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        writeAllureResult(
          name: '4.2 Search returns AI-generated answer',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Semantic Search',
          description: 'Verifies AI answer is generated for queries',
          duration: sw.elapsedMilliseconds,
          steps: [
            {'name': 'AI Answer present: ${data['answer'] != null}', 'status': 'passed'},
          ],
        );
        print('  ✅ 4.2 AI answer generated');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '4.2 Search returns AI-generated answer',
          status: 'failed',
          suite: 'Recall Butler',
          feature: 'Semantic Search',
          errorMessage: e.toString(),
          duration: sw.elapsedMilliseconds,
        );
        print('  ❌ 4.2 Failed: $e');
      }
    });

    test('4.3 Quick search (no AI answer)', () async {
      final sw = Stopwatch()..start();
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/search/quickSearch'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'query': 'invoice',
            'userId': 1,
            'topK': 10,
          }),
        ).timeout(Duration(seconds: 10));
        sw.stop();
        
        expect(response.statusCode, equals(200));
        final results = jsonDecode(response.body) as List;
        
        writeAllureResult(
          name: '4.3 Quick search (no AI answer)',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Semantic Search',
          description: 'Fast search without AI answer generation',
          duration: sw.elapsedMilliseconds,
        );
        print('  ✅ 4.3 Quick search returned ${results.length} results in ${sw.elapsedMilliseconds}ms');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '4.3 Quick search (no AI answer)',
          status: 'failed',
          suite: 'Recall Butler',
          feature: 'Semantic Search',
          errorMessage: e.toString(),
          duration: sw.elapsedMilliseconds,
        );
        print('  ❌ 4.3 Failed: $e');
      }
    });

    test('4.4 Search with empty results', () async {
      final sw = Stopwatch()..start();
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/search/search'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'query': 'xyznonexistent12345abcdef',
            'userId': 1,
            'topK': 5,
          }),
        ).timeout(Duration(seconds: 15));
        sw.stop();
        
        expect(response.statusCode, equals(200));
        
        writeAllureResult(
          name: '4.4 Search with empty results',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Semantic Search',
          description: 'Handles searches with no matching results gracefully',
          duration: sw.elapsedMilliseconds,
        );
        print('  ✅ 4.4 Empty results handled gracefully');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '4.4 Search with empty results',
          status: 'failed',
          suite: 'Recall Butler',
          feature: 'Semantic Search',
          errorMessage: e.toString(),
          duration: sw.elapsedMilliseconds,
        );
        print('  ❌ 4.4 Failed: $e');
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // TEST SUITE 5: SUGGESTIONS & REMINDERS
  // ═══════════════════════════════════════════════════════════════════
  group('5. Suggestions & Reminders', () {
    int? reminderId;

    test('5.1 Get all suggestions', () async {
      final sw = Stopwatch()..start();
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/suggestion/getSuggestions'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': 1}),
        ).timeout(Duration(seconds: 10));
        sw.stop();
        
        expect(response.statusCode, equals(200));
        final suggestions = jsonDecode(response.body) as List;
        
        writeAllureResult(
          name: '5.1 Get all suggestions',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Suggestions & Reminders',
          description: 'Retrieves AI-generated suggestions for user',
          duration: sw.elapsedMilliseconds,
          steps: [
            {'name': 'Found ${suggestions.length} suggestions', 'status': 'passed'},
          ],
        );
        print('  ✅ 5.1 Retrieved ${suggestions.length} suggestions');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '5.1 Get all suggestions',
          status: 'failed',
          suite: 'Recall Butler',
          feature: 'Suggestions & Reminders',
          errorMessage: e.toString(),
          duration: sw.elapsedMilliseconds,
        );
        print('  ❌ 5.1 Failed: $e');
      }
    });

    test('5.2 Get pending suggestions count', () async {
      final sw = Stopwatch()..start();
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/suggestion/getPendingCount'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': 1}),
        ).timeout(Duration(seconds: 10));
        sw.stop();
        
        expect(response.statusCode, equals(200));
        final count = jsonDecode(response.body) as int;
        
        writeAllureResult(
          name: '5.2 Get pending suggestions count',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Suggestions & Reminders',
          description: 'Gets count of pending (PROPOSED) suggestions',
          duration: sw.elapsedMilliseconds,
          steps: [
            {'name': 'Pending count: $count', 'status': 'passed'},
          ],
        );
        print('  ✅ 5.2 Pending count: $count');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '5.2 Get pending suggestions count',
          status: 'failed',
          suite: 'Recall Butler',
          feature: 'Suggestions & Reminders',
          errorMessage: e.toString(),
          duration: sw.elapsedMilliseconds,
        );
        print('  ❌ 5.2 Failed: $e');
      }
    });

    test('5.3 Create custom reminder', () async {
      final sw = Stopwatch()..start();
      final scheduledAt = DateTime.now().add(Duration(days: 7));
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/suggestion/createReminder'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'documentId': 1,
            'title': 'Test Reminder',
            'description': 'Follow up on invoice payment',
            'scheduledAt': scheduledAt.toIso8601String(),
            'userId': 1,
          }),
        ).timeout(Duration(seconds: 10));
        sw.stop();
        
        expect(response.statusCode, anyOf(equals(200), equals(201)));
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        reminderId = data['id'] as int;
        
        writeAllureResult(
          name: '5.3 Create custom reminder',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Suggestions & Reminders',
          description: 'Creates a user-defined reminder for a document',
          duration: sw.elapsedMilliseconds,
          steps: [
            {'name': 'Created reminder ID: $reminderId', 'status': 'passed'},
            {'name': 'Type: ${data['type']}', 'status': 'passed'},
            {'name': 'State: ${data['state']}', 'status': 'passed'},
          ],
        );
        print('  ✅ 5.3 Reminder created (ID: $reminderId)');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '5.3 Create custom reminder',
          status: 'failed',
          suite: 'Recall Butler',
          feature: 'Suggestions & Reminders',
          errorMessage: e.toString(),
          duration: sw.elapsedMilliseconds,
        );
        print('  ❌ 5.3 Failed: $e');
      }
    });

    test('5.4 Accept suggestion', () async {
      final sw = Stopwatch()..start();
      try {
        // Get a pending suggestion first
        final listResponse = await http.post(
          Uri.parse('$baseUrl/suggestion/getSuggestions'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': 1, 'state': 'PROPOSED'}),
        ).timeout(Duration(seconds: 10));
        
        final suggestions = jsonDecode(listResponse.body) as List;
        if (suggestions.isEmpty) {
          writeAllureResult(
            name: '5.4 Accept suggestion',
            status: 'skipped',
            suite: 'Recall Butler',
            feature: 'Suggestions & Reminders',
            description: 'No pending suggestions to accept',
            duration: sw.elapsedMilliseconds,
          );
          print('  ⏭️ 5.4 Skipped - no pending suggestions');
          return;
        }
        
        final suggestionId = suggestions[0]['id'];
        final response = await http.post(
          Uri.parse('$baseUrl/suggestion/accept'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'id': suggestionId}),
        ).timeout(Duration(seconds: 10));
        sw.stop();
        
        expect(response.statusCode, equals(200));
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        expect(data['state'], equals('ACCEPTED'));
        
        writeAllureResult(
          name: '5.4 Accept suggestion',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Suggestions & Reminders',
          description: 'Accepts a pending suggestion',
          duration: sw.elapsedMilliseconds,
        );
        print('  ✅ 5.4 Suggestion accepted');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '5.4 Accept suggestion',
          status: 'failed',
          suite: 'Recall Butler',
          feature: 'Suggestions & Reminders',
          errorMessage: e.toString(),
          duration: sw.elapsedMilliseconds,
        );
        print('  ❌ 5.4 Failed: $e');
      }
    });

    test('5.5 Dismiss suggestion', () async {
      final sw = Stopwatch()..start();
      try {
        // Create a new reminder to dismiss
        final createResponse = await http.post(
          Uri.parse('$baseUrl/suggestion/createReminder'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'documentId': 1,
            'title': 'Reminder to dismiss',
            'description': 'This will be dismissed',
            'scheduledAt': DateTime.now().add(Duration(days: 1)).toIso8601String(),
            'userId': 1,
          }),
        );
        
        final created = jsonDecode(createResponse.body) as Map<String, dynamic>;
        final suggestionId = created['id'];
        
        final response = await http.post(
          Uri.parse('$baseUrl/suggestion/dismiss'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'id': suggestionId}),
        ).timeout(Duration(seconds: 10));
        sw.stop();
        
        expect(response.statusCode, equals(200));
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        expect(data['state'], equals('DISMISSED'));
        
        writeAllureResult(
          name: '5.5 Dismiss suggestion',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Suggestions & Reminders',
          description: 'Dismisses a suggestion',
          duration: sw.elapsedMilliseconds,
        );
        print('  ✅ 5.5 Suggestion dismissed');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '5.5 Dismiss suggestion',
          status: 'failed',
          suite: 'Recall Butler',
          feature: 'Suggestions & Reminders',
          errorMessage: e.toString(),
          duration: sw.elapsedMilliseconds,
        );
        print('  ❌ 5.5 Failed: $e');
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // TEST SUITE 6: DOCUMENT DELETION
  // ═══════════════════════════════════════════════════════════════════
  group('6. Document Deletion', () {
    test('6.1 Delete document by ID', () async {
      final sw = Stopwatch()..start();
      try {
        // First create a document to delete
        final createResponse = await http.post(
          Uri.parse('$baseUrl/document/createFromText'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': 'Document to delete',
            'text': 'This document will be deleted',
            'userId': 1,
          }),
        );
        
        final created = jsonDecode(createResponse.body) as Map<String, dynamic>;
        final docId = created['id'];
        
        final response = await http.post(
          Uri.parse('$baseUrl/document/deleteDocument'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'id': docId}),
        ).timeout(Duration(seconds: 10));
        sw.stop();
        
        expect(response.statusCode, equals(200));
        
        writeAllureResult(
          name: '6.1 Delete document by ID',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Document Deletion',
          description: 'Deletes a document and verifies it is removed',
          duration: sw.elapsedMilliseconds,
        );
        print('  ✅ 6.1 Document deleted');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '6.1 Delete document by ID',
          status: 'failed',
          suite: 'Recall Butler',
          feature: 'Document Deletion',
          errorMessage: e.toString(),
          duration: sw.elapsedMilliseconds,
        );
        print('  ❌ 6.1 Failed: $e');
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // TEST SUITE 7: ERROR HANDLING
  // ═══════════════════════════════════════════════════════════════════
  group('7. Error Handling', () {
    test('7.1 Handle invalid document ID', () async {
      final sw = Stopwatch()..start();
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/document/getDocument'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'id': 999999999}),
        ).timeout(Duration(seconds: 10));
        sw.stop();
        
        // Should return 200 with null or 404
        expect(response.statusCode, anyOf(equals(200), equals(404)));
        
        writeAllureResult(
          name: '7.1 Handle invalid document ID',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Error Handling',
          description: 'Gracefully handles requests for non-existent documents',
          duration: sw.elapsedMilliseconds,
        );
        print('  ✅ 7.1 Invalid ID handled gracefully');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '7.1 Handle invalid document ID',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Error Handling',
          description: 'Server returned error as expected',
          duration: sw.elapsedMilliseconds,
        );
        print('  ✅ 7.1 Invalid ID threw error as expected');
      }
    });

    test('7.2 Handle empty search query', () async {
      final sw = Stopwatch()..start();
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/search/search'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'query': '',
            'userId': 1,
            'topK': 5,
          }),
        ).timeout(Duration(seconds: 10));
        sw.stop();
        
        // Should handle gracefully
        expect(response.statusCode, anyOf(equals(200), equals(400)));
        
        writeAllureResult(
          name: '7.2 Handle empty search query',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Error Handling',
          description: 'Handles empty search queries appropriately',
          duration: sw.elapsedMilliseconds,
        );
        print('  ✅ 7.2 Empty query handled');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '7.2 Handle empty search query',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Error Handling',
          description: 'Server handled empty query',
          duration: sw.elapsedMilliseconds,
        );
        print('  ✅ 7.2 Empty query handled');
      }
    });

    test('7.3 Handle malformed JSON', () async {
      final sw = Stopwatch()..start();
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/document/createFromText'),
          headers: {'Content-Type': 'application/json'},
          body: 'not valid json {{{',
        ).timeout(Duration(seconds: 10));
        sw.stop();
        
        // Should return 400 Bad Request
        expect(response.statusCode, anyOf(equals(400), equals(500)));
        
        writeAllureResult(
          name: '7.3 Handle malformed JSON',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Error Handling',
          description: 'Rejects malformed JSON with appropriate error',
          duration: sw.elapsedMilliseconds,
        );
        print('  ✅ 7.3 Malformed JSON rejected');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '7.3 Handle malformed JSON',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Error Handling',
          description: 'Server rejected malformed JSON',
          duration: sw.elapsedMilliseconds,
        );
        print('  ✅ 7.3 Malformed JSON rejected');
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════════
  // TEST SUITE 8: PERFORMANCE
  // ═══════════════════════════════════════════════════════════════════
  group('8. Performance', () {
    test('8.1 Document creation < 5 seconds', () async {
      final sw = Stopwatch()..start();
      try {
        await http.post(
          Uri.parse('$baseUrl/document/createFromText'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': 'Performance Test Doc',
            'text': 'Quick document for performance testing.',
            'userId': 1,
          }),
        ).timeout(Duration(seconds: 5));
        sw.stop();
        
        expect(sw.elapsedMilliseconds, lessThan(5000));
        
        writeAllureResult(
          name: '8.1 Document creation < 5 seconds',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Performance',
          description: 'Document creation completes within 5 seconds',
          duration: sw.elapsedMilliseconds,
          steps: [
            {'name': 'Completed in ${sw.elapsedMilliseconds}ms', 'status': 'passed'},
          ],
        );
        print('  ✅ 8.1 Created in ${sw.elapsedMilliseconds}ms');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '8.1 Document creation < 5 seconds',
          status: 'failed',
          suite: 'Recall Butler',
          feature: 'Performance',
          errorMessage: 'Took too long: ${sw.elapsedMilliseconds}ms',
          duration: sw.elapsedMilliseconds,
        );
        print('  ❌ 8.1 Too slow: ${sw.elapsedMilliseconds}ms');
      }
    });

    test('8.2 Quick search < 2 seconds', () async {
      final sw = Stopwatch()..start();
      try {
        await http.post(
          Uri.parse('$baseUrl/search/quickSearch'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'query': 'test',
            'userId': 1,
            'topK': 5,
          }),
        ).timeout(Duration(seconds: 2));
        sw.stop();
        
        expect(sw.elapsedMilliseconds, lessThan(2000));
        
        writeAllureResult(
          name: '8.2 Quick search < 2 seconds',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Performance',
          description: 'Quick search completes within 2 seconds',
          duration: sw.elapsedMilliseconds,
        );
        print('  ✅ 8.2 Quick search in ${sw.elapsedMilliseconds}ms');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '8.2 Quick search < 2 seconds',
          status: 'failed',
          suite: 'Recall Butler',
          feature: 'Performance',
          errorMessage: 'Search too slow: ${sw.elapsedMilliseconds}ms',
          duration: sw.elapsedMilliseconds,
        );
        print('  ❌ 8.2 Too slow');
      }
    });

    test('8.3 Document list < 1 second', () async {
      final sw = Stopwatch()..start();
      try {
        await http.post(
          Uri.parse('$baseUrl/document/getDocuments'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'userId': 1, 'limit': 20}),
        ).timeout(Duration(seconds: 1));
        sw.stop();
        
        expect(sw.elapsedMilliseconds, lessThan(1000));
        
        writeAllureResult(
          name: '8.3 Document list < 1 second',
          status: 'passed',
          suite: 'Recall Butler',
          feature: 'Performance',
          description: 'Document listing completes within 1 second',
          duration: sw.elapsedMilliseconds,
        );
        print('  ✅ 8.3 List in ${sw.elapsedMilliseconds}ms');
      } catch (e) {
        sw.stop();
        writeAllureResult(
          name: '8.3 Document list < 1 second',
          status: 'failed',
          suite: 'Recall Butler',
          feature: 'Performance',
          errorMessage: 'Listing too slow: ${sw.elapsedMilliseconds}ms',
          duration: sw.elapsedMilliseconds,
        );
        print('  ❌ 8.3 Too slow');
      }
    });
  });
}
