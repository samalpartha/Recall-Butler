import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recall_butler_client/recall_butler_client.dart';
import 'package:recall_butler_flutter/providers/documents_provider.dart';
import 'package:recall_butler_flutter/services/api_service.dart';

class MockApiService extends Mock implements ApiService {}

void main() {
  late MockApiService mockApiService;
  late ProviderContainer container;

  setUp(() {
    mockApiService = MockApiService();
    container = ProviderContainer(overrides: [
      // We need to override the API service provider, but since it's defined
      // in another file and used inside documentsProvider, the best way 
      // is usually to override the provider that documentsProvider watches.
      // However, documentsProvider watches `apiServiceProvider`.
      // Let's assume we can pass the mock directly or we need to override `apiServiceProvider`.
    ]);
  });

  tearDown(() {
    container.dispose();
  });
  
  // Note: Since we can't easily import apiServiceProvider from here without 
  // knowing its exact location (it is in connectivity_provider.dart), 
  // we will test DocumentsNotifier directly.
  
  group('DocumentsNotifier', () {
    late DocumentsNotifier notifier;

    setUp(() {
       // notifier setup moved to individual tests to allow better mock setup
    });

    test('initial state is loading', () {
      // We need to recreate notifier to check initial state if needed,
      // but the constructor calls _loadDocuments immediately.
      // So we have to mock getDocuments BEFORE instantiating if we want to test load.
      when(() => mockApiService.getDocuments()).thenAnswer((_) async => []);
      final n = DocumentsNotifier(mockApiService);
      expect(n.state, isA<AsyncLoading>());
    });

    test('loads documents successfully', () async {
      final documents = [
        Document(
          id: 1,
          title: 'Test Doc',
          extractedText: 'Content',
          sourceType: 'TEXT',
          status: 'READY',
          userId: 1,
        )
      ];
      when(() => mockApiService.getDocuments()).thenAnswer((_) async => documents);
      
      final n = DocumentsNotifier(mockApiService);
      
      // Wait for the future to complete
      await Future.delayed(Duration.zero);
      
      expect(n.state, isA<AsyncData<List<Document>>>());
      expect(n.state.value, documents);
      verify(() => mockApiService.getDocuments()).called(1);
    });
    
    test('handles load error', () async {
      final error = Exception('Failed to load');
      when(() => mockApiService.getDocuments()).thenThrow(error);
      
      final n = DocumentsNotifier(mockApiService);
      
      // Wait for future
      await Future.delayed(Duration.zero);
      
      expect(n.state, isA<AsyncError>());
      verify(() => mockApiService.getDocuments()).called(1);
    });

    test('createFromText calls api and reloads', () async {
      final newDoc = Document(
        id: 2,
        title: 'New Doc',
        extractedText: 'New Content',
        sourceType: 'TEXT',
        status: 'READY',
        userId: 1,
      );
      
      when(() => mockApiService.getDocuments()).thenAnswer((_) async => []);
      when(() => mockApiService.createFromText(title: 'New Doc', text: 'New Content'))
          .thenAnswer((_) async => newDoc);
          
      final n = DocumentsNotifier(mockApiService);
      await Future.delayed(Duration.zero); // finish initial load
      
      await n.createFromText(title: 'New Doc', text: 'New Content');
      
      verify(() => mockApiService.createFromText(title: 'New Doc', text: 'New Content')).called(1);
      verify(() => mockApiService.getDocuments()).called(2); // Initial + reload
    });
    
     test('delete calls api and reloads', () async {
      when(() => mockApiService.getDocuments()).thenAnswer((_) async => []);
      when(() => mockApiService.deleteDocument(123)).thenAnswer((_) async => true);

      final n = DocumentsNotifier(mockApiService);
      await Future.delayed(Duration.zero); // finish initial load

      await n.delete(123);

      verify(() => mockApiService.deleteDocument(123)).called(1);
      verify(() => mockApiService.getDocuments()).called(2); // Initial + reload
    });
  });
}
