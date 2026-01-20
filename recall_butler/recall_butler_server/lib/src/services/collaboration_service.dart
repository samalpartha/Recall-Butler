import 'dart:async';
import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'logger_service.dart';
import 'auth_service.dart';

/// Real-time Collaboration Service
/// Enables live collaboration on workspaces and documents
class CollaborationService {
  static final CollaborationService _instance = CollaborationService._internal();
  factory CollaborationService() => _instance;
  CollaborationService._internal();

  // Workspace subscriptions: workspaceId -> Set of userIds
  final Map<String, Set<int>> _workspaceSubscriptions = {};
  
  // User connections: userId -> StreamController for events
  final Map<int, StreamController<CollaborationEvent>> _userConnections = {};
  
  // Active cursors: workspaceId -> Map of userId -> cursor position
  final Map<String, Map<int, CursorPosition>> _cursors = {};
  
  // Document locks: documentId -> userId who holds the lock
  final Map<int, DocumentLock> _documentLocks = {};
  
  // Presence: userId -> PresenceInfo
  final Map<int, PresenceInfo> _presence = {};

  // Workspaces: workspaceId -> WorkspaceData
  final Map<String, WorkspaceData> _workspaces = {};
  
  /// Create a new workspace
  Future<WorkspaceData> createWorkspace({
    required int ownerId,
    required String name,
    String? description,
    bool isPublic = false,
  }) async {
    final workspaceId = 'ws_${DateTime.now().millisecondsSinceEpoch}';
    
    final workspace = WorkspaceData(
      id: workspaceId,
      name: name,
      description: description,
      ownerId: ownerId,
      isPublic: isPublic,
      members: {ownerId: WorkspaceRole.owner},
      documents: [],
      createdAt: DateTime.now(),
    );
    
    _workspaces[workspaceId] = workspace;
    _workspaceSubscriptions[workspaceId] = {ownerId};
    
    logger.audit(
      action: 'WORKSPACE_CREATED',
      userId: ownerId.toString(),
      resourceType: 'workspace',
      resourceId: workspaceId,
    );
    
    return workspace;
  }

  /// Join a workspace
  Future<bool> joinWorkspace({
    required int userId,
    required String workspaceId,
    String? inviteCode,
  }) async {
    final workspace = _workspaces[workspaceId];
    if (workspace == null) return false;
    
    // Check access
    if (!workspace.isPublic && !workspace.members.containsKey(userId)) {
      // Would verify invite code in production
      return false;
    }
    
    // Add member
    workspace.members[userId] = WorkspaceRole.member;
    _workspaceSubscriptions[workspaceId]?.add(userId);
    
    // Notify other members
    _broadcastToWorkspace(workspaceId, CollaborationEvent(
      type: EventType.memberJoined,
      workspaceId: workspaceId,
      userId: userId,
      data: {'userId': userId},
      timestamp: DateTime.now(),
    ), excludeUser: userId);
    
    logger.audit(
      action: 'WORKSPACE_JOINED',
      userId: userId.toString(),
      resourceType: 'workspace',
      resourceId: workspaceId,
    );
    
    return true;
  }

  /// Leave a workspace
  Future<void> leaveWorkspace({
    required int userId,
    required String workspaceId,
  }) async {
    final workspace = _workspaces[workspaceId];
    if (workspace == null) return;
    
    // Can't leave if owner (must transfer ownership first)
    if (workspace.ownerId == userId) {
      throw Exception('Owner cannot leave workspace. Transfer ownership first.');
    }
    
    workspace.members.remove(userId);
    _workspaceSubscriptions[workspaceId]?.remove(userId);
    
    // Notify other members
    _broadcastToWorkspace(workspaceId, CollaborationEvent(
      type: EventType.memberLeft,
      workspaceId: workspaceId,
      userId: userId,
      data: {'userId': userId},
      timestamp: DateTime.now(),
    ));
  }

  /// Add document to workspace
  Future<void> addDocumentToWorkspace({
    required int userId,
    required String workspaceId,
    required int documentId,
  }) async {
    final workspace = _workspaces[workspaceId];
    if (workspace == null) return;
    
    // Check permission
    if (!_canEdit(workspace, userId)) {
      throw Exception('Insufficient permissions');
    }
    
    workspace.documents.add(documentId);
    
    // Notify members
    _broadcastToWorkspace(workspaceId, CollaborationEvent(
      type: EventType.documentAdded,
      workspaceId: workspaceId,
      userId: userId,
      documentId: documentId,
      data: {'documentId': documentId},
      timestamp: DateTime.now(),
    ));
  }

  /// Subscribe to workspace events
  Stream<CollaborationEvent> subscribeToWorkspace({
    required int userId,
    required String workspaceId,
  }) {
    // Ensure user has a connection
    _userConnections[userId] ??= StreamController<CollaborationEvent>.broadcast();
    
    // Add to workspace subscribers
    _workspaceSubscriptions[workspaceId] ??= {};
    _workspaceSubscriptions[workspaceId]!.add(userId);
    
    // Update presence
    _updatePresence(userId, workspaceId: workspaceId);
    
    return _userConnections[userId]!.stream.where(
      (event) => event.workspaceId == workspaceId,
    );
  }

  /// Update cursor position
  void updateCursor({
    required int userId,
    required String workspaceId,
    required int documentId,
    required int line,
    required int column,
  }) {
    _cursors[workspaceId] ??= {};
    _cursors[workspaceId]![userId] = CursorPosition(
      userId: userId,
      documentId: documentId,
      line: line,
      column: column,
      updatedAt: DateTime.now(),
    );
    
    // Broadcast cursor update
    _broadcastToWorkspace(workspaceId, CollaborationEvent(
      type: EventType.cursorMoved,
      workspaceId: workspaceId,
      userId: userId,
      documentId: documentId,
      data: {
        'line': line,
        'column': column,
      },
      timestamp: DateTime.now(),
    ), excludeUser: userId);
  }

  /// Lock a document for editing
  Future<DocumentLock?> lockDocument({
    required int userId,
    required int documentId,
    Duration timeout = const Duration(minutes: 5),
  }) async {
    final existingLock = _documentLocks[documentId];
    
    // Check if already locked by another user
    if (existingLock != null && 
        existingLock.userId != userId && 
        !existingLock.isExpired) {
      return null; // Lock failed
    }
    
    // Create new lock
    final lock = DocumentLock(
      documentId: documentId,
      userId: userId,
      acquiredAt: DateTime.now(),
      expiresAt: DateTime.now().add(timeout),
    );
    
    _documentLocks[documentId] = lock;
    
    logger.debug('Document locked', context: {
      'documentId': documentId,
      'userId': userId,
    });
    
    return lock;
  }

  /// Release a document lock
  void releaseLock({
    required int userId,
    required int documentId,
  }) {
    final lock = _documentLocks[documentId];
    if (lock != null && lock.userId == userId) {
      _documentLocks.remove(documentId);
    }
  }

  /// Broadcast a document change
  void broadcastDocumentChange({
    required int userId,
    required String workspaceId,
    required int documentId,
    required String changeType,
    required Map<String, dynamic> changeData,
  }) {
    _broadcastToWorkspace(workspaceId, CollaborationEvent(
      type: EventType.documentChanged,
      workspaceId: workspaceId,
      userId: userId,
      documentId: documentId,
      data: {
        'changeType': changeType,
        ...changeData,
      },
      timestamp: DateTime.now(),
    ), excludeUser: userId);
  }

  /// Get workspace members with presence info
  List<MemberPresence> getWorkspaceMembers(String workspaceId) {
    final workspace = _workspaces[workspaceId];
    if (workspace == null) return [];
    
    return workspace.members.entries.map((entry) {
      final presence = _presence[entry.key];
      return MemberPresence(
        userId: entry.key,
        role: entry.value,
        isOnline: presence?.isOnline ?? false,
        lastSeen: presence?.lastSeen,
        currentDocument: _cursors[workspaceId]?[entry.key]?.documentId,
      );
    }).toList();
  }

  /// Update user presence
  void _updatePresence(int userId, {String? workspaceId}) {
    _presence[userId] = PresenceInfo(
      userId: userId,
      isOnline: true,
      lastSeen: DateTime.now(),
      currentWorkspace: workspaceId,
    );
    
    // Broadcast presence update if in a workspace
    if (workspaceId != null) {
      _broadcastToWorkspace(workspaceId, CollaborationEvent(
        type: EventType.presenceChanged,
        workspaceId: workspaceId,
        userId: userId,
        data: {'status': 'online'},
        timestamp: DateTime.now(),
      ), excludeUser: userId);
    }
  }

  /// Disconnect user
  void disconnectUser(int userId) {
    _presence[userId]?.isOnline = false;
    _presence[userId]?.lastSeen = DateTime.now();
    
    // Notify all workspaces user was in
    for (final entry in _workspaceSubscriptions.entries) {
      if (entry.value.contains(userId)) {
        _broadcastToWorkspace(entry.key, CollaborationEvent(
          type: EventType.presenceChanged,
          workspaceId: entry.key,
          userId: userId,
          data: {'status': 'offline'},
          timestamp: DateTime.now(),
        ));
        entry.value.remove(userId);
      }
    }
    
    // Close connection
    _userConnections[userId]?.close();
    _userConnections.remove(userId);
  }

  /// Broadcast event to workspace members
  void _broadcastToWorkspace(
    String workspaceId, 
    CollaborationEvent event, {
    int? excludeUser,
  }) {
    final subscribers = _workspaceSubscriptions[workspaceId] ?? {};
    
    for (final userId in subscribers) {
      if (userId == excludeUser) continue;
      _userConnections[userId]?.add(event);
    }
  }

  /// Check if user can edit in workspace
  bool _canEdit(WorkspaceData workspace, int userId) {
    final role = workspace.members[userId];
    return role == WorkspaceRole.owner || 
           role == WorkspaceRole.admin || 
           role == WorkspaceRole.editor;
  }

  /// Get workspace data
  WorkspaceData? getWorkspace(String workspaceId) => _workspaces[workspaceId];

  /// Get user's workspaces
  List<WorkspaceData> getUserWorkspaces(int userId) {
    return _workspaces.values
        .where((ws) => ws.members.containsKey(userId))
        .toList();
  }
}

/// Workspace roles
enum WorkspaceRole {
  owner,
  admin,
  editor,
  member,
  viewer,
}

/// Collaboration event types
enum EventType {
  memberJoined,
  memberLeft,
  documentAdded,
  documentRemoved,
  documentChanged,
  cursorMoved,
  presenceChanged,
  lockAcquired,
  lockReleased,
  comment,
}

/// Collaboration event
class CollaborationEvent {
  final EventType type;
  final String workspaceId;
  final int userId;
  final int? documentId;
  final Map<String, dynamic> data;
  final DateTime timestamp;

  CollaborationEvent({
    required this.type,
    required this.workspaceId,
    required this.userId,
    this.documentId,
    required this.data,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'type': type.name,
    'workspaceId': workspaceId,
    'userId': userId,
    if (documentId != null) 'documentId': documentId,
    'data': data,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Workspace data
class WorkspaceData {
  final String id;
  final String name;
  final String? description;
  final int ownerId;
  final bool isPublic;
  final Map<int, WorkspaceRole> members;
  final List<int> documents;
  final DateTime createdAt;

  WorkspaceData({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    required this.isPublic,
    required this.members,
    required this.documents,
    required this.createdAt,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'description': description,
    'ownerId': ownerId,
    'isPublic': isPublic,
    'memberCount': members.length,
    'documentCount': documents.length,
    'createdAt': createdAt.toIso8601String(),
  };
}

/// Cursor position for live editing
class CursorPosition {
  final int userId;
  final int documentId;
  final int line;
  final int column;
  final DateTime updatedAt;

  CursorPosition({
    required this.userId,
    required this.documentId,
    required this.line,
    required this.column,
    required this.updatedAt,
  });
}

/// Document lock
class DocumentLock {
  final int documentId;
  final int userId;
  final DateTime acquiredAt;
  final DateTime expiresAt;

  DocumentLock({
    required this.documentId,
    required this.userId,
    required this.acquiredAt,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

/// User presence info
class PresenceInfo {
  final int userId;
  bool isOnline;
  DateTime? lastSeen;
  String? currentWorkspace;

  PresenceInfo({
    required this.userId,
    required this.isOnline,
    this.lastSeen,
    this.currentWorkspace,
  });
}

/// Member presence for UI
class MemberPresence {
  final int userId;
  final WorkspaceRole role;
  final bool isOnline;
  final DateTime? lastSeen;
  final int? currentDocument;

  MemberPresence({
    required this.userId,
    required this.role,
    required this.isOnline,
    this.lastSeen,
    this.currentDocument,
  });

  Map<String, dynamic> toJson() => {
    'userId': userId,
    'role': role.name,
    'isOnline': isOnline,
    'lastSeen': lastSeen?.toIso8601String(),
    'currentDocument': currentDocument,
  };
}
