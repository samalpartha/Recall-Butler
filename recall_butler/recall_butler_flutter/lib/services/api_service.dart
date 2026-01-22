import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:recall_butler_client/recall_butler_client.dart';
import 'package:serverpod_flutter/serverpod_flutter.dart';
import 'offline_service.dart';

/// Extension to add helper methods to Document
extension DocumentHelpers on Document {
  bool get isProcessing => status == 'PROCESSING' || status == 'EMBEDDING' || status == 'QUEUED';
  bool get isReady => status == 'READY';
  bool get isFailed => status == 'FAILED';
  bool get isPendingSync => status == 'PENDING_SYNC';
  DateTime get createdAt => DateTime.now(); // Placeholder - timestamps not in model
  DateTime get updatedAt => DateTime.now();
  
  /// Convert to map for caching
  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'sourceType': sourceType,
    'title': title,
    'sourceUrl': sourceUrl,
    'mimeType': mimeType,
    'extractedText': extractedText,
    'summary': summary,
    'keyFieldsJson': keyFieldsJson,
    'status': status,
    'errorMessage': errorMessage,
  };
  
  /// Create from map
  static Document fromMap(Map<String, dynamic> map) => Document(
    id: map['id'] as int?,
    userId: map['userId'] as int,
    sourceType: map['sourceType'] as String,
    title: map['title'] as String,
    sourceUrl: map['sourceUrl'] as String?,
    mimeType: map['mimeType'] as String?,
    extractedText: map['extractedText'] as String?,
    summary: map['summary'] as String?,
    keyFieldsJson: map['keyFieldsJson'] as String?,
    status: map['status'] as String,
    errorMessage: map['errorMessage'] as String?,
  );
}

/// Extension to add helper methods to Suggestion
extension SuggestionHelpers on Suggestion {
  Map<String, dynamic> toMap() => {
    'id': id,
    'documentId': documentId,
    'userId': userId,
    'type': type,
    'title': title,
    'description': description,
    'payloadJson': payloadJson,
    'state': state,
    'scheduledAt': scheduledAt?.toIso8601String(),
    'executedAt': executedAt?.toIso8601String(),
  };
  
  static Suggestion fromMap(Map<String, dynamic> map) => Suggestion(
    id: map['id'] as int?,
    documentId: map['documentId'] as int,
    userId: map['userId'] as int,
    type: map['type'] as String,
    title: map['title'] as String,
    description: map['description'] as String,
    payloadJson: map['payloadJson'] as String,
    state: map['state'] as String,
    scheduledAt: map['scheduledAt'] != null ? DateTime.parse(map['scheduledAt']) : null,
    executedAt: map['executedAt'] != null ? DateTime.parse(map['executedAt']) : null,
  );
}

/// Singleton API service using Serverpod client with offline support
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  
  late Client client;
  final OfflineService _offline = OfflineService();
  
  ApiService._internal() {
    // Platform-specific base URL
    // Web: localhost works normally
    // Android emulator: 10.0.2.2 is the special alias for host machine
    // Android device: would need actual IP address (TODO: make configurable)
    final baseUrl = _getBaseUrl();
    debugPrint('🌐 Initializing ApiService with base URL: $baseUrl');
    
    client = Client(baseUrl)
      ..connectivityMonitor = FlutterConnectivityMonitor();
  }
  
  /// Get platform-specific base URL
  String _getBaseUrl() {
    if (kIsWeb) {
      // Web: use localhost
      return 'http://localhost:8182/';
    } else {
      // Mobile/Desktop: check platform
      try {
        if (Platform.isAndroid) {
          // Android emulator: use special alias for host machine
          return 'http://10.0.2.2:8182/';
        } else if (Platform.isIOS) {
          // iOS simulator: localhost works
          return 'http://localhost:8182/';
        } else {
          // macOS, Windows, Linux: localhost
          return 'http://localhost:8182/';
        }
      } catch (e) {
        // Fallback if Platform is not available
        debugPrint('⚠️ Platform detection failed, using localhost: $e');
        return 'http://localhost:8182/';
      }
    }
  }

  /// Initialize offline support
  Future<void> initializeOffline() async {
    await _offline.initialize();
  }

  /// Check if online
  bool get isOnline => _offline.isOnline;
  
  /// Stream of connectivity changes
  Stream<bool> get connectivityStream => _offline.connectivityStream;
  
  /// Get pending sync count
  int get pendingSyncCount => _offline.getPendingSyncCount();

  // ============ Document Operations ============

  Future<Document> createFromText({
    required String title,
    required String text,
    int userId = 1,
  }) async {
    if (_offline.isOnline) {
      try {
        final doc = await client.document.createFromText(
          title: title,
          text: text,
          userId: userId,
        );
        // Cache the created document
        await _offline.cacheDocument(doc.toMap());
        return doc;
      } catch (e) {
        debugPrint('❌ Online create failed, queuing for sync: $e');
        return _createOfflineDocument(title: title, text: text, userId: userId);
      }
    } else {
      return _createOfflineDocument(title: title, text: text, userId: userId);
    }
  }
  
  /// Create a document offline (for sync later)
  Future<Document> _createOfflineDocument({
    required String title,
    required String text,
    int userId = 1,
  }) async {
    // Create a temporary offline document
    final tempId = -DateTime.now().millisecondsSinceEpoch;
    final offlineDoc = Document(
      id: tempId,
      userId: userId,
      sourceType: 'text',
      title: title,
      extractedText: text,
      status: 'PENDING_SYNC',
    );
    
    // Cache locally
    await _offline.cacheDocument(offlineDoc.toMap());
    
    // Add to sync queue
    await _offline.addToSyncQueue(SyncItem(
      id: tempId.toString(),
      type: 'create_document_text',
      data: {'title': title, 'text': text, 'userId': userId},
      createdAt: DateTime.now(),
    ));
    
    debugPrint('📴 Document saved offline for sync: $title');
    return offlineDoc;
  }

  Future<Document> createFromUrl({
    required String title,
    required String url,
    int userId = 1,
  }) async {
    if (_offline.isOnline) {
      try {
        final doc = await client.document.createFromUrl(
          title: title,
          url: url,
          userId: userId,
        );
        await _offline.cacheDocument(doc.toMap());
        return doc;
      } catch (e) {
        debugPrint('❌ URL create requires online: $e');
        // URLs need network, create placeholder
        final tempId = -DateTime.now().millisecondsSinceEpoch;
        final offlineDoc = Document(
          id: tempId,
          userId: userId,
          sourceType: 'url',
          title: title,
          sourceUrl: url,
          status: 'PENDING_SYNC',
        );
        await _offline.cacheDocument(offlineDoc.toMap());
        await _offline.addToSyncQueue(SyncItem(
          id: tempId.toString(),
          type: 'create_document_url',
          data: {'title': title, 'url': url, 'userId': userId},
          createdAt: DateTime.now(),
        ));
        return offlineDoc;
      }
    } else {
      throw OfflineException('URL import requires network connection');
    }
  }

  Future<List<Document>> getDocuments({int userId = 1, int limit = 50}) async {
    if (_offline.isOnline) {
      try {
        final docs = await client.document.getDocuments(userId: userId, limit: limit);
        // Cache all documents
        await _offline.cacheDocuments(docs.map((d) => d.toMap()).toList());
        await _offline.updateLastSyncTime();
        return docs;
      } catch (e) {
        debugPrint('❌ Online fetch failed, using cache: $e');
        return _getCachedDocuments();
      }
    } else {
      return _getCachedDocuments();
    }
  }
  
  /// Get documents from cache
  List<Document> _getCachedDocuments() {
    final cached = _offline.getCachedDocuments();
    return cached.map((m) => DocumentHelpers.fromMap(m)).toList();
  }

  Future<Document?> getDocument(int id) async {
    if (_offline.isOnline) {
      try {
        final doc = await client.document.getDocument(id);
        if (doc != null) {
          await _offline.cacheDocument(doc.toMap());
        }
        return doc;
      } catch (e) {
        debugPrint('❌ Online get failed, checking cache: $e');
        return _getCachedDocument(id);
      }
    } else {
      return _getCachedDocument(id);
    }
  }
  
  Document? _getCachedDocument(int id) {
    final cached = _offline.getCachedDocument(id.toString());
    if (cached != null) {
      return DocumentHelpers.fromMap(cached);
    }
    return null;
  }

  Future<bool> deleteDocument(int id) async {
    if (_offline.isOnline) {
      try {
        final result = await client.document.deleteDocument(id);
        await _offline.removeCachedDocument(id.toString());
        return result;
      } catch (e) {
        debugPrint('❌ Delete failed: $e');
        return false;
      }
    } else {
      // Queue for sync and remove from cache
      await _offline.addToSyncQueue(SyncItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'delete_document',
        data: {'id': id},
        createdAt: DateTime.now(),
      ));
      await _offline.removeCachedDocument(id.toString());
      return true;
    }
  }

  Future<Map<String, int>> getStats({int userId = 1}) async {
    if (_offline.isOnline) {
      try {
        return await client.document.getStats(userId: userId);
      } catch (e) {
        return _getOfflineStats();
      }
    } else {
      return _getOfflineStats();
    }
  }
  
  Map<String, int> _getOfflineStats() {
    final docs = _offline.getCachedDocuments();
    return {
      'total': docs.length,
      'ready': docs.where((d) => d['status'] == 'READY').length,
      'processing': docs.where((d) => d['status'] == 'PROCESSING').length,
      'pendingSync': docs.where((d) => d['status'] == 'PENDING_SYNC').length,
    };
  }

  // ============ Search Operations ============

  Future<SearchResponse> search(String query, {int userId = 1, int topK = 5}) async {
    if (_offline.isOnline) {
      return await client.search.search(
        query: query,
        userId: userId,
        topK: topK,
      );
    } else {
      // Perform basic offline search
      return _offlineSearch(query);
    }
  }
  
  /// Basic offline search (text matching)
  SearchResponse _offlineSearch(String query) {
    final docs = _offline.getCachedDocuments();
    final queryLower = query.toLowerCase();
    
    final results = <SearchResult>[];
    for (final doc in docs) {
      final title = (doc['title'] as String? ?? '').toLowerCase();
      final text = (doc['extractedText'] as String? ?? '').toLowerCase();
      final summary = (doc['summary'] as String? ?? '').toLowerCase();
      
      if (title.contains(queryLower) || text.contains(queryLower) || summary.contains(queryLower)) {
        results.add(SearchResult(
          documentId: doc['id'] as int,
          chunkId: 0,
          title: doc['title'] as String? ?? 'Untitled',
          snippet: _extractSnippet(text, queryLower),
          sourceType: doc['sourceType'] as String? ?? 'text',
          similarity: 0.8, // Placeholder
        ));
      }
    }
    
    return SearchResponse(
      query: query,
      answer: results.isEmpty 
        ? 'No offline results found for "$query"'
        : 'Found ${results.length} offline results (limited search - connect for full AI search)',
      results: results,
      totalResults: results.length,
    );
  }
  
  String _extractSnippet(String text, String query) {
    final index = text.indexOf(query);
    if (index == -1) return text.substring(0, text.length.clamp(0, 150));
    
    final start = (index - 50).clamp(0, text.length);
    final end = (index + query.length + 100).clamp(0, text.length);
    return '...${text.substring(start, end)}...';
  }

  Future<List<SearchResult>> quickSearch(String query, {int userId = 1, int topK = 10}) async {
    if (_offline.isOnline) {
      return await client.search.quickSearch(
        query: query,
        userId: userId,
        topK: topK,
      );
    } else {
      return _offlineSearch(query).results;
    }
  }

  // ============ Suggestion Operations ============

  Future<List<Suggestion>> getSuggestions({int userId = 1, String? state}) async {
    if (_offline.isOnline) {
      try {
        final suggestions = await client.suggestion.getSuggestions(userId: userId, state: state);
        await _offline.cacheSuggestions(suggestions.map((s) => s.toMap()).toList());
        return suggestions;
      } catch (e) {
        return _getCachedSuggestions(state: state);
      }
    } else {
      return _getCachedSuggestions(state: state);
    }
  }
  
  List<Suggestion> _getCachedSuggestions({String? state}) {
    final cached = _offline.getCachedSuggestions(state: state);
    return cached.map((m) => SuggestionHelpers.fromMap(m)).toList();
  }

  Future<int> getPendingCount({int userId = 1}) async {
    if (_offline.isOnline) {
      try {
        return await client.suggestion.getPendingCount(userId: userId);
      } catch (e) {
        return _offline.getCachedSuggestions(state: 'PROPOSED').length;
      }
    } else {
      return _offline.getCachedSuggestions(state: 'PROPOSED').length;
    }
  }

  Future<Suggestion> acceptSuggestion(int id) async {
    if (_offline.isOnline) {
      return await client.suggestion.accept(id);
    } else {
      throw OfflineException('Accepting suggestions requires network connection');
    }
  }

  Future<Suggestion> dismissSuggestion(int id) async {
    if (_offline.isOnline) {
      return await client.suggestion.dismiss(id);
    } else {
      throw OfflineException('Dismissing suggestions requires network connection');
    }
  }

  Future<Suggestion> createReminder({
    required int documentId,
    required String title,
    required String description,
    required DateTime scheduledAt,
    int userId = 1,
  }) async {
    if (_offline.isOnline) {
      return await client.suggestion.createReminder(
        documentId: documentId,
        title: title,
        description: description,
        scheduledAt: scheduledAt,
        userId: userId,
      );
    } else {
      // Queue for sync
      await _offline.addToSyncQueue(SyncItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'create_reminder',
        data: {
          'documentId': documentId,
          'title': title,
          'description': description,
          'scheduledAt': scheduledAt.toIso8601String(),
          'userId': userId,
        },
        createdAt: DateTime.now(),
      ));
      
      // Return a placeholder
      return Suggestion(
        id: -DateTime.now().millisecondsSinceEpoch,
        documentId: documentId,
        userId: userId,
        type: 'reminder',
        title: title,
        description: description,
        payloadJson: '{"pendingSync": true}',
        state: 'PENDING_SYNC',
        scheduledAt: scheduledAt,
      );
    }
  }
  
  /// Sync all pending items
  Future<void> syncPending() async {
    await _offline.syncPendingItems();
  }

  // ============ Analytics Operations ============

  /// Get analytics summary
  Future<Map<String, dynamic>> getAnalytics({int userId = 1}) async {
    if (_offline.isOnline) {
      try {
        // Try to get from server
        final stats = await getStats(userId: userId);
        final suggestions = await getSuggestions(userId: userId);
        
        final accepted = suggestions.where((s) => s.state == 'ACCEPTED').length;
        final pending = suggestions.where((s) => s.state == 'PROPOSED').length;
        
        return {
          'documents': {
            'total': stats['total'] ?? 0,
            'thisWeek': stats['ready'] ?? 0,
            'thisMonth': stats['total'] ?? 0,
            'growth': stats['total'] != null && stats['total']! > 0 
              ? ((stats['ready'] ?? 0) / stats['total']! * 100) 
              : 0.0,
          },
          'suggestions': {
            'total': suggestions.length,
            'accepted': accepted,
            'pending': pending,
            'acceptanceRate': suggestions.isNotEmpty 
              ? (accepted / suggestions.length * 100)
              : 0.0,
          },
          'searches': {
            'total': 0, // Would need search logging
            'thisWeek': 0,
          },
          'timestamp': DateTime.now().toIso8601String(),
        };
      } catch (e) {
        debugPrint('❌ Analytics fetch failed: $e');
        return _getOfflineAnalytics();
      }
    } else {
      return _getOfflineAnalytics();
    }
  }
  
  Map<String, dynamic> _getOfflineAnalytics() {
    final docs = _offline.getCachedDocuments();
    final suggestions = _offline.getCachedSuggestions();
    
    final accepted = suggestions.where((s) => s['state'] == 'ACCEPTED').length;
    final pending = suggestions.where((s) => s['state'] == 'PROPOSED').length;
    
    return {
      'documents': {
        'total': docs.length,
        'thisWeek': docs.where((d) => d['status'] == 'READY').length,
        'thisMonth': docs.length,
        'growth': docs.isNotEmpty 
          ? (docs.where((d) => d['status'] == 'READY').length / docs.length * 100)
          : 0.0,
      },
      'suggestions': {
        'total': suggestions.length,
        'accepted': accepted,
        'pending': pending,
        'acceptanceRate': suggestions.isNotEmpty 
          ? (accepted / suggestions.length * 100)
          : 0.0,
      },
      'searches': {'total': 0, 'thisWeek': 0},
      'timestamp': DateTime.now().toIso8601String(),
    };
  }

  /// Get AI-generated insights
  Future<Map<String, dynamic>> getInsights({int userId = 1}) async {
    final analytics = await getAnalytics(userId: userId);
    final docs = analytics['documents'] as Map<String, dynamic>;
    final suggestions = analytics['suggestions'] as Map<String, dynamic>;
    
    final insights = <Map<String, dynamic>>[];
    
    final docTotal = docs['total'] ?? 0;
    final pending = suggestions['pending'] ?? 0;
    
    if (docTotal > 10) {
      insights.add({
        'type': 'productivity',
        'icon': '🚀',
        'title': 'Growing Memory Library!',
        'description': 'You have $docTotal memories stored. Your recall system is building nicely!',
        'priority': 'high',
      });
    } else if (docTotal == 0) {
      insights.add({
        'type': 'engagement',
        'icon': '💡',
        'title': 'Get Started',
        'description': 'Start adding memories to build your personal knowledge base!',
        'priority': 'medium',
      });
    } else {
      insights.add({
        'type': 'progress',
        'icon': '📚',
        'title': 'Building Your Library',
        'description': 'You have $docTotal memories. Keep adding more for better recall!',
        'priority': 'low',
      });
    }
    
    if (pending > 0) {
      insights.add({
        'type': 'action',
        'icon': '⏰',
        'title': 'Pending Suggestions',
        'description': 'You have $pending suggestions waiting for your review.',
        'priority': pending > 5 ? 'high' : 'medium',
      });
    }
    
    if (!_offline.isOnline) {
      insights.add({
        'type': 'offline',
        'icon': '📴',
        'title': 'Offline Mode',
        'description': 'Some features are limited. Connect to sync your data.',
        'priority': 'medium',
      });
    }
    
    return {
      'insights': insights,
      'metrics': {
        'recentDocuments': docTotal,
        'pendingSuggestions': pending,
      },
      'generatedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Get knowledge graph data
  Future<Map<String, dynamic>> getKnowledgeGraph({int userId = 1}) async {
    final docs = _offline.isOnline 
      ? await getDocuments(userId: userId)
      : _getCachedDocuments();
    
    final nodes = <Map<String, dynamic>>[];
    final edges = <Map<String, dynamic>>[];
    final keywordDocs = <String, List<int>>{};
    
    for (var i = 0; i < docs.length; i++) {
      final doc = docs[i];
      nodes.add({
        'id': 'doc_${doc.id}',
        'label': (doc.title.length > 25) 
          ? '${doc.title.substring(0, 25)}...' 
          : doc.title,
        'type': 'document',
        'sourceType': doc.sourceType,
        'size': 20,
      });
      
      // Extract keywords from summary or key fields
      final text = '${doc.summary ?? ''} ${doc.keyFieldsJson ?? ''}'.toLowerCase();
      final words = text.split(RegExp(r'[^a-z0-9]+'))
        .where((w) => w.length > 4 && w.length < 15)
        .take(5);
      
      for (final word in words) {
        keywordDocs.putIfAbsent(word, () => []);
        keywordDocs[word]!.add(i);
      }
    }
    
    // Create keyword nodes and edges for shared keywords
    keywordDocs.forEach((keyword, docIndices) {
      if (docIndices.length > 1 && docIndices.length <= 5) {
        final kwId = 'kw_$keyword';
        nodes.add({
          'id': kwId,
          'label': keyword,
          'type': 'keyword',
          'size': 12,
        });
        
        for (final idx in docIndices) {
          edges.add({
            'source': 'doc_${docs[idx].id}',
            'target': kwId,
          });
        }
      }
    });
    
    return {
      'nodes': nodes,
      'edges': edges,
      'stats': {
        'documents': docs.length,
        'keywords': nodes.where((n) => n['type'] == 'keyword').length,
        'connections': edges.length,
      },
    };
  }
}

/// Exception for offline operations
class OfflineException implements Exception {
  final String message;
  OfflineException(this.message);
  
  @override
  String toString() => 'OfflineException: $message';
}
