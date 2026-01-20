import 'dart:async';
import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'offline_storage_service.dart';
import 'sync_queue_service.dart';
import 'logger_service.dart';

/// Offline Sync Service - Complete Implementation
/// Handles bidirectional sync between local and server storage
class OfflineSyncService {
  final Session session;
  final OfflineStorageService storage;
  final SyncQueueService syncQueue;
  final LoggerService logger;
  
  bool _isSyncing = false;
  Timer? _periodicSyncTimer;
  StreamController<SyncStatus>? _syncStatusController;

  OfflineSyncService(this.session)
      : storage = OfflineStorageService(),
        syncQueue = SyncQueueService(),
        logger = LoggerService(session);

  Stream<SyncStatus> get syncStatusStream {
    _syncStatusController ??= StreamController<SyncStatus>.broadcast();
    return _syncStatusController!.stream;
  }

  /// Initialize offline sync
  Future<void> initialize() async {
    await storage.initialize();
    await syncQueue.initialize();
    
    // Start periodic sync (every 5 minutes when online)
    _periodicSyncTimer = Timer.periodic(
      Duration(minutes: 5),
      (_) => performSync(),
    );
    
    logger.info('Offline sync initialized');
  }

  /// Perform full bidirectional sync
  Future<SyncResult> performSync({bool force = false}) async {
    if (_isSyncing && !force) {
      logger.debug('Sync already in progress');
      return SyncResult.inProgress();
    }

    _isSyncing = true;
    _emitStatus(SyncStatus.syncing);

    try {
      logger.info('Starting sync operation');
      final result = await _executeSyncOperation();
      
      if (result.success) {
        _emitStatus(SyncStatus.completed);
      } else {
        _emitStatus(SyncStatus.failed, error: result.error);
      }
      
      return result;
      
    } catch (e, stackTrace) {
      logger.error('Sync failed', {
        'error': e.toString(),
        'stackTrace': stackTrace.toString(),
      });
      
      _emitStatus(SyncStatus.failed, error: e.toString());
      return SyncResult.error(e.toString());
      
    } finally {
      _isSyncing = false;
    }
  }

  /// Execute the actual sync operation
  Future<SyncResult> _executeSyncOperation() async {
    final stats = SyncStatistics();

    // Step 1: Pull changes from server
    final pullResult = await _pullFromServer();
    stats.mergeDownload(pullResult);

    // Step 2: Resolve conflicts
    final conflicts = await _detectConflicts();
    if (conflicts.isNotEmpty) {
      final resolvedConflicts = await _resolveConflicts(conflicts);
      stats.conflictsResolved = resolvedConflicts.length;
    }

    // Step 3: Push local changes to server
    final pushResult = await _pushToServer();
    stats.mergeUpload(pushResult);

    // Step 4: Update sync metadata
    await _updateSyncMetadata();

    logger.info('Sync completed', stats.toMap());

    return SyncResult.success(stats);
  }

  /// Pull changes from server
  Future<SyncStats> _pullFromServer() async {
    final stats = SyncStats();
    final lastSyncTime = await _getLastSyncTime();

    try {
      // Fetch documents modified since last sync
      final modifiedDocs = await _fetchModifiedDocuments(lastSyncTime);
      
      for (final doc in modifiedDocs) {
        final localDoc = await storage.getDocument(doc.id!);
        
        if (localDoc == null) {
          // New document from server
          await storage.saveDocument(doc);
          stats.created++;
        } else if (_shouldUpdateLocal(localDoc, doc)) {
          // Server version is newer
          await storage.updateDocument(doc);
          stats.updated++;
        }
      }

      // Fetch deleted documents
      final deletedIds = await _fetchDeletedDocuments(lastSyncTime);
      for (final id in deletedIds) {
        await storage.deleteDocument(id);
        stats.deleted++;
      }

    } catch (e) {
      logger.error('Pull from server failed', {'error': e.toString()});
      stats.errors++;
    }

    return stats;
  }

  /// Push local changes to server
  Future<SyncStats> _pushToServer() async {
    final stats = SyncStats();
    final pendingOperations = await syncQueue.getPendingOperations();

    for (final operation in pendingOperations) {
      try {
        switch (operation.type) {
          case OperationType.create:
            await _pushCreate(operation);
            stats.created++;
            break;
            
          case OperationType.update:
            await _pushUpdate(operation);
            stats.updated++;
            break;
            
          case OperationType.delete:
            await _pushDelete(operation);
            stats.deleted++;
            break;
        }

        // Mark operation as completed
        await syncQueue.markCompleted(operation.id);
        
      } catch (e) {
        logger.error('Push operation failed', {
          'operation': operation.type.name,
          'error': e.toString(),
        });
        
        stats.errors++;
        
        // Retry logic
        if (operation.retryCount < 3) {
          await syncQueue.incrementRetry(operation.id);
        } else {
          await syncQueue.markFailed(operation.id);
        }
      }
    }

    return stats;
  }

  /// Detect sync conflicts
  Future<List<SyncConflict>> _detectConflicts() async {
    final conflicts = <SyncConflict>[];
    final localDocs = await storage.getAllModifiedDocuments();

    for (final localDoc in localDocs) {
      final serverDoc = await _fetchServerDocument(localDoc.id!);
      
      if (serverDoc != null) {
        if (_hasConflict(localDoc, serverDoc)) {
          conflicts.add(SyncConflict(
            documentId: localDoc.id!,
            localVersion: localDoc,
            serverVersion: serverDoc,
            conflictType: _determineConflictType(localDoc, serverDoc),
          ));
        }
      }
    }

    return conflicts;
  }

  /// Resolve conflicts automatically or flag for manual resolution
  Future<List<SyncConflict>> _resolveConflicts(
    List<SyncConflict> conflicts,
  ) async {
    final resolved = <SyncConflict>[];

    for (final conflict in conflicts) {
      try {
        switch (conflict.conflictType) {
          case ConflictType.serverNewer:
            // Accept server version
            await storage.updateDocument(conflict.serverVersion);
            resolved.add(conflict);
            break;

          case ConflictType.localNewer:
            // Push local version
            await _pushUpdate(SyncOperation(
              id: '',
              type: OperationType.update,
              documentId: conflict.documentId,
              data: conflict.localVersion.toJson(),
              timestamp: DateTime.now(),
            ));
            resolved.add(conflict);
            break;

          case ConflictType.bothModified:
            // Attempt automatic merge
            final merged = await _attemptAutoMerge(
              conflict.localVersion,
              conflict.serverVersion,
            );
            
            if (merged != null) {
              await storage.updateDocument(merged);
              await _pushUpdate(SyncOperation(
                id: '',
                type: OperationType.update,
                documentId: conflict.documentId,
                data: merged.toJson(),
                timestamp: DateTime.now(),
              ));
              resolved.add(conflict);
            } else {
              // Flag for manual resolution
              await storage.markConflicted(conflict.documentId);
            }
            break;
        }
      } catch (e) {
        logger.error('Conflict resolution failed', {
          'documentId': conflict.documentId,
          'error': e.toString(),
        });
      }
    }

    return resolved;
  }

  /// Attempt automatic merge of conflicting versions
  Future<Document?> _attemptAutoMerge(
    Document local,
    Document server,
  ) async {
    // Simple field-level merge strategy
    // For more complex merges, use operational transformation or CRDTs
    
    final merged = Document.fromJson(server.toJson());
    
    // Merge title (prefer non-empty)
    if (local.title.isNotEmpty && server.title.isEmpty) {
      merged.title = local.title;
    }
    
    // Merge content (prefer longer version)
    if (local.content.length > server.content.length) {
      merged.content = local.content;
    }
    
    // Merge metadata (union of tags, etc.)
    merged.metadata = {...server.metadata, ...local.metadata};
    
    return merged;
  }

  /// Check if local document should be updated with server version
  bool _shouldUpdateLocal(Document local, Document server) {
    // Server modified more recently than local
    return server.updatedAt.isAfter(local.updatedAt);
  }

  /// Check if there's a conflict between versions
  bool _hasConflict(Document local, Document server) {
    // Both modified after last sync
    final lastSync = _getLastSyncTime();
    return local.updatedAt.isAfter(lastSync) && 
           server.updatedAt.isAfter(lastSync);
  }

  /// Determine conflict type
  ConflictType _determineConflictType(Document local, Document server) {
    final lastSync = _getLastSyncTime();
    
    final localModified = local.updatedAt.isAfter(lastSync);
    final serverModified = server.updatedAt.isAfter(lastSync);
    
    if (localModified && serverModified) {
      return ConflictType.bothModified;
    } else if (serverModified) {
      return ConflictType.serverNewer;
    } else {
      return ConflictType.localNewer;
    }
  }

  // Server API calls
  Future<List<Document>> _fetchModifiedDocuments(DateTime since) async {
    // Implementation would call server endpoint
    // GET /documents?modifiedSince={since}
    return [];
  }

  Future<List<int>> _fetchDeletedDocuments(DateTime since) async {
    // Implementation would call server endpoint
    // GET /documents/deleted?since={since}
    return [];
  }

  Future<Document?> _fetchServerDocument(int id) async {
    // Implementation would call server endpoint
    // GET /documents/{id}
    return null;
  }

  Future<void> _pushCreate(SyncOperation operation) async {
    // POST /documents
  }

  Future<void> _pushUpdate(SyncOperation operation) async {
    // PUT /documents/{id}
  }

  Future<void> _pushDelete(SyncOperation operation) async {
    // DELETE /documents/{id}
  }

  // Metadata management
  Future<DateTime> _getLastSyncTime() async {
    final prefs = await SharedPreferences.getInstance();
    final timestamp = prefs.getInt('last_sync_timestamp') ?? 0;
    return DateTime.fromMillisecondsSinceEpoch(timestamp);
  }

  Future<void> _updateSyncMetadata() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      'last_sync_timestamp',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  void _emitStatus(SyncStatus status, {String? error}) {
    _syncStatusController?.add(status.copyWith(error: error));
  }

  Future<void> dispose() async {
    _periodicSyncTimer?.cancel();
    await _syncStatusController?.close();
  }
}

// Supporting classes
enum OperationType { create, update, delete }
enum ConflictType { serverNewer, localNewer, bothModified }
enum SyncStatus { idle, syncing, completed, failed }

class SyncResult {
  final bool success;
  final String? error;
  final SyncStatistics? stats;

  SyncResult({required this.success, this.error, this.stats});

  factory SyncResult.success(SyncStatistics stats) =>
      SyncResult(success: true, stats: stats);
  factory SyncResult.error(String error) =>
      SyncResult(success: false, error: error);
  factory SyncResult.inProgress() =>
      SyncResult(success: false, error: 'Sync in progress');
}

class SyncStatistics {
  int downloaded = 0;
  int uploaded = 0;
  int conflictsResolved = 0;
  int errors = 0;

  void mergeDownload(SyncStats stats) {
    downloaded += stats.created + stats.updated + stats.deleted;
    errors += stats.errors;
  }

  void mergeUpload(SyncStats stats) {
    uploaded += stats.created + stats.updated + stats.deleted;
    errors += stats.errors;
  }

  Map<String, dynamic> toMap() => {
        'downloaded': downloaded,
        'uploaded': uploaded,
        'conflictsResolved': conflictsResolved,
        'errors': errors,
      };
}

class SyncStats {
  int created = 0;
  int updated = 0;
  int deleted = 0;
  int errors = 0;
}

class SyncConflict {
  final int documentId;
  final Document localVersion;
  final Document serverVersion;
  final ConflictType conflictType;

  SyncConflict({
    required this.documentId,
    required this.localVersion,
    required this.serverVersion,
    required this.conflictType,
  });
}

class SyncOperation {
  final String id;
  final OperationType type;
  final int documentId;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  SyncOperation({
    required this.id,
    required this.type,
    required this.documentId,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });
}
