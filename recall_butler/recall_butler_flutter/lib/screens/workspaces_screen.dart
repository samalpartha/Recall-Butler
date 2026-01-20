import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../services/collaboration_service.dart';

/// Provider for collaboration service
final collaborationServiceProvider = Provider<CollaborationService>((ref) {
  final service = CollaborationService();
  service.initialize();
  return service;
});

/// Workspaces Screen
class WorkspacesScreen extends ConsumerStatefulWidget {
  const WorkspacesScreen({super.key});

  @override
  ConsumerState<WorkspacesScreen> createState() => _WorkspacesScreenState();
}

class _WorkspacesScreenState extends ConsumerState<WorkspacesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collaboration = ref.watch(collaborationServiceProvider);
    final ownedWorkspaces = collaboration.ownedWorkspaces;
    final sharedWorkspaces = collaboration.sharedWorkspaces;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(LucideIcons.users, color: AppTheme.accentGold, size: 24),
            const SizedBox(width: 12),
            const Text('Workspaces'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentGold,
          labelColor: AppTheme.accentGold,
          unselectedLabelColor: AppTheme.textMutedDark,
          tabs: [
            Tab(text: 'My Workspaces (${ownedWorkspaces.length})'),
            Tab(text: 'Shared (${sharedWorkspaces.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildWorkspacesList(ownedWorkspaces, isOwned: true),
          _buildWorkspacesList(sharedWorkspaces, isOwned: false),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'workspace_fab',
        onPressed: () => _showCreateWorkspaceSheet(context),
        icon: const Icon(LucideIcons.plus),
        label: const Text('New Workspace'),
        backgroundColor: AppTheme.accentGold,
        foregroundColor: AppTheme.primaryDark,
      ),
    );
  }

  Widget _buildWorkspacesList(List<Workspace> workspaces, {required bool isOwned}) {
    if (workspaces.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isOwned ? LucideIcons.folderPlus : LucideIcons.share2,
              size: 64,
              color: AppTheme.textMutedDark,
            ),
            const SizedBox(height: 16),
            Text(
              isOwned ? 'No workspaces yet' : 'No shared workspaces',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              isOwned
                  ? 'Create a workspace to organize and share your memories'
                  : 'Workspaces shared with you will appear here',
              style: TextStyle(color: AppTheme.textSecondaryDark),
              textAlign: TextAlign.center,
            ),
          ],
        ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: workspaces.length,
      itemBuilder: (context, index) {
        return _WorkspaceCard(
          workspace: workspaces[index],
          isOwned: isOwned,
          onTap: () => _openWorkspace(workspaces[index]),
          delay: index * 100,
        );
      },
    );
  }

  void _openWorkspace(Workspace workspace) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => _WorkspaceDetailScreen(workspace: workspace),
      ),
    );
  }

  void _showCreateWorkspaceSheet(BuildContext context) {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Create Workspace',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 20),
            TextField(
              controller: nameController,
              decoration: const InputDecoration(
                labelText: 'Workspace Name',
                hintText: 'e.g., Team Project',
              ),
              autofocus: true,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What is this workspace for?',
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (nameController.text.isNotEmpty) {
                    await ref.read(collaborationServiceProvider).createWorkspace(
                      name: nameController.text,
                      description: descController.text.isEmpty ? null : descController.text,
                    );
                    if (mounted) {
                      Navigator.pop(context);
                      setState(() {});
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Workspace "${nameController.text}" created!'),
                          backgroundColor: AppTheme.statusReady,
                        ),
                      );
                    }
                  }
                },
                child: const Text('Create Workspace'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkspaceCard extends StatelessWidget {
  final Workspace workspace;
  final bool isOwned;
  final VoidCallback onTap;
  final int delay;

  const _WorkspaceCard({
    required this.workspace,
    required this.isOwned,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final onlineMembers = workspace.members.where((m) => m.isOnline).length;
    final dateFormat = DateFormat('MMM d, yyyy');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isOwned 
            ? AppTheme.accentGold.withOpacity(0.3)
            : AppTheme.accentTeal.withOpacity(0.3),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isOwned
                            ? [AppTheme.accentGold, AppTheme.accentCopper]
                            : [AppTheme.accentTeal, Colors.teal],
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          workspace.name.substring(0, 1).toUpperCase(),
                          style: TextStyle(
                            color: AppTheme.primaryDark,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            workspace.name,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          if (workspace.description != null)
                            Text(
                              workspace.description!,
                              style: TextStyle(
                                color: AppTheme.textMutedDark,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      LucideIcons.chevronRight,
                      color: AppTheme.textMutedDark,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    // Members avatars
                    SizedBox(
                      width: 60,
                      height: 24,
                      child: Stack(
                        children: [
                          ...workspace.members.take(3).toList().asMap().entries.map((entry) {
                            return Positioned(
                              left: entry.key * 16.0,
                              child: Container(
                                width: 24,
                                height: 24,
                                decoration: BoxDecoration(
                                  color: _getMemberColor(entry.key),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: AppTheme.cardDark,
                                    width: 2,
                                  ),
                                ),
                                child: Center(
                                  child: Text(
                                    entry.value.name.substring(0, 1),
                                    style: TextStyle(
                                      color: AppTheme.primaryDark,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    Text(
                      '${workspace.members.length} members',
                      style: TextStyle(
                        color: AppTheme.textMutedDark,
                        fontSize: 12,
                      ),
                    ),
                    if (onlineMembers > 0) ...[
                      const SizedBox(width: 8),
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: AppTheme.statusReady,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '$onlineMembers online',
                        style: TextStyle(
                          color: AppTheme.statusReady,
                          fontSize: 11,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Icon(
                      LucideIcons.fileText,
                      size: 14,
                      color: AppTheme.textMutedDark,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${workspace.documentIds.length} docs',
                      style: TextStyle(
                        color: AppTheme.textMutedDark,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(begin: 0.05);
  }

  Color _getMemberColor(int index) {
    final colors = [
      AppTheme.accentGold,
      AppTheme.accentTeal,
      AppTheme.accentCopper,
      Colors.purple,
      Colors.pink,
    ];
    return colors[index % colors.length];
  }
}

/// Workspace Detail Screen
class _WorkspaceDetailScreen extends ConsumerStatefulWidget {
  final Workspace workspace;

  const _WorkspaceDetailScreen({required this.workspace});

  @override
  ConsumerState<_WorkspaceDetailScreen> createState() => _WorkspaceDetailScreenState();
}

class _WorkspaceDetailScreenState extends ConsumerState<_WorkspaceDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final collaboration = ref.watch(collaborationServiceProvider);
    final workspace = collaboration.getWorkspace(widget.workspace.id) ?? widget.workspace;
    final isOwner = workspace.ownerId == 'user_1';

    return Scaffold(
      appBar: AppBar(
        title: Text(workspace.name),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.share2),
            onPressed: () => _showShareSheet(context, workspace),
          ),
          if (isOwner)
            IconButton(
              icon: const Icon(LucideIcons.settings),
              onPressed: () => _showSettingsSheet(context, workspace),
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentGold.withOpacity(0.15),
                    AppTheme.accentTeal.withOpacity(0.15),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [AppTheme.accentGold, AppTheme.accentCopper],
                      ),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        workspace.name.substring(0, 1).toUpperCase(),
                        style: TextStyle(
                          color: AppTheme.primaryDark,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          workspace.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        if (workspace.description != null)
                          Text(
                            workspace.description!,
                            style: TextStyle(color: AppTheme.textSecondaryDark),
                          ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            _StatBadge(
                              icon: LucideIcons.users,
                              value: '${workspace.members.length}',
                              label: 'members',
                            ),
                            const SizedBox(width: 12),
                            _StatBadge(
                              icon: LucideIcons.fileText,
                              value: '${workspace.documentIds.length}',
                              label: 'docs',
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn().slideY(begin: -0.1),
            const SizedBox(height: 24),

            // Members section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Members',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                if (isOwner)
                  TextButton.icon(
                    onPressed: () => _showInviteSheet(context, workspace),
                    icon: const Icon(LucideIcons.userPlus, size: 16),
                    label: const Text('Invite'),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            ...workspace.members.asMap().entries.map((entry) {
              return _MemberTile(
                member: entry.value,
                isOwner: isOwner,
                canEdit: isOwner && entry.value.role != MemberRole.owner,
                onRoleChange: (role) => _updateMemberRole(entry.value, role),
                onRemove: () => _removeMember(entry.value),
                delay: entry.key * 100,
              );
            }),
            const SizedBox(height: 24),

            // Quick actions
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ActionChip(
                  icon: LucideIcons.link,
                  label: 'Copy Link',
                  onTap: () => _copyShareLink(workspace),
                ),
                _ActionChip(
                  icon: LucideIcons.download,
                  label: 'Export',
                  onTap: () {},
                ),
                if (!isOwner)
                  _ActionChip(
                    icon: LucideIcons.logOut,
                    label: 'Leave',
                    onTap: () => _leaveWorkspace(workspace),
                    isDestructive: true,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showShareSheet(BuildContext context, Workspace workspace) {
    final link = ref.read(collaborationServiceProvider).generateShareLink(workspace.id);
    
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Share Workspace',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.cardDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      link,
                      style: TextStyle(
                        color: AppTheme.textSecondaryDark,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(LucideIcons.copy, size: 18),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: link));
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Link copied!')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _showInviteSheet(context, workspace),
                icon: const Icon(LucideIcons.mail),
                label: const Text('Invite by Email'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showInviteSheet(BuildContext context, Workspace workspace) {
    final emailController = TextEditingController();
    MemberRole selectedRole = MemberRole.viewer;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Invite Member',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: emailController,
                decoration: const InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'colleague@example.com',
                ),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<MemberRole>(
                value: selectedRole,
                decoration: const InputDecoration(labelText: 'Role'),
                items: [MemberRole.viewer, MemberRole.editor, MemberRole.admin]
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(_getRoleLabel(role)),
                        ))
                    .toList(),
                onChanged: (role) {
                  if (role != null) setModalState(() => selectedRole = role);
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (emailController.text.isNotEmpty) {
                      await ref.read(collaborationServiceProvider).inviteMember(
                        workspaceId: workspace.id,
                        email: emailController.text,
                        role: selectedRole,
                      );
                      if (mounted) {
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Invitation sent to ${emailController.text}'),
                            backgroundColor: AppTheme.statusReady,
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Send Invitation'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, Workspace workspace) {
    // Settings implementation
  }

  void _updateMemberRole(WorkspaceMember member, MemberRole role) async {
    await ref.read(collaborationServiceProvider).updateMemberRole(
      workspaceId: widget.workspace.id,
      memberId: member.id,
      newRole: role,
    );
    setState(() {});
  }

  void _removeMember(WorkspaceMember member) async {
    await ref.read(collaborationServiceProvider).removeMember(
      workspaceId: widget.workspace.id,
      memberId: member.id,
    );
    setState(() {});
  }

  void _copyShareLink(Workspace workspace) {
    final link = ref.read(collaborationServiceProvider).generateShareLink(workspace.id);
    Clipboard.setData(ClipboardData(text: link));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share link copied!')),
    );
  }

  void _leaveWorkspace(Workspace workspace) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave Workspace?'),
        content: Text('Are you sure you want to leave "${workspace.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.statusFailed),
            child: const Text('Leave'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(collaborationServiceProvider).leaveWorkspace(workspace.id);
      if (mounted) Navigator.pop(context);
    }
  }

  String _getRoleLabel(MemberRole role) {
    switch (role) {
      case MemberRole.owner:
        return '👑 Owner';
      case MemberRole.admin:
        return '⚙️ Admin';
      case MemberRole.editor:
        return '✏️ Editor';
      case MemberRole.viewer:
        return '👁️ Viewer';
    }
  }
}

class _StatBadge extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;

  const _StatBadge({
    required this.icon,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppTheme.textMutedDark),
          const SizedBox(width: 4),
          Text(
            '$value $label',
            style: TextStyle(
              color: AppTheme.textSecondaryDark,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _MemberTile extends StatelessWidget {
  final WorkspaceMember member;
  final bool isOwner;
  final bool canEdit;
  final Function(MemberRole) onRoleChange;
  final VoidCallback onRemove;
  final int delay;

  const _MemberTile({
    required this.member,
    required this.isOwner,
    required this.canEdit,
    required this.onRoleChange,
    required this.onRemove,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Stack(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    member.name.substring(0, 1).toUpperCase(),
                    style: TextStyle(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (member.isOnline)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.statusReady,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppTheme.cardDark, width: 2),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.name,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Text(
                  member.email,
                  style: TextStyle(
                    color: AppTheme.textMutedDark,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getRoleColor(member.role).withOpacity(0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              member.role.name.toUpperCase(),
              style: TextStyle(
                color: _getRoleColor(member.role),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          if (canEdit) ...[
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Icon(LucideIcons.moreVertical, size: 18, color: AppTheme.textMutedDark),
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'role', child: Text('Change Role')),
                const PopupMenuItem(value: 'remove', child: Text('Remove')),
              ],
              onSelected: (value) {
                if (value == 'remove') onRemove();
              },
            ),
          ],
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(begin: 0.05);
  }

  Color _getRoleColor(MemberRole role) {
    switch (role) {
      case MemberRole.owner:
        return AppTheme.accentGold;
      case MemberRole.admin:
        return AppTheme.accentCopper;
      case MemberRole.editor:
        return AppTheme.accentTeal;
      case MemberRole.viewer:
        return AppTheme.textMutedDark;
    }
  }
}

class _ActionChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(
        icon,
        size: 16,
        color: isDestructive ? AppTheme.statusFailed : AppTheme.accentGold,
      ),
      label: Text(
        label,
        style: TextStyle(
          color: isDestructive ? AppTheme.statusFailed : AppTheme.textPrimaryDark,
        ),
      ),
      backgroundColor: AppTheme.cardDark,
      side: BorderSide(
        color: isDestructive 
          ? AppTheme.statusFailed.withOpacity(0.3)
          : AppTheme.cardDark,
      ),
      onPressed: onTap,
    );
  }
}
