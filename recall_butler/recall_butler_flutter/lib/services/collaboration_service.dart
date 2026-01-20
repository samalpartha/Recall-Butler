import 'package:flutter/foundation.dart';

/// Workspace model for collaboration
class Workspace {
  final String id;
  final String name;
  final String? description;
  final String ownerId;
  final DateTime createdAt;
  final List<WorkspaceMember> members;
  final List<String> documentIds;
  final WorkspaceSettings settings;
  final String? avatarUrl;

  Workspace({
    required this.id,
    required this.name,
    this.description,
    required this.ownerId,
    required this.createdAt,
    required this.members,
    required this.documentIds,
    required this.settings,
    this.avatarUrl,
  });

  Workspace copyWith({
    String? name,
    String? description,
    List<WorkspaceMember>? members,
    List<String>? documentIds,
    WorkspaceSettings? settings,
  }) {
    return Workspace(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      ownerId: ownerId,
      createdAt: createdAt,
      members: members ?? this.members,
      documentIds: documentIds ?? this.documentIds,
      settings: settings ?? this.settings,
      avatarUrl: avatarUrl,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'description': description,
    'ownerId': ownerId,
    'createdAt': createdAt.toIso8601String(),
    'members': members.map((m) => m.toMap()).toList(),
    'documentIds': documentIds,
    'settings': settings.toMap(),
    'avatarUrl': avatarUrl,
  };

  factory Workspace.fromMap(Map<String, dynamic> map) => Workspace(
    id: map['id'],
    name: map['name'],
    description: map['description'],
    ownerId: map['ownerId'],
    createdAt: DateTime.parse(map['createdAt']),
    members: (map['members'] as List)
        .map((m) => WorkspaceMember.fromMap(m))
        .toList(),
    documentIds: List<String>.from(map['documentIds'] ?? []),
    settings: WorkspaceSettings.fromMap(map['settings'] ?? {}),
    avatarUrl: map['avatarUrl'],
  );
}

/// Workspace member model
class WorkspaceMember {
  final String id;
  final String userId;
  final String name;
  final String email;
  final MemberRole role;
  final DateTime joinedAt;
  final String? avatarUrl;
  final bool isOnline;

  WorkspaceMember({
    required this.id,
    required this.userId,
    required this.name,
    required this.email,
    required this.role,
    required this.joinedAt,
    this.avatarUrl,
    this.isOnline = false,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'userId': userId,
    'name': name,
    'email': email,
    'role': role.name,
    'joinedAt': joinedAt.toIso8601String(),
    'avatarUrl': avatarUrl,
    'isOnline': isOnline,
  };

  factory WorkspaceMember.fromMap(Map<String, dynamic> map) => WorkspaceMember(
    id: map['id'],
    userId: map['userId'],
    name: map['name'],
    email: map['email'],
    role: MemberRole.values.firstWhere(
      (r) => r.name == map['role'],
      orElse: () => MemberRole.viewer,
    ),
    joinedAt: DateTime.parse(map['joinedAt']),
    avatarUrl: map['avatarUrl'],
    isOnline: map['isOnline'] ?? false,
  );
}

enum MemberRole {
  owner,
  admin,
  editor,
  viewer,
}

/// Workspace settings
class WorkspaceSettings {
  final bool isPublic;
  final bool allowInvites;
  final bool allowExport;
  final bool notifyOnChanges;
  final String defaultPermission;

  WorkspaceSettings({
    this.isPublic = false,
    this.allowInvites = true,
    this.allowExport = true,
    this.notifyOnChanges = true,
    this.defaultPermission = 'viewer',
  });

  Map<String, dynamic> toMap() => {
    'isPublic': isPublic,
    'allowInvites': allowInvites,
    'allowExport': allowExport,
    'notifyOnChanges': notifyOnChanges,
    'defaultPermission': defaultPermission,
  };

  factory WorkspaceSettings.fromMap(Map<String, dynamic> map) => WorkspaceSettings(
    isPublic: map['isPublic'] ?? false,
    allowInvites: map['allowInvites'] ?? true,
    allowExport: map['allowExport'] ?? true,
    notifyOnChanges: map['notifyOnChanges'] ?? true,
    defaultPermission: map['defaultPermission'] ?? 'viewer',
  );
}

/// Share invitation model
class ShareInvitation {
  final String id;
  final String workspaceId;
  final String invitedEmail;
  final String invitedBy;
  final MemberRole role;
  final DateTime createdAt;
  final DateTime expiresAt;
  final InvitationStatus status;

  ShareInvitation({
    required this.id,
    required this.workspaceId,
    required this.invitedEmail,
    required this.invitedBy,
    required this.role,
    required this.createdAt,
    required this.expiresAt,
    required this.status,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'workspaceId': workspaceId,
    'invitedEmail': invitedEmail,
    'invitedBy': invitedBy,
    'role': role.name,
    'createdAt': createdAt.toIso8601String(),
    'expiresAt': expiresAt.toIso8601String(),
    'status': status.name,
  };

  factory ShareInvitation.fromMap(Map<String, dynamic> map) => ShareInvitation(
    id: map['id'],
    workspaceId: map['workspaceId'],
    invitedEmail: map['invitedEmail'],
    invitedBy: map['invitedBy'],
    role: MemberRole.values.firstWhere(
      (r) => r.name == map['role'],
      orElse: () => MemberRole.viewer,
    ),
    createdAt: DateTime.parse(map['createdAt']),
    expiresAt: DateTime.parse(map['expiresAt']),
    status: InvitationStatus.values.firstWhere(
      (s) => s.name == map['status'],
      orElse: () => InvitationStatus.pending,
    ),
  );
}

enum InvitationStatus {
  pending,
  accepted,
  declined,
  expired,
}

/// Collaboration service
class CollaborationService {
  static final CollaborationService _instance = CollaborationService._internal();
  factory CollaborationService() => _instance;
  CollaborationService._internal();

  final List<Workspace> _workspaces = [];
  final List<ShareInvitation> _invitations = [];
  String _currentUserId = 'user_1';
  String _currentUserName = 'You';
  String _currentUserEmail = 'you@example.com';

  List<Workspace> get workspaces => List.unmodifiable(_workspaces);
  List<Workspace> get ownedWorkspaces => 
    _workspaces.where((w) => w.ownerId == _currentUserId).toList();
  List<Workspace> get sharedWorkspaces => 
    _workspaces.where((w) => w.ownerId != _currentUserId).toList();
  List<ShareInvitation> get pendingInvitations =>
    _invitations.where((i) => i.status == InvitationStatus.pending).toList();

  /// Initialize with sample data
  void initialize() {
    _workspaces.addAll(_generateSampleWorkspaces());
    debugPrint('👥 Collaboration Service initialized with ${_workspaces.length} workspaces');
  }

  /// Create a new workspace
  Future<Workspace> createWorkspace({
    required String name,
    String? description,
  }) async {
    final workspace = Workspace(
      id: 'ws_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      description: description,
      ownerId: _currentUserId,
      createdAt: DateTime.now(),
      members: [
        WorkspaceMember(
          id: 'mem_${DateTime.now().millisecondsSinceEpoch}',
          userId: _currentUserId,
          name: _currentUserName,
          email: _currentUserEmail,
          role: MemberRole.owner,
          joinedAt: DateTime.now(),
          isOnline: true,
        ),
      ],
      documentIds: [],
      settings: WorkspaceSettings(),
    );

    _workspaces.add(workspace);
    debugPrint('👥 Created workspace: $name');
    return workspace;
  }

  /// Invite a member to workspace
  Future<ShareInvitation> inviteMember({
    required String workspaceId,
    required String email,
    MemberRole role = MemberRole.viewer,
  }) async {
    final invitation = ShareInvitation(
      id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
      workspaceId: workspaceId,
      invitedEmail: email,
      invitedBy: _currentUserId,
      role: role,
      createdAt: DateTime.now(),
      expiresAt: DateTime.now().add(const Duration(days: 7)),
      status: InvitationStatus.pending,
    );

    _invitations.add(invitation);
    debugPrint('📧 Sent invitation to $email for workspace $workspaceId');
    return invitation;
  }

  /// Accept invitation (simulated)
  Future<void> acceptInvitation(String invitationId) async {
    final index = _invitations.indexWhere((i) => i.id == invitationId);
    if (index == -1) return;

    final invitation = _invitations[index];
    
    // Add member to workspace
    final wsIndex = _workspaces.indexWhere((w) => w.id == invitation.workspaceId);
    if (wsIndex != -1) {
      final workspace = _workspaces[wsIndex];
      final newMember = WorkspaceMember(
        id: 'mem_${DateTime.now().millisecondsSinceEpoch}',
        userId: 'user_${DateTime.now().millisecondsSinceEpoch}',
        name: invitation.invitedEmail.split('@')[0],
        email: invitation.invitedEmail,
        role: invitation.role,
        joinedAt: DateTime.now(),
      );
      
      _workspaces[wsIndex] = workspace.copyWith(
        members: [...workspace.members, newMember],
      );
    }

    // Update invitation status
    _invitations[index] = ShareInvitation(
      id: invitation.id,
      workspaceId: invitation.workspaceId,
      invitedEmail: invitation.invitedEmail,
      invitedBy: invitation.invitedBy,
      role: invitation.role,
      createdAt: invitation.createdAt,
      expiresAt: invitation.expiresAt,
      status: InvitationStatus.accepted,
    );

    debugPrint('✅ Invitation accepted: ${invitation.invitedEmail}');
  }

  /// Add document to workspace
  Future<void> addDocumentToWorkspace({
    required String workspaceId,
    required String documentId,
  }) async {
    final index = _workspaces.indexWhere((w) => w.id == workspaceId);
    if (index == -1) return;

    final workspace = _workspaces[index];
    if (!workspace.documentIds.contains(documentId)) {
      _workspaces[index] = workspace.copyWith(
        documentIds: [...workspace.documentIds, documentId],
      );
      debugPrint('📄 Added document $documentId to workspace ${workspace.name}');
    }
  }

  /// Remove document from workspace
  Future<void> removeDocumentFromWorkspace({
    required String workspaceId,
    required String documentId,
  }) async {
    final index = _workspaces.indexWhere((w) => w.id == workspaceId);
    if (index == -1) return;

    final workspace = _workspaces[index];
    _workspaces[index] = workspace.copyWith(
      documentIds: workspace.documentIds.where((id) => id != documentId).toList(),
    );
    debugPrint('📄 Removed document $documentId from workspace ${workspace.name}');
  }

  /// Update member role
  Future<void> updateMemberRole({
    required String workspaceId,
    required String memberId,
    required MemberRole newRole,
  }) async {
    final wsIndex = _workspaces.indexWhere((w) => w.id == workspaceId);
    if (wsIndex == -1) return;

    final workspace = _workspaces[wsIndex];
    final members = workspace.members.map((m) {
      if (m.id == memberId) {
        return WorkspaceMember(
          id: m.id,
          userId: m.userId,
          name: m.name,
          email: m.email,
          role: newRole,
          joinedAt: m.joinedAt,
          avatarUrl: m.avatarUrl,
          isOnline: m.isOnline,
        );
      }
      return m;
    }).toList();

    _workspaces[wsIndex] = workspace.copyWith(members: members);
    debugPrint('👤 Updated role for member $memberId to ${newRole.name}');
  }

  /// Remove member from workspace
  Future<void> removeMember({
    required String workspaceId,
    required String memberId,
  }) async {
    final wsIndex = _workspaces.indexWhere((w) => w.id == workspaceId);
    if (wsIndex == -1) return;

    final workspace = _workspaces[wsIndex];
    _workspaces[wsIndex] = workspace.copyWith(
      members: workspace.members.where((m) => m.id != memberId).toList(),
    );
    debugPrint('👤 Removed member $memberId from workspace');
  }

  /// Leave workspace
  Future<void> leaveWorkspace(String workspaceId) async {
    final wsIndex = _workspaces.indexWhere((w) => w.id == workspaceId);
    if (wsIndex == -1) return;

    final workspace = _workspaces[wsIndex];
    if (workspace.ownerId == _currentUserId) {
      // Can't leave owned workspace, must transfer or delete
      throw Exception('Cannot leave workspace you own. Transfer ownership first.');
    }

    _workspaces[wsIndex] = workspace.copyWith(
      members: workspace.members.where((m) => m.userId != _currentUserId).toList(),
    );
    _workspaces.removeAt(wsIndex);
    debugPrint('👋 Left workspace: ${workspace.name}');
  }

  /// Delete workspace
  Future<void> deleteWorkspace(String workspaceId) async {
    final workspace = _workspaces.firstWhere((w) => w.id == workspaceId);
    if (workspace.ownerId != _currentUserId) {
      throw Exception('Only the owner can delete a workspace');
    }

    _workspaces.removeWhere((w) => w.id == workspaceId);
    debugPrint('🗑️ Deleted workspace: ${workspace.name}');
  }

  /// Generate share link
  String generateShareLink(String workspaceId) {
    return 'https://recallbutler.app/join/$workspaceId';
  }

  /// Get workspace by ID
  Workspace? getWorkspace(String workspaceId) {
    try {
      return _workspaces.firstWhere((w) => w.id == workspaceId);
    } catch (_) {
      return null;
    }
  }

  /// Check user permission
  bool hasPermission(String workspaceId, MemberRole requiredRole) {
    final workspace = getWorkspace(workspaceId);
    if (workspace == null) return false;

    final member = workspace.members.firstWhere(
      (m) => m.userId == _currentUserId,
      orElse: () => WorkspaceMember(
        id: '',
        userId: '',
        name: '',
        email: '',
        role: MemberRole.viewer,
        joinedAt: DateTime.now(),
      ),
    );

    final roleHierarchy = [MemberRole.viewer, MemberRole.editor, MemberRole.admin, MemberRole.owner];
    return roleHierarchy.indexOf(member.role) >= roleHierarchy.indexOf(requiredRole);
  }

  /// Generate sample workspaces
  List<Workspace> _generateSampleWorkspaces() {
    return [
      Workspace(
        id: 'ws_personal',
        name: 'Personal',
        description: 'Your private workspace',
        ownerId: _currentUserId,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        members: [
          WorkspaceMember(
            id: 'mem_1',
            userId: _currentUserId,
            name: _currentUserName,
            email: _currentUserEmail,
            role: MemberRole.owner,
            joinedAt: DateTime.now().subtract(const Duration(days: 30)),
            isOnline: true,
          ),
        ],
        documentIds: ['1', '2', '3'],
        settings: WorkspaceSettings(),
      ),
      Workspace(
        id: 'ws_team',
        name: 'Team Project',
        description: 'Shared workspace for the hackathon team',
        ownerId: _currentUserId,
        createdAt: DateTime.now().subtract(const Duration(days: 7)),
        members: [
          WorkspaceMember(
            id: 'mem_2',
            userId: _currentUserId,
            name: _currentUserName,
            email: _currentUserEmail,
            role: MemberRole.owner,
            joinedAt: DateTime.now().subtract(const Duration(days: 7)),
            isOnline: true,
          ),
          WorkspaceMember(
            id: 'mem_3',
            userId: 'user_alice',
            name: 'Alice',
            email: 'alice@example.com',
            role: MemberRole.admin,
            joinedAt: DateTime.now().subtract(const Duration(days: 5)),
            isOnline: true,
          ),
          WorkspaceMember(
            id: 'mem_4',
            userId: 'user_bob',
            name: 'Bob',
            email: 'bob@example.com',
            role: MemberRole.editor,
            joinedAt: DateTime.now().subtract(const Duration(days: 3)),
            isOnline: false,
          ),
        ],
        documentIds: ['4', '5'],
        settings: WorkspaceSettings(allowInvites: true),
      ),
      Workspace(
        id: 'ws_shared',
        name: 'Research Notes',
        description: 'Shared research from the team',
        ownerId: 'user_alice',
        createdAt: DateTime.now().subtract(const Duration(days: 14)),
        members: [
          WorkspaceMember(
            id: 'mem_5',
            userId: 'user_alice',
            name: 'Alice',
            email: 'alice@example.com',
            role: MemberRole.owner,
            joinedAt: DateTime.now().subtract(const Duration(days: 14)),
            isOnline: true,
          ),
          WorkspaceMember(
            id: 'mem_6',
            userId: _currentUserId,
            name: _currentUserName,
            email: _currentUserEmail,
            role: MemberRole.viewer,
            joinedAt: DateTime.now().subtract(const Duration(days: 10)),
            isOnline: true,
          ),
        ],
        documentIds: ['6', '7', '8'],
        settings: WorkspaceSettings(),
      ),
    ];
  }
}
