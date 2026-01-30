import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:hive/hive.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:recall_butler_flutter/services/offline_service.dart';

class MockConnectivity extends Mock implements Connectivity {}
class MockHiveInterface extends Mock implements HiveInterface {}
class MockBox extends Mock implements Box {}

void main() {
  late OfflineService offlineService;
  late MockConnectivity mockConnectivity;
  late MockHiveInterface mockHive;
  late MockBox mockBox;

  setUp(() {
    mockConnectivity = MockConnectivity();
    mockHive = MockHiveInterface();
    mockBox = MockBox();

    // Mock Hive behavior
    when(() => mockHive.openBox(any())).thenAnswer((_) async => mockBox);
    
    // Mock Box behavior
    when(() => mockBox.put(any(), any())).thenAnswer((_) async => null);
    when(() => mockBox.get(any())).thenReturn(null);
    when(() => mockBox.delete(any())).thenAnswer((_) async => null);
    when(() => mockBox.clear()).thenAnswer((_) async => 0);
    when(() => mockBox.keys).thenReturn([]);
    
    // Mock Connectivity behavior
    when(() => mockConnectivity.checkConnectivity())
        .thenAnswer((_) async => [ConnectivityResult.wifi]);
    when(() => mockConnectivity.onConnectivityChanged)
        .thenAnswer((_) => Stream.value([ConnectivityResult.wifi]));

    offlineService = OfflineService.test(
      connectivity: mockConnectivity,
      hive: mockHive,
    );
  });

  test('initialize sets up hive and connectivity', () async {
    await offlineService.initialize();

    verify(() => mockHive.openBox('documents_cache')).called(1);
    verify(() => mockConnectivity.checkConnectivity()).called(1);
    expect(offlineService.isOnline, isTrue);
  });

  test('cacheDocument saves to hive', () async {
    await offlineService.initialize();
    
    final doc = {'id': '1', 'title': 'Test'};
    await offlineService.cacheDocument(doc);

    verify(() => mockBox.put('1', any())).called(1);
  });
  
  test('addToSyncQueue saves to hive', () async {
    await offlineService.initialize();
    
    final item = SyncItem(
      id: '123',
      type: 'create_doc',
      data: {},
      createdAt: DateTime.now(),
    );
    
    await offlineService.addToSyncQueue(item);
    
    verify(() => mockBox.put(any(), any())).called(1);
  });
  
  test('connectivity change updates isOnline', () async {
    final controller = StreamController<List<ConnectivityResult>>();
    when(() => mockConnectivity.onConnectivityChanged).thenAnswer((_) => controller.stream);
    
    // Re-initialize to pick up the new stream
    offlineService = OfflineService.test(
      connectivity: mockConnectivity,
      hive: mockHive,
    );
    
    await offlineService.initialize();
    
    // Go offline
    controller.add([ConnectivityResult.none]);
    await Future.delayed(Duration.zero);
    expect(offlineService.isOnline, isFalse);
    
    // Go online
    controller.add([ConnectivityResult.mobile]);
    await Future.delayed(Duration.zero);
    expect(offlineService.isOnline, isTrue);
  });
}
