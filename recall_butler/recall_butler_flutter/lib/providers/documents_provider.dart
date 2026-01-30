import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_butler_client/recall_butler_client.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import 'connectivity_provider.dart';

// apiServiceProvider is defined in connectivity_provider.dart

/// Provider for all documents
final documentsProvider = StateNotifierProvider<DocumentsNotifier, AsyncValue<List<Document>>>((ref) {
  final api = ref.watch(apiServiceProvider);
  return DocumentsNotifier(api);
});

/// Provider for recent documents (last 10)
final recentDocumentsProvider = FutureProvider<List<Document>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getDocuments(limit: 10);
});

/// Provider for processing documents
final processingDocumentsProvider = FutureProvider<List<Document>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  final docs = await api.getDocuments(limit: 50);
  return docs.where((d) => d.status == 'PROCESSING').toList();
});

/// Notifier for document operations
class DocumentsNotifier extends StateNotifier<AsyncValue<List<Document>>> {
  final ApiService _api;

  DocumentsNotifier(this._api) : super(const AsyncValue.loading()) {
    _loadDocuments();
  }

  Future<void> _loadDocuments() async {
    try {
      final docs = await _api.getDocuments();
      state = AsyncValue.data(docs);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<Document> createFromText({
    required String title,
    required String text,
    bool isVoiceNote = false,
  }) async {
    final doc = await _api.createFromText(
      title: title,
      text: text,
    );
    await _loadDocuments();
    
    // Send notification
    final notificationService = NotificationService();
    if (isVoiceNote) {
      await notificationService.notifyVoiceNoteSaved(
        documentId: doc.id ?? 0,
        title: title,
      );
    } else {
      await notificationService.notifyDocumentReady(
        documentId: doc.id ?? 0,
        title: title,
      );
    }
    
    return doc;
  }

  Future<Document> createFromUrl({
    required String title,
    required String url,
  }) async {
    final doc = await _api.createFromUrl(
      title: title,
      url: url,
    );
    await _loadDocuments();
    
    // Send notification
    final notificationService = NotificationService();
    await notificationService.notifyDocumentReady(
      documentId: doc.id ?? 0,
      title: title,
    );
    
    return doc;
  }

  Future<Document> createFromImage({
    required String title,
    required String imageBase64,
    required String type,
  }) async {
    final doc = await _api.createFromImage(
      title: title,
      imageBase64: imageBase64,
      type: type,
    );
    await _loadDocuments();

    // Send notification
    final notificationService = NotificationService();
    await notificationService.notifyDocumentReady(
      documentId: doc.id ?? 0,
      title: title,
    );

    return doc;
  }

  Future<Document> uploadFile({
    required String title,
    required String fileName,
    required String mimeType,
    required List<int> bytes,
  }) async {
    // Convert file bytes to text for now
    final text = String.fromCharCodes(bytes);
    return createFromText(title: title, text: text);
  }

  Future<void> refresh() => _loadDocuments();

  Future<void> delete(int documentId) async {
    await _api.deleteDocument(documentId);
    await _loadDocuments();
  }
}

/// Provider for a single document
final documentProvider = FutureProvider.family<Document?, int>((ref, id) async {
  final api = ref.watch(apiServiceProvider);
  return api.getDocument(id);
});

/// Provider for document stats
final documentStatsProvider = FutureProvider<Map<String, int>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getStats();
});
