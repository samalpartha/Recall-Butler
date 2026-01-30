import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recall_butler_client/recall_butler_client.dart';
import 'package:recall_butler_flutter/services/api_service.dart';
import 'package:recall_butler_flutter/services/offline_service.dart';

// Mock Classes
class MockClient extends Mock implements Client {}
class MockOfflineService extends Mock implements OfflineService {}
class MockEndpointDocument extends Mock implements EndpointDocument {}
class MockEndpointSearch extends Mock implements EndpointSearch {}
class MockEndpointSuggestion extends Mock implements EndpointSuggestion {}

void main() {
  late ApiService apiService;
  late MockClient mockClient;
  late MockOfflineService mockOfflineService;
  late MockEndpointDocument mockDocumentEndpoint;
  late MockEndpointSearch mockSearchEndpoint;
  late MockEndpointSuggestion mockSuggestionEndpoint;

  setUpAll(() {
    // Register fallback values if needed for Any() matchers
    registerFallbackValue(Document(
        id: 0, 
        userId: 0, 
        sourceType: 'text', 
        title: 'fallback', 
        status: 'pending',
    ));
    registerFallbackValue(SyncItem(
      id: 'fallback',
      type: 'fallback',
      data: {},
      createdAt: DateTime.now(),
    ));
  });

  setUp(() {
    ApiService.reset();
    mockClient = MockClient();
    mockOfflineService = MockOfflineService();
    mockDocumentEndpoint = MockEndpointDocument();
    mockSearchEndpoint = MockEndpointSearch();
    mockSuggestionEndpoint = MockEndpointSuggestion();

    // Setup client endpoint mocks
    when(() => mockClient.document).thenReturn(mockDocumentEndpoint);
    when(() => mockClient.search).thenReturn(mockSearchEndpoint);
    when(() => mockClient.suggestion).thenReturn(mockSuggestionEndpoint);
    
    // Default offline service behavior
    when(() => mockOfflineService.cacheDocument(any())).thenAnswer((_) async {});
    when(() => mockOfflineService.removeCachedDocument(any())).thenAnswer((_) async {});
    when(() => mockOfflineService.addToSyncQueue(any())).thenAnswer((_) async {});
    when(() => mockOfflineService.registerHandler(any(), any())).thenReturn(null);

    apiService = ApiService.test(
      client: mockClient,
      offlineService: mockOfflineService,
    );
  });

  group('ApiService - Online Mode', () {
    setUp(() {
      when(() => mockOfflineService.isOnline).thenReturn(true);
    });

    test('createFromText calls client and caches result', () async {
      final expectedDoc = Document(
        id: 1,
        userId: 1,
        sourceType: 'text',
        title: 'Test',
        extractedText: 'Content',
        status: 'READY',
      );

      when(() => mockDocumentEndpoint.createFromText(
        title: any(named: 'title'),
        text: any(named: 'text'),
        userId: any(named: 'userId'),
      )).thenAnswer((_) async => expectedDoc);

      final result = await apiService.createFromText(title: 'Test', text: 'Content');

      expect(result.id, 1);
      verify(() => mockDocumentEndpoint.createFromText(
        title: 'Test',
        text: 'Content',
        userId: 1,
      )).called(1);
      verify(() => mockOfflineService.cacheDocument(any())).called(1);
    });

    test('getDocuments merges server results with pending local docs', () async {
      final serverDocs = [
        Document(
          id: 1,
          userId: 1,
          sourceType: 'text',
          title: 'Server Doc',
          status: 'READY',
        )
      ];
      final pendingDocs = [
        {'id': -1, 'userId': 1, 'sourceType': 'text', 'title': 'Pending Doc', 'status': 'PENDING_SYNC'}
      ];

      when(() => mockDocumentEndpoint.getDocuments(userId: any(named: 'userId'), limit: any(named: 'limit')))
          .thenAnswer((_) async => serverDocs);
      when(() => mockOfflineService.cacheDocuments(any())).thenAnswer((_) async {});
      when(() => mockOfflineService.updateLastSyncTime()).thenAnswer((_) async {});
      when(() => mockOfflineService.getCachedDocuments()).thenReturn(pendingDocs);

      final result = await apiService.getDocuments();

      // Should contain both pending and server docs
      expect(result.length, 2);
      expect(result.first.status, 'PENDING_SYNC'); // Pending should be first
      expect(result.last.status, 'READY');
      
      verify(() => mockDocumentEndpoint.getDocuments(userId: 1, limit: 50)).called(1);
    });
    
    test('deleteDocument calls server and removes from cache', () async {
      when(() => mockDocumentEndpoint.deleteDocument(any())).thenAnswer((_) async => true);
      
      final success = await apiService.deleteDocument(123);
      
      expect(success, isTrue);
      verify(() => mockDocumentEndpoint.deleteDocument(123)).called(1);
      verify(() => mockOfflineService.removeCachedDocument('123')).called(1);
    });
  });

  group('ApiService - Offline Mode', () {
    setUp(() {
      when(() => mockOfflineService.isOnline).thenReturn(false);
    });

    test('createFromText creates pending offline document', () async {
      final result = await apiService.createFromText(title: 'Offline Doc', text: 'Content');

      expect(result.id, isNegative); // Temp ID
      expect(result.status, 'PENDING_SYNC');
      
      verifyZeroInteractions(mockDocumentEndpoint);
      verify(() => mockOfflineService.addToSyncQueue(any())).called(1);
      verify(() => mockOfflineService.cacheDocument(any())).called(1);
    });

    test('getDocuments returns only cached documents', () async {
      final cachedDocs = [
        {'id': 1, 'userId': 1, 'sourceType': 'text', 'title': 'Cached Doc', 'status': 'READY'}
      ];
      when(() => mockOfflineService.getCachedDocuments()).thenReturn(cachedDocs);

      final result = await apiService.getDocuments();

      expect(result.length, 1);
      expect(result.first.title, 'Cached Doc');
      verifyZeroInteractions(mockDocumentEndpoint);
    });
  });

  group('ApiService - Error Handling', () {
    test('createFromText fallback to offline on server error', () async {
      when(() => mockOfflineService.isOnline).thenReturn(true);
      when(() => mockDocumentEndpoint.createFromText(
        title: any(named: 'title'),
        text: any(named: 'text'),
        userId: any(named: 'userId'),
      )).thenThrow(Exception('Server error'));

      final result = await apiService.createFromText(title: 'Test', text: 'Content');

      expect(result.status, 'PENDING_SYNC'); // Fallback to pending
      verify(() => mockOfflineService.addToSyncQueue(any())).called(1);
    });
  });
}
