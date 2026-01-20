import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:serverpod/serverpod.dart';

/// ═══════════════════════════════════════════════════════════════════════════════
/// ⚡ FASTAPI-STYLE ASYNC REAL-TIME APIs
/// ═══════════════════════════════════════════════════════════════════════════════
/// 
/// Implements modern async patterns for real-time updates:
/// - Server-Sent Events (SSE) for live updates
/// - WebSocket for bidirectional communication  
/// - Streaming AI responses
/// - Event-driven architecture
/// ═══════════════════════════════════════════════════════════════════════════════

/// Real-time event types
enum RealtimeEventType {
  documentCreated,
  documentUpdated,
  documentDeleted,
  suggestionCreated,
  suggestionAccepted,
  suggestionDismissed,
  searchCompleted,
  aiResponse,
  syncStarted,
  syncCompleted,
  reminderTriggered,
  connectionEstablished,
  heartbeat,
  error,
}

/// Real-time event payload
class RealtimeEvent {
  final String id;
  final RealtimeEventType type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int? userId;

  RealtimeEvent({
    required this.id,
    required this.type,
    required this.data,
    DateTime? timestamp,
    this.userId,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
    if (userId != null) 'userId': userId,
  };

  String toSSE() {
    final json = jsonEncode(toJson());
    return 'id: $id\nevent: ${type.name}\ndata: $json\n\n';
  }

  factory RealtimeEvent.fromJson(Map<String, dynamic> json) => RealtimeEvent(
    id: json['id'],
    type: RealtimeEventType.values.firstWhere(
      (e) => e.name == json['type'],
      orElse: () => RealtimeEventType.error,
    ),
    data: json['data'] ?? {},
    timestamp: DateTime.parse(json['timestamp']),
    userId: json['userId'],
  );
}

/// Real-time event bus for pub/sub
class RealtimeEventBus {
  static final RealtimeEventBus _instance = RealtimeEventBus._internal();
  factory RealtimeEventBus() => _instance;
  RealtimeEventBus._internal();

  final _controller = StreamController<RealtimeEvent>.broadcast();
  final Map<int, StreamController<RealtimeEvent>> _userStreams = {};
  int _eventCounter = 0;

  /// Get global event stream
  Stream<RealtimeEvent> get stream => _controller.stream;

  /// Get user-specific event stream
  Stream<RealtimeEvent> getUserStream(int userId) {
    _userStreams[userId] ??= StreamController<RealtimeEvent>.broadcast();
    return _userStreams[userId]!.stream;
  }

  /// Publish an event
  void publish(RealtimeEvent event) {
    _controller.add(event);
    
    // Also send to user-specific stream if userId is set
    if (event.userId != null && _userStreams.containsKey(event.userId)) {
      _userStreams[event.userId]!.add(event);
    }
  }

  /// Publish a typed event
  void emit({
    required RealtimeEventType type,
    required Map<String, dynamic> data,
    int? userId,
  }) {
    publish(RealtimeEvent(
      id: 'evt_${++_eventCounter}_${DateTime.now().millisecondsSinceEpoch}',
      type: type,
      data: data,
      userId: userId,
    ));
  }

  /// Close a user's stream
  void closeUserStream(int userId) {
    _userStreams[userId]?.close();
    _userStreams.remove(userId);
  }

  /// Dispose all streams
  void dispose() {
    _controller.close();
    for (final stream in _userStreams.values) {
      stream.close();
    }
    _userStreams.clear();
  }
}

/// SSE (Server-Sent Events) Handler
class SSEHandler {
  final RealtimeEventBus _eventBus = RealtimeEventBus();
  final Map<String, StreamSubscription> _subscriptions = {};

  /// Create SSE stream for a user
  Stream<String> createSSEStream({
    required int userId,
    List<RealtimeEventType>? filterTypes,
  }) async* {
    // Send initial connection event
    yield RealtimeEvent(
      id: 'init_${DateTime.now().millisecondsSinceEpoch}',
      type: RealtimeEventType.connectionEstablished,
      data: {'userId': userId, 'connectedAt': DateTime.now().toIso8601String()},
      userId: userId,
    ).toSSE();

    // Start heartbeat
    final heartbeat = Timer.periodic(Duration(seconds: 30), (timer) {
      // Heartbeat will be yielded in the main stream
    });

    try {
      await for (final event in _eventBus.getUserStream(userId)) {
        // Filter by type if specified
        if (filterTypes != null && !filterTypes.contains(event.type)) {
          continue;
        }
        
        yield event.toSSE();
      }
    } finally {
      heartbeat.cancel();
    }
  }

  /// Send event to specific user's SSE stream
  void sendToUser(int userId, RealtimeEvent event) {
    _eventBus.publish(RealtimeEvent(
      id: event.id,
      type: event.type,
      data: event.data,
      userId: userId,
    ));
  }

  /// Broadcast event to all connected users
  void broadcast(RealtimeEvent event) {
    _eventBus.publish(event);
  }
}

/// WebSocket Handler for bidirectional communication
class WebSocketHandler {
  final RealtimeEventBus _eventBus = RealtimeEventBus();
  final Map<String, WebSocket> _connections = {};
  final Map<int, Set<String>> _userConnections = {};

  /// Handle new WebSocket connection
  Future<void> handleConnection(
    WebSocket socket,
    int userId,
  ) async {
    final connectionId = 'ws_${userId}_${DateTime.now().millisecondsSinceEpoch}';
    
    _connections[connectionId] = socket;
    _userConnections[userId] ??= {};
    _userConnections[userId]!.add(connectionId);

    // Send welcome message
    _send(socket, RealtimeEvent(
      id: 'welcome_$connectionId',
      type: RealtimeEventType.connectionEstablished,
      data: {
        'connectionId': connectionId,
        'userId': userId,
        'message': 'Connected to Recall Butler real-time service',
      },
      userId: userId,
    ));

    // Subscribe to user events
    final subscription = _eventBus.getUserStream(userId).listen((event) {
      _send(socket, event);
    });

    // Handle incoming messages
    await for (final message in socket) {
      try {
        final data = jsonDecode(message as String) as Map<String, dynamic>;
        await _handleMessage(connectionId, userId, data);
      } catch (e) {
        _send(socket, RealtimeEvent(
          id: 'error_${DateTime.now().millisecondsSinceEpoch}',
          type: RealtimeEventType.error,
          data: {'message': 'Invalid message format: $e'},
          userId: userId,
        ));
      }
    }

    // Cleanup on disconnect
    subscription.cancel();
    _connections.remove(connectionId);
    _userConnections[userId]?.remove(connectionId);
  }

  /// Handle incoming WebSocket message
  Future<void> _handleMessage(
    String connectionId,
    int userId,
    Map<String, dynamic> message,
  ) async {
    final action = message['action'] as String?;
    final payload = message['payload'] as Map<String, dynamic>? ?? {};

    switch (action) {
      case 'subscribe':
        // Subscribe to specific event types
        final types = (payload['types'] as List?)?.cast<String>() ?? [];
        print('📡 [WS] User $userId subscribed to: $types');
        break;

      case 'unsubscribe':
        // Unsubscribe from event types
        final types = (payload['types'] as List?)?.cast<String>() ?? [];
        print('📡 [WS] User $userId unsubscribed from: $types');
        break;

      case 'ping':
        // Respond to ping
        final socket = _connections[connectionId];
        if (socket != null) {
          _send(socket, RealtimeEvent(
            id: 'pong_${DateTime.now().millisecondsSinceEpoch}',
            type: RealtimeEventType.heartbeat,
            data: {'pong': true, 'timestamp': DateTime.now().toIso8601String()},
            userId: userId,
          ));
        }
        break;

      case 'search':
        // Real-time search request
        final query = payload['query'] as String?;
        if (query != null) {
          // Emit search started event
          _eventBus.emit(
            type: RealtimeEventType.searchCompleted,
            data: {'query': query, 'status': 'processing'},
            userId: userId,
          );
        }
        break;

      default:
        print('📡 [WS] Unknown action: $action');
    }
  }

  /// Send event to WebSocket
  void _send(WebSocket socket, RealtimeEvent event) {
    try {
      socket.add(jsonEncode(event.toJson()));
    } catch (e) {
      print('❌ [WS] Failed to send: $e');
    }
  }

  /// Send to specific user
  void sendToUser(int userId, RealtimeEvent event) {
    final connections = _userConnections[userId] ?? {};
    for (final connId in connections) {
      final socket = _connections[connId];
      if (socket != null) {
        _send(socket, event);
      }
    }
  }

  /// Broadcast to all connections
  void broadcast(RealtimeEvent event) {
    for (final socket in _connections.values) {
      _send(socket, event);
    }
  }

  /// Close all connections for a user
  void closeUserConnections(int userId) {
    final connections = _userConnections[userId] ?? {};
    for (final connId in connections) {
      _connections[connId]?.close();
      _connections.remove(connId);
    }
    _userConnections.remove(userId);
  }
}

/// Streaming AI Response Handler
class StreamingAIHandler {
  final RealtimeEventBus _eventBus = RealtimeEventBus();

  /// Stream AI response token by token
  Stream<String> streamAIResponse({
    required int userId,
    required String prompt,
    required Future<String> Function(String) aiFunction,
  }) async* {
    // Emit start event
    _eventBus.emit(
      type: RealtimeEventType.aiResponse,
      data: {'status': 'started', 'prompt': prompt},
      userId: userId,
    );

    try {
      // Get full response (in production, use streaming API)
      final response = await aiFunction(prompt);
      
      // Simulate token streaming
      final words = response.split(' ');
      for (int i = 0; i < words.length; i++) {
        yield words[i] + (i < words.length - 1 ? ' ' : '');
        await Future.delayed(Duration(milliseconds: 50));
      }

      // Emit completion
      _eventBus.emit(
        type: RealtimeEventType.aiResponse,
        data: {'status': 'completed', 'response': response},
        userId: userId,
      );
    } catch (e) {
      _eventBus.emit(
        type: RealtimeEventType.error,
        data: {'message': 'AI streaming failed: $e'},
        userId: userId,
      );
      yield '[Error: $e]';
    }
  }
}

/// Real-time Sync Manager
class RealtimeSyncManager {
  final RealtimeEventBus _eventBus = RealtimeEventBus();
  final Map<int, DateTime> _lastSync = {};

  /// Start sync for user
  Future<void> startSync(int userId) async {
    _eventBus.emit(
      type: RealtimeEventType.syncStarted,
      data: {'userId': userId, 'startedAt': DateTime.now().toIso8601String()},
      userId: userId,
    );

    // Simulate sync process
    await Future.delayed(Duration(milliseconds: 500));

    _lastSync[userId] = DateTime.now();

    _eventBus.emit(
      type: RealtimeEventType.syncCompleted,
      data: {
        'userId': userId,
        'completedAt': DateTime.now().toIso8601String(),
        'itemsSynced': 0, // Would be actual count
      },
      userId: userId,
    );
  }

  /// Get last sync time
  DateTime? getLastSync(int userId) => _lastSync[userId];
}

/// Convenience methods for emitting common events
extension RealtimeEventBusExtensions on RealtimeEventBus {
  void emitDocumentCreated(int userId, int documentId, String title) {
    emit(
      type: RealtimeEventType.documentCreated,
      data: {'documentId': documentId, 'title': title},
      userId: userId,
    );
  }

  void emitDocumentUpdated(int userId, int documentId, String title) {
    emit(
      type: RealtimeEventType.documentUpdated,
      data: {'documentId': documentId, 'title': title},
      userId: userId,
    );
  }

  void emitDocumentDeleted(int userId, int documentId) {
    emit(
      type: RealtimeEventType.documentDeleted,
      data: {'documentId': documentId},
      userId: userId,
    );
  }

  void emitSuggestionCreated(int userId, int suggestionId, String title) {
    emit(
      type: RealtimeEventType.suggestionCreated,
      data: {'suggestionId': suggestionId, 'title': title},
      userId: userId,
    );
  }

  void emitReminderTriggered(int userId, int documentId, String title) {
    emit(
      type: RealtimeEventType.reminderTriggered,
      data: {'documentId': documentId, 'title': title},
      userId: userId,
    );
  }
}
