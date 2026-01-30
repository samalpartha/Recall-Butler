import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Offline sync service - handles local caching and sync queue
class OfflineService {
  static OfflineService? _mockInstance;
  static final OfflineService _instance = OfflineService._internal();

  factory OfflineService() => _mockInstance ?? _instance;

  OfflineService._internal() {
    _connectivity = Connectivity();
    _hive = Hive;
  }

  /// Constructor for testing
  @visibleForTesting
  OfflineService.test({
    required Connectivity connectivity,
    required HiveInterface hive,
  }) {
    _connectivity = connectivity;
    _hive = hive;
    _mockInstance = this;
  }
  
  // Hive boxes
  static const String _documentsBox = 'documents_cache';
  static const String _suggestionsBox = 'suggestions_cache';
  static const String _syncQueueBox = 'sync_queue';
  static const String _settingsBox = 'settings';

  Box? _documents;
  Box? _suggestions;
  Box? _syncQueue;
  Box? _settings;

  // Dependencies
  late final Connectivity _connectivity;
  late final HiveInterface _hive;
  StreamSubscription? _connectivitySubscription;
  
  bool _isOnline = true;
  bool _isInitialized = false;

  // Stream for connectivity changes
  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get connectivityStream => _connectivityController.stream;
  bool get isOnline => _isOnline;
  bool get isInitialized => _isInitialized;

  /// Initialize offline service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize Hive
      // Note: initFlutter is an extension method on HiveInterface in hive_flutter
      // For testing, we might need to skip this or mock it differently if using strict mocks
      if (_hive == Hive) {
        await Hive.initFlutter();
      }

      // Open boxes
      _documents = await _hive.openBox(_documentsBox);
      _suggestions = await _hive.openBox(_suggestionsBox);
      _syncQueue = await _hive.openBox(_syncQueueBox);
      _settings = await _hive.openBox(_settingsBox);

      // Check initial connectivity
      final result = await _connectivity.checkConnectivity();
      _isOnline = !result.contains(ConnectivityResult.none);
      _connectivityController.add(_isOnline);

      // Listen for connectivity changes
      _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
        final wasOnline = _isOnline;
        _isOnline = !results.contains(ConnectivityResult.none);
        
        if (_isOnline != wasOnline) {
          _connectivityController.add(_isOnline);
          debugPrint('📶 Connectivity changed: ${_isOnline ? "Online" : "Offline"}');
          
          if (_isOnline) {
            // Sync pending items when back online
            syncPendingItems();
          }
        }
      });

      _isInitialized = true;
      debugPrint('✅ Offline service initialized');
    } catch (e) {
      debugPrint('❌ Failed to initialize offline service: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectivityController.close();
  }

  // ========== Document Caching ==========

  /// Cache a document locally
  Future<void> cacheDocument(Map<String, dynamic> document) async {
    if (_documents == null) return;
    
    final id = document['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
    await _documents!.put(id, jsonEncode(document));
    debugPrint('📦 Cached document: $id');
  }

  /// Cache multiple documents
  Future<void> cacheDocuments(List<Map<String, dynamic>> documents) async {
    if (_documents == null) return;
    
    for (final doc in documents) {
      await cacheDocument(doc);
    }
    debugPrint('📦 Cached ${documents.length} documents');
  }

  /// Get cached documents
  List<Map<String, dynamic>> getCachedDocuments() {
    if (_documents == null) return [];
    
    final docs = <Map<String, dynamic>>[];
    for (final key in _documents!.keys) {
      try {
        final json = _documents!.get(key) as String?;
        if (json != null) {
          docs.add(jsonDecode(json) as Map<String, dynamic>);
        }
      } catch (e) {
        debugPrint('Error reading cached document: $e');
      }
    }
    
    // Sort by id descending (newest first)
    docs.sort((a, b) => (b['id'] ?? 0).compareTo(a['id'] ?? 0));
    return docs;
  }

  /// Get a single cached document
  Map<String, dynamic>? getCachedDocument(String id) {
    if (_documents == null) return null;
    
    try {
      final json = _documents!.get(id) as String?;
      if (json != null) {
        return jsonDecode(json) as Map<String, dynamic>;
      }
    } catch (e) {
      debugPrint('Error reading cached document: $e');
    }
    return null;
  }

  /// Remove a cached document
  Future<void> removeCachedDocument(String id) async {
    if (_documents == null) return;
    await _documents!.delete(id);
  }

  /// Clear all cached documents
  Future<void> clearDocumentCache() async {
    if (_documents == null) return;
    await _documents!.clear();
  }

  // ========== Suggestion Caching ==========

  /// Cache suggestions locally
  Future<void> cacheSuggestions(List<Map<String, dynamic>> suggestions) async {
    if (_suggestions == null) return;
    
    await _suggestions!.clear();
    for (final suggestion in suggestions) {
      final id = suggestion['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
      await _suggestions!.put(id, jsonEncode(suggestion));
    }
    debugPrint('📦 Cached ${suggestions.length} suggestions');
  }

  /// Get cached suggestions
  List<Map<String, dynamic>> getCachedSuggestions({String? state}) {
    if (_suggestions == null) return [];
    
    final suggestions = <Map<String, dynamic>>[];
    for (final key in _suggestions!.keys) {
      try {
        final json = _suggestions!.get(key) as String?;
        if (json != null) {
          final suggestion = jsonDecode(json) as Map<String, dynamic>;
          if (state == null || suggestion['state'] == state) {
            suggestions.add(suggestion);
          }
        }
      } catch (e) {
        debugPrint('Error reading cached suggestion: $e');
      }
    }
    return suggestions;
  }

  // ========== Sync Queue ==========

  /// Add item to sync queue (for offline operations)
  Future<void> addToSyncQueue(SyncItem item) async {
    if (_syncQueue == null) return;
    
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    await _syncQueue!.put(id, jsonEncode(item.toJson()));
    debugPrint('📤 Added to sync queue: ${item.type}');
  }

  /// Get pending sync items
  List<SyncItem> getPendingSyncItems() {
    if (_syncQueue == null) return [];
    
    final items = <SyncItem>[];
    for (final key in _syncQueue!.keys) {
      try {
        final json = _syncQueue!.get(key) as String?;
        if (json != null) {
          items.add(SyncItem.fromJson(jsonDecode(json), key));
        }
      } catch (e) {
        debugPrint('Error reading sync item: $e');
      }
    }
    return items;
  }

  /// Get pending sync count
  int getPendingSyncCount() {
    return _syncQueue?.length ?? 0;
  }

  /// Remove item from sync queue
  Future<void> removeFromSyncQueue(String id) async {
    if (_syncQueue == null) return;
    await _syncQueue!.delete(id);
  }

  /// Sync pending items when back online
  Future<void> syncPendingItems() async {
    if (!_isOnline) return;
    
    final items = getPendingSyncItems();
    if (items.isEmpty) return;
    
    debugPrint('🔄 Syncing ${items.length} pending items...');
    
    for (final item in items) {
      try {
        // Execute sync operation based on type
        await _executeSyncItem(item);
        await removeFromSyncQueue(item.id);
        debugPrint('✅ Synced: ${item.type}');
      } catch (e) {
        debugPrint('❌ Failed to sync ${item.type}: $e');
        // Keep in queue for retry
      }
    }
  }

  // Sync Handlers
  final Map<String, Future<void> Function(Map<String, dynamic>)> _handlers = {};

  /// Register a handler for a sync item type
  void registerHandler(String type, Future<void> Function(Map<String, dynamic>) handler) {
    _handlers[type] = handler;
  }

  /// Execute a sync item
  Future<void> _executeSyncItem(SyncItem item) async {
    final handler = _handlers[item.type];
    if (handler != null) {
      final data = Map<String, dynamic>.from(item.data);
      data['__sync_id__'] = item.id;
      await handler(data);
    } else if (item.syncCallback != null) {
      await item.syncCallback!();
    } else {
      debugPrint('⚠️ No handler registered for sync type: ${item.type}');
    }
  }

  // ========== Settings ==========

  /// Save a setting
  Future<void> saveSetting(String key, dynamic value) async {
    if (_settings == null) return;
    await _settings!.put(key, jsonEncode(value));
  }

  /// Get a setting
  T? getSetting<T>(String key) {
    if (_settings == null) return null;
    try {
      final json = _settings!.get(key) as String?;
      if (json != null) {
        return jsonDecode(json) as T;
      }
    } catch (e) {
      debugPrint('Error reading setting: $e');
    }
    return null;
  }

  /// Get last sync time
  DateTime? getLastSyncTime() {
    final timestamp = getSetting<int>('lastSyncTime');
    if (timestamp != null) {
      return DateTime.fromMillisecondsSinceEpoch(timestamp);
    }
    return null;
  }

  /// Update last sync time
  Future<void> updateLastSyncTime() async {
    await saveSetting('lastSyncTime', DateTime.now().millisecondsSinceEpoch);
  }
}

/// Sync item for offline queue
class SyncItem {
  final String id;
  final String type; // 'create_document', 'create_reminder', etc.
  final Map<String, dynamic> data;
  final DateTime createdAt;
  final Future<void> Function()? syncCallback;

  SyncItem({
    required this.id,
    required this.type,
    required this.data,
    required this.createdAt,
    this.syncCallback,
  });

  Map<String, dynamic> toJson() => {
    'type': type,
    'data': data,
    'createdAt': createdAt.millisecondsSinceEpoch,
  };

  factory SyncItem.fromJson(Map<String, dynamic> json, String id) {
    return SyncItem(
      id: id,
      type: json['type'] as String,
      data: json['data'] as Map<String, dynamic>,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    );
  }
}
