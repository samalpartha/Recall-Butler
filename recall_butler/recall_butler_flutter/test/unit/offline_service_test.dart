import 'package:flutter_test/flutter_test.dart';
import 'package:recall_butler_flutter/services/offline_service.dart';

void main() {
  group('OfflineService', () {
    test('is singleton', () {
      final instance1 = OfflineService();
      final instance2 = OfflineService();
      expect(identical(instance1, instance2), isTrue);
    });
  });

  group('SyncOperation', () {
    test('serializes to JSON correctly', () {
      final operation = SyncOperation(
        type: SyncOperationType.createDocumentText,
        payload: {'title': 'Test', 'text': 'Content'},
        tempId: 123,
      );

      final json = operation.toJson();
      
      expect(json['type'], 'SyncOperationType.createDocumentText');
      expect(json['payload']['title'], 'Test');
      expect(json['payload']['text'], 'Content');
      expect(json['tempId'], 123);
    });

    test('deserializes from JSON correctly', () {
      final json = {
        'type': 'SyncOperationType.createDocumentText',
        'payload': {'title': 'Test', 'text': 'Content'},
        'tempId': 123,
      };

      final operation = SyncOperation.fromJson(json);
      
      expect(operation.type, SyncOperationType.createDocumentText);
      expect(operation.payload['title'], 'Test');
      expect(operation.tempId, 123);
    });

    test('handles null tempId', () {
      final operation = SyncOperation(
        type: SyncOperationType.deleteDocument,
        payload: {'documentId': 456},
      );

      final json = operation.toJson();
      expect(json['tempId'], isNull);

      final restored = SyncOperation.fromJson(json);
      expect(restored.tempId, isNull);
    });
  });

  group('SyncOperationType', () {
    test('has all required types', () {
      expect(SyncOperationType.values, contains(SyncOperationType.createDocumentText));
      expect(SyncOperationType.values, contains(SyncOperationType.createDocumentUrl));
      expect(SyncOperationType.values, contains(SyncOperationType.deleteDocument));
      expect(SyncOperationType.values, contains(SyncOperationType.acceptSuggestion));
      expect(SyncOperationType.values, contains(SyncOperationType.dismissSuggestion));
      expect(SyncOperationType.values, contains(SyncOperationType.createReminder));
    });
  });
}
