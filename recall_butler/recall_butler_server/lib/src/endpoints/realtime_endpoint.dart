import 'package:serverpod/serverpod.dart';
import '../integrations/realtime_api.dart';
import '../integrations/web5_integration.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// ⚡ REAL-TIME & WEB5 ENDPOINTS
/// ═══════════════════════════════════════════════════════════════════════════════
/// 
/// FastAPI-style async endpoints for:
/// - Real-time event subscriptions
/// - WebSocket connection info
/// - Web5 decentralized identity
/// ═══════════════════════════════════════════════════════════════════════════════

class RealtimeEndpoint extends Endpoint {
  final RealtimeEventBus _eventBus = RealtimeEventBus();
  final Web5Integration _web5 = Web5Integration();

  // ═══════════════════════════════════════════════════════════════════════════
  // REAL-TIME EVENTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get SSE connection info for client
  Future<Map<String, dynamic>> getSSEInfo(Session session) async {
    return {
      'endpoint': '/events/sse',
      'heartbeatInterval': 30,
      'reconnectDelay': 5,
      'supportedEvents': RealtimeEventType.values.map((e) => e.name).toList(),
      'documentation': 'Connect to SSE stream for real-time updates',
    };
  }

  /// Get WebSocket connection info
  Future<Map<String, dynamic>> getWebSocketInfo(Session session) async {
    return {
      'endpoint': '/ws',
      'protocol': 'recall-butler-v1',
      'supportedActions': [
        'subscribe',
        'unsubscribe', 
        'ping',
        'search',
      ],
      'supportedEvents': RealtimeEventType.values.map((e) => e.name).toList(),
      'documentation': 'Connect via WebSocket for bidirectional real-time communication',
    };
  }

  /// Trigger a test event (for debugging)
  Future<Map<String, dynamic>> triggerTestEvent(
    Session session, {
    required int userId,
    required String eventType,
    Map<String, dynamic>? data,
  }) async {
    final type = RealtimeEventType.values.firstWhere(
      (e) => e.name == eventType,
      orElse: () => RealtimeEventType.heartbeat,
    );

    _eventBus.emit(
      type: type,
      data: data ?? {'test': true, 'timestamp': DateTime.now().toIso8601String()},
      userId: userId,
    );

    return {
      'success': true,
      'eventType': eventType,
      'userId': userId,
      'sentAt': DateTime.now().toIso8601String(),
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WEB5 DECENTRALIZED IDENTITY
  // ═══════════════════════════════════════════════════════════════════════════

  /// Create a new Web5 decentralized identity
  Future<Map<String, dynamic>> createWeb5Identity(
    Session session, {
    String? name,
    String? email,
  }) async {
    final identity = await _web5.createIdentity(name: name, email: email);
    
    return {
      'success': true,
      'identity': identity.toJson(),
      'message': 'Decentralized identity created! Your DID is your unique identifier.',
    };
  }

  /// Connect to existing Web5 identity
  Future<Map<String, dynamic>> connectWeb5Identity(
    Session session, {
    required String did,
  }) async {
    try {
      final identity = await _web5.connectIdentity(did);
      
      return {
        'success': true,
        'identity': identity?.toJson(),
        'message': 'Connected to decentralized identity',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Store a memory in user's Decentralized Web Node
  Future<Map<String, dynamic>> storeInDWN(
    Session session, {
    required String title,
    required String content,
    required String sourceType,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final record = await _web5.storeMemory(
        title: title,
        content: content,
        sourceType: sourceType,
        metadata: metadata,
      );

      return {
        'success': true,
        'record': record.toJson(),
        'message': 'Memory stored in your Decentralized Web Node',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Share memories with another user via Verifiable Credential
  Future<Map<String, dynamic>> shareMemories(
    Session session, {
    required String recipientDid,
    required List<String> memoryIds,
    int expiresInDays = 30,
  }) async {
    try {
      final credential = await _web5.createMemoryShareCredential(
        recipientDid: recipientDid,
        memoryIds: memoryIds,
        expiresAt: DateTime.now().add(Duration(days: expiresInDays)),
      );

      return {
        'success': true,
        'credential': credential.toJson(),
        'message': 'Share credential created. Send to recipient for verification.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Export Web5 identity for backup
  Future<Map<String, dynamic>> exportWeb5Identity(Session session) async {
    try {
      final backup = await _web5.exportIdentity();
      
      return {
        'success': true,
        'backup': backup,
        'message': 'Store this backup securely. It contains your identity keys.',
      };
    } catch (e) {
      return {
        'success': false,
        'error': e.toString(),
      };
    }
  }

  /// Get current Web5 DID
  Future<Map<String, dynamic>> getCurrentDID(Session session) async {
    final did = _web5.userDid;
    
    return {
      'success': did != null,
      'did': did,
      'isConnected': did != null,
    };
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SYNC STATUS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get real-time sync status
  Future<Map<String, dynamic>> getSyncStatus(
    Session session, {
    required int userId,
  }) async {
    final syncManager = RealtimeSyncManager();
    final lastSync = syncManager.getLastSync(userId);

    return {
      'lastSync': lastSync?.toIso8601String(),
      'isOnline': true, // Would check actual connectivity
      'pendingChanges': 0, // Would check sync queue
      'status': 'synced',
    };
  }

  /// Trigger manual sync
  Future<Map<String, dynamic>> triggerSync(
    Session session, {
    required int userId,
  }) async {
    final syncManager = RealtimeSyncManager();
    await syncManager.startSync(userId);

    return {
      'success': true,
      'syncedAt': DateTime.now().toIso8601String(),
      'message': 'Sync completed successfully',
    };
  }
}
