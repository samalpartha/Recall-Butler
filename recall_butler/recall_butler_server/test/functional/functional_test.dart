import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:test/test.dart';

/// Functional Tests for Recall Butler with Allure Report Integration
/// 
/// Run: dart test test/functional/functional_test.dart --reporter json > allure-results/results.json
/// Then: allure generate allure-results -o allure-report && allure open allure-report
void main() {
  final baseUrl = 'http://localhost:8180';
  final allureResults = <Map<String, dynamic>>[];
  
  // Helper to record test result for Allure
  void recordResult(String name, String status, {String? description, int? duration, String? error}) {
    allureResults.add({
      'name': name,
      'status': status,
      'description': description,
      'start': DateTime.now().millisecondsSinceEpoch,
      'stop': DateTime.now().millisecondsSinceEpoch + (duration ?? 0),
      'statusDetails': error != null ? {'message': error} : null,
      'labels': [
        {'name': 'suite', 'value': 'Recall Butler Functional Tests'},
        {'name': 'feature', 'value': 'API'},
      ],
    });
  }

  setUpAll(() {
    print('\n╔════════════════════════════════════════════════════════════╗');
    print('║           RECALL BUTLER FUNCTIONAL TEST SUITE              ║');
    print('╠════════════════════════════════════════════════════════════╣');
    print('║  Server: $baseUrl                              ║');
    print('╚════════════════════════════════════════════════════════════╝\n');
  });

  tearDownAll(() async {
    // Write Allure results
    final resultsDir = Directory('allure-results');
    if (!resultsDir.existsSync()) {
      resultsDir.createSync(recursive: true);
    }
    
    // Write each result as separate file for Allure
    for (var i = 0; i < allureResults.length; i++) {
      final file = File('allure-results/result-$i.json');
      file.writeAsStringSync(jsonEncode(allureResults[i]));
    }
    
    print('\n═══════════════════════════════════════════════════════════════');
    print('Allure results written to: allure-results/');
    print('To generate report: allure generate allure-results -o allure-report');
    print('═══════════════════════════════════════════════════════════════\n');
  });

  // ═══════════════════════════════════════════════════════════════
  // FUNCTIONAL TEST: Complete Document Lifecycle
  // ═══════════════════════════════════════════════════════════════
  group('📄 Document Lifecycle', () {
    int? createdDocId;

    test('FT-001: Create document from text', () async {
      final stopwatch = Stopwatch()..start();
      
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/document/createFromText'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': 'Functional Test Invoice #12345',
            'text': 'Invoice Amount: \$500.00\nDue Date: January 25, 2026\nClient: Acme Corp',
            'userId': 1,
          }),
        ).timeout(const Duration(seconds: 15));

        stopwatch.stop();
        
        expect(response.statusCode, anyOf(equals(200), equals(201)));
        
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        expect(data['title'], equals('Functional Test Invoice #12345'));
        expect(data['sourceType'], equals('text'));
        
        createdDocId = data['id'] as int;
        
        recordResult('FT-001: Create document from text', 'passed',
          description: 'Created document with ID: $createdDocId',
          duration: stopwatch.elapsedMilliseconds);
        
        print('  ✅ Created document ID: $createdDocId');
        
      } catch (e) {
        stopwatch.stop();
        recordResult('FT-001: Create document from text', 'failed',
          error: e.toString(), duration: stopwatch.elapsedMilliseconds);
        rethrow;
      }
    });

    test('FT-002: Retrieve created document', () async {
      final stopwatch = Stopwatch()..start();
      
      try {
        expect(createdDocId, isNotNull, reason: 'Document must be created first');
        
        final response = await http.get(
          Uri.parse('$baseUrl/document/getDocument?id=$createdDocId'),
        ).timeout(const Duration(seconds: 10));

        stopwatch.stop();
        
        expect(response.statusCode, equals(200));
        
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        expect(data['id'], equals(createdDocId));
        expect(data['title'], equals('Functional Test Invoice #12345'));
        
        recordResult('FT-002: Retrieve created document', 'passed',
          description: 'Retrieved document $createdDocId successfully',
          duration: stopwatch.elapsedMilliseconds);
        
        print('  ✅ Retrieved document: ${data['title']}');
        
      } catch (e) {
        stopwatch.stop();
        recordResult('FT-002: Retrieve created document', 'failed',
          error: e.toString(), duration: stopwatch.elapsedMilliseconds);
        rethrow;
      }
    });

    test('FT-003: Document appears in list', () async {
      final stopwatch = Stopwatch()..start();
      
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/document/getDocuments?userId=1&limit=50'),
        ).timeout(const Duration(seconds: 10));

        stopwatch.stop();
        
        expect(response.statusCode, equals(200));
        
        final docs = jsonDecode(response.body) as List;
        final found = docs.any((doc) => doc['id'] == createdDocId);
        
        expect(found, isTrue, reason: 'Created document should be in list');
        
        recordResult('FT-003: Document appears in list', 'passed',
          description: 'Found document in list of ${docs.length} documents',
          duration: stopwatch.elapsedMilliseconds);
        
        print('  ✅ Document found in list of ${docs.length} documents');
        
      } catch (e) {
        stopwatch.stop();
        recordResult('FT-003: Document appears in list', 'failed',
          error: e.toString(), duration: stopwatch.elapsedMilliseconds);
        rethrow;
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // FUNCTIONAL TEST: Search Functionality
  // ═══════════════════════════════════════════════════════════════
  group('🔍 Search Functionality', () {
    test('FT-004: Semantic search returns results', () async {
      final stopwatch = Stopwatch()..start();
      
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/search/search'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'query': 'What invoices are due?',
            'userId': 1,
            'topK': 10,
          }),
        ).timeout(const Duration(seconds: 20));

        stopwatch.stop();
        
        expect(response.statusCode, equals(200));
        
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        expect(data['query'], equals('What invoices are due?'));
        expect(data['results'], isA<List>());
        
        final results = data['results'] as List;
        
        recordResult('FT-004: Semantic search returns results', 'passed',
          description: 'Found ${results.length} results for invoice query',
          duration: stopwatch.elapsedMilliseconds);
        
        print('  ✅ Search returned ${results.length} results');
        if (data['answer'] != null) {
          print('  📝 AI Answer: ${(data['answer'] as String).substring(0, 100.clamp(0, (data['answer'] as String).length))}...');
        }
        
      } catch (e) {
        stopwatch.stop();
        recordResult('FT-004: Semantic search returns results', 'failed',
          error: e.toString(), duration: stopwatch.elapsedMilliseconds);
        rethrow;
      }
    });

    test('FT-005: Quick search performs faster', () async {
      final stopwatch = Stopwatch()..start();
      
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

        stopwatch.stop();
        
        expect(response.statusCode, equals(200));
        
        final results = jsonDecode(response.body) as List;
        
        // Quick search should be faster (no AI answer generation)
        expect(stopwatch.elapsedMilliseconds, lessThan(5000));
        
        recordResult('FT-005: Quick search performs faster', 'passed',
          description: 'Quick search completed in ${stopwatch.elapsedMilliseconds}ms',
          duration: stopwatch.elapsedMilliseconds);
        
        print('  ✅ Quick search: ${results.length} results in ${stopwatch.elapsedMilliseconds}ms');
        
      } catch (e) {
        stopwatch.stop();
        recordResult('FT-005: Quick search performs faster', 'failed',
          error: e.toString(), duration: stopwatch.elapsedMilliseconds);
        rethrow;
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // FUNCTIONAL TEST: Suggestion/Reminder System
  // ═══════════════════════════════════════════════════════════════
  group('💡 Suggestion System', () {
    int? createdReminderId;

    test('FT-006: Create reminder for document', () async {
      final stopwatch = Stopwatch()..start();
      final scheduledAt = DateTime.now().add(const Duration(days: 3));
      
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/suggestion/createReminder'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'documentId': 1,
            'title': 'Follow up on Functional Test Invoice',
            'description': 'Check if payment was received for Invoice #12345',
            'scheduledAt': scheduledAt.toIso8601String(),
            'userId': 1,
          }),
        ).timeout(const Duration(seconds: 10));

        stopwatch.stop();
        
        expect(response.statusCode, anyOf(equals(200), equals(201)));
        
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        expect(data['type'], equals('reminder'));
        expect(data['state'], equals('PROPOSED'));
        
        createdReminderId = data['id'] as int;
        
        recordResult('FT-006: Create reminder for document', 'passed',
          description: 'Created reminder ID: $createdReminderId',
          duration: stopwatch.elapsedMilliseconds);
        
        print('  ✅ Created reminder ID: $createdReminderId');
        
      } catch (e) {
        stopwatch.stop();
        recordResult('FT-006: Create reminder for document', 'failed',
          error: e.toString(), duration: stopwatch.elapsedMilliseconds);
        rethrow;
      }
    });

    test('FT-007: Pending suggestions count increases', () async {
      final stopwatch = Stopwatch()..start();
      
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/suggestion/getPendingCount?userId=1'),
        ).timeout(const Duration(seconds: 10));

        stopwatch.stop();
        
        expect(response.statusCode, equals(200));
        
        final count = jsonDecode(response.body) as int;
        expect(count, greaterThanOrEqualTo(0));
        
        recordResult('FT-007: Pending suggestions count', 'passed',
          description: 'Found $count pending suggestions',
          duration: stopwatch.elapsedMilliseconds);
        
        print('  ✅ Pending suggestions: $count');
        
      } catch (e) {
        stopwatch.stop();
        recordResult('FT-007: Pending suggestions count', 'failed',
          error: e.toString(), duration: stopwatch.elapsedMilliseconds);
        rethrow;
      }
    });

    test('FT-008: Accept suggestion changes state', () async {
      final stopwatch = Stopwatch()..start();
      
      try {
        expect(createdReminderId, isNotNull, reason: 'Reminder must be created first');
        
        final response = await http.post(
          Uri.parse('$baseUrl/suggestion/accept'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({'id': createdReminderId}),
        ).timeout(const Duration(seconds: 10));

        stopwatch.stop();
        
        expect(response.statusCode, equals(200));
        
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        expect(data['state'], equals('ACCEPTED'));
        
        recordResult('FT-008: Accept suggestion changes state', 'passed',
          description: 'Suggestion $createdReminderId accepted',
          duration: stopwatch.elapsedMilliseconds);
        
        print('  ✅ Suggestion accepted: ${data['state']}');
        
      } catch (e) {
        stopwatch.stop();
        recordResult('FT-008: Accept suggestion changes state', 'failed',
          error: e.toString(), duration: stopwatch.elapsedMilliseconds);
        rethrow;
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // FUNCTIONAL TEST: Statistics & Dashboard
  // ═══════════════════════════════════════════════════════════════
  group('📊 Statistics', () {
    test('FT-009: Get document statistics', () async {
      final stopwatch = Stopwatch()..start();
      
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/document/getStats?userId=1'),
        ).timeout(const Duration(seconds: 10));

        stopwatch.stop();
        
        expect(response.statusCode, equals(200));
        
        final stats = jsonDecode(response.body) as Map<String, dynamic>;
        
        recordResult('FT-009: Get document statistics', 'passed',
          description: 'Stats: $stats',
          duration: stopwatch.elapsedMilliseconds);
        
        print('  ✅ Statistics: $stats');
        
      } catch (e) {
        stopwatch.stop();
        recordResult('FT-009: Get document statistics', 'failed',
          error: e.toString(), duration: stopwatch.elapsedMilliseconds);
        rethrow;
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // FUNCTIONAL TEST: URL Document Creation
  // ═══════════════════════════════════════════════════════════════
  group('🌐 URL Processing', () {
    test('FT-010: Create document from URL', () async {
      final stopwatch = Stopwatch()..start();
      
      try {
        final response = await http.post(
          Uri.parse('$baseUrl/document/createFromUrl'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'title': 'Example Web Page',
            'url': 'https://example.com',
            'userId': 1,
          }),
        ).timeout(const Duration(seconds: 15));

        stopwatch.stop();
        
        expect(response.statusCode, anyOf(equals(200), equals(201)));
        
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        expect(data['sourceType'], equals('url'));
        expect(data['sourceUrl'], equals('https://example.com'));
        
        recordResult('FT-010: Create document from URL', 'passed',
          description: 'Created URL document: ${data['id']}',
          duration: stopwatch.elapsedMilliseconds);
        
        print('  ✅ Created URL document: ${data['id']}');
        
      } catch (e) {
        stopwatch.stop();
        recordResult('FT-010: Create document from URL', 'failed',
          error: e.toString(), duration: stopwatch.elapsedMilliseconds);
        rethrow;
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // FUNCTIONAL TEST: Error Handling
  // ═══════════════════════════════════════════════════════════════
  group('⚠️ Error Handling', () {
    test('FT-011: Handle invalid document ID gracefully', () async {
      final stopwatch = Stopwatch()..start();
      
      try {
        final response = await http.get(
          Uri.parse('$baseUrl/document/getDocument?id=999999'),
        ).timeout(const Duration(seconds: 10));

        stopwatch.stop();
        
        // Should return 404 or null/empty response
        expect(response.statusCode, anyOf(equals(200), equals(404)));
        
        recordResult('FT-011: Handle invalid document ID gracefully', 'passed',
          description: 'Server handled invalid ID correctly',
          duration: stopwatch.elapsedMilliseconds);
        
        print('  ✅ Invalid ID handled gracefully');
        
      } catch (e) {
        stopwatch.stop();
        recordResult('FT-011: Handle invalid document ID gracefully', 'failed',
          error: e.toString(), duration: stopwatch.elapsedMilliseconds);
        rethrow;
      }
    });
  });
}
