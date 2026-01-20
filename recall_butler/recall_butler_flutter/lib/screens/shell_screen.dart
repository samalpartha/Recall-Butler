import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../providers/suggestions_provider.dart';
import '../providers/connectivity_provider.dart';
import '../widgets/offline_indicator.dart';
import 'ingest_screen.dart';
import 'search_screen.dart';
import 'activity_screen.dart';
import 'chat_screen.dart';
import 'voice_capture_screen.dart';
import 'camera_capture_screen.dart';
import 'mood_checkin_screen.dart';
import 'accessibility_screen.dart';
import 'help_screen.dart';
import 'web5_profile_screen.dart';
import 'analytics_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'knowledge_graph_screen.dart';
import 'knowledge_graph_viz_screen.dart';
import 'calendar_screen.dart';
import 'smart_reminders_screen.dart';
import 'workspaces_screen.dart';
import 'ai_agent_screen.dart';
import 'login_screen.dart';

/// Main shell with bottom navigation and quick actions
class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _currentIndex = 0;
  bool _showQuickActions = false;
  
  final List<Widget> _screens = const [
    IngestScreen(),
    SearchScreen(),
    ActivityScreen(),
  ];

  void _toggleQuickActions() {
    setState(() => _showQuickActions = !_showQuickActions);
  }

  void _openChat() {
    setState(() => _showQuickActions = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatScreen()),
    );
  }

  void _openVoice() {
    setState(() => _showQuickActions = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VoiceCaptureScreen()),
    );
  }

  void _openCamera() {
    setState(() => _showQuickActions = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraCaptureScreen()),
    );
  }

  void _openMoodCheckin() {
    setState(() => _showQuickActions = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const MoodCheckinScreen()),
    );
  }

  void _openAccessibility() {
    setState(() => _showQuickActions = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AccessibilityScreen()),
    );
  }

  void _openHelp() {
    setState(() => _showQuickActions = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const HelpScreen()),
    );
  }

  void _openWeb5Profile() {
    setState(() => _showQuickActions = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const Web5ProfileScreen()),
    );
  }

  void _openAnalytics() {
    setState(() => _showQuickActions = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnalyticsDashboardScreen()),
    );
  }

  void _openAiAgent() {
    setState(() => _showQuickActions = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AiAgentScreen()),
    );
  }

  void _openKnowledgeGraph() {
    setState(() => _showQuickActions = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const KnowledgeGraphVizScreen()),
    );
  }

  void _openCalendar() {
    setState(() => _showQuickActions = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CalendarScreen()),
    );
  }

  void _openSmartReminders() {
    setState(() => _showQuickActions = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const SmartRemindersScreen()),
    );
  }

  void _openWorkspaces() {
    setState(() => _showQuickActions = false);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const WorkspacesScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = ref.watch(pendingSuggestionsCountProvider);
    final isOnline = ref.watch(isOnlineProvider);
    
    return Scaffold(
      body: Stack(
        children: [
          // Main content with offline banner space
          Column(
            children: [
              // Offline banner
              const OfflineBanner(),
              
              // Main screen content
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _screens[_currentIndex],
                ),
              ),
            ],
          ),

          // Quick actions overlay
          if (_showQuickActions) ...[
            // Backdrop
            GestureDetector(
              onTap: _toggleQuickActions,
              child: Container(
                color: Colors.black54,
              ).animate().fadeIn(duration: 200.ms),
            ),

            // Quick action buttons - scrollable container
            Positioned(
              bottom: 100,
              right: 20,
              top: 80, // Constrain from top to make room
              child: SingleChildScrollView(
                reverse: true, // Start from bottom
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _QuickActionButton(
                      icon: LucideIcons.bot,
                      label: 'AI Agent',
                      color: Colors.deepPurple,
                      onTap: _openAiAgent,
                    ).animate()
                      .fadeIn(delay: 25.ms)
                      .slideX(begin: 0.3),
                    const SizedBox(height: 12),
                    _QuickActionButton(
                      icon: LucideIcons.messageCircle,
                      label: 'Chat with Butler',
                      color: AppTheme.accentGold,
                      onTap: _openChat,
                    ).animate()
                      .fadeIn(delay: 50.ms)
                      .slideX(begin: 0.3),
                    const SizedBox(height: 12),
                    _QuickActionButton(
                      icon: LucideIcons.mic,
                      label: 'Voice Note',
                      color: AppTheme.statusProcessing,
                      onTap: _openVoice,
                    ).animate()
                      .fadeIn(delay: 100.ms)
                      .slideX(begin: 0.3),
                    const SizedBox(height: 12),
                    _QuickActionButton(
                      icon: LucideIcons.camera,
                      label: 'Scan Document',
                      color: AppTheme.accentCopper,
                      onTap: _openCamera,
                    ).animate()
                      .fadeIn(delay: 150.ms)
                      .slideX(begin: 0.3),
                    const SizedBox(height: 12),
                    _QuickActionButton(
                      icon: LucideIcons.heart,
                      label: 'Mood Check-in',
                      color: Colors.pink,
                      onTap: _openMoodCheckin,
                    ).animate()
                      .fadeIn(delay: 200.ms)
                      .slideX(begin: 0.3),
                  const SizedBox(height: 12),
                  _QuickActionButton(
                    icon: LucideIcons.sparkles,
                    label: 'Personalize',
                    color: Colors.deepPurple,
                    onTap: _openAccessibility,
                  ).animate()
                    .fadeIn(delay: 250.ms)
                    .slideX(begin: 0.3),
                  const SizedBox(height: 12),
                  _QuickActionButton(
                    icon: LucideIcons.helpCircle,
                    label: 'Help & Guide',
                    color: AppTheme.statusReady,
                    onTap: _openHelp,
                  ).animate()
                    .fadeIn(delay: 300.ms)
                    .slideX(begin: 0.3),
                  const SizedBox(height: 12),
                  _QuickActionButton(
                    icon: LucideIcons.barChart3,
                    label: 'Analytics',
                    color: Colors.orange,
                    onTap: _openAnalytics,
                  ).animate()
                    .fadeIn(delay: 350.ms)
                    .slideX(begin: 0.3),
                  const SizedBox(height: 12),
                  _QuickActionButton(
                    icon: LucideIcons.network,
                    label: 'Knowledge Graph',
                    color: AppTheme.accentTeal,
                    onTap: _openKnowledgeGraph,
                  ).animate()
                    .fadeIn(delay: 375.ms)
                    .slideX(begin: 0.3),
                  const SizedBox(height: 12),
                  _QuickActionButton(
                    icon: LucideIcons.calendar,
                    label: 'Calendar',
                    color: Colors.indigo,
                    onTap: _openCalendar,
                  ).animate()
                    .fadeIn(delay: 388.ms)
                    .slideX(begin: 0.3),
                  const SizedBox(height: 12),
                  _QuickActionButton(
                    icon: LucideIcons.bellRing,
                    label: 'Smart Reminders',
                    color: Colors.amber,
                    onTap: _openSmartReminders,
                  ).animate()
                    .fadeIn(delay: 400.ms)
                    .slideX(begin: 0.3),
                  const SizedBox(height: 12),
                  _QuickActionButton(
                    icon: LucideIcons.users,
                    label: 'Workspaces',
                    color: Colors.cyan,
                    onTap: _openWorkspaces,
                  ).animate()
                    .fadeIn(delay: 412.ms)
                    .slideX(begin: 0.3),
                  const SizedBox(height: 12),
                  _QuickActionButton(
                    icon: LucideIcons.fingerprint,
                    label: 'Web5 Identity',
                    color: Colors.blue,
                    onTap: _openWeb5Profile,
                  ).animate()
                    .fadeIn(delay: 425.ms)
                    .slideX(begin: 0.3),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),

      // Floating Action Button
      floatingActionButton: FloatingActionButton(
        heroTag: 'shell_fab', // Unique hero tag to avoid conflicts
        onPressed: _toggleQuickActions,
        backgroundColor: _showQuickActions ? AppTheme.textMutedDark : AppTheme.accentGold,
        child: AnimatedRotation(
          turns: _showQuickActions ? 0.125 : 0,
          duration: const Duration(milliseconds: 200),
          child: Icon(
            _showQuickActions ? LucideIcons.x : LucideIcons.plus,
            color: Colors.black,
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,

      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outline,
              width: 1,
            ),
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: LucideIcons.inbox,
                  label: 'Memories',
                  isSelected: _currentIndex == 0,
                  onTap: () => setState(() => _currentIndex = 0),
                ),
                _NavItem(
                  icon: LucideIcons.search,
                  label: 'Search',
                  isSelected: _currentIndex == 1,
                  onTap: () => setState(() => _currentIndex = 1),
                ),
                _NavItem(
                  icon: LucideIcons.bellRing,
                  label: 'Activity',
                  isSelected: _currentIndex == 2,
                  onTap: () => setState(() => _currentIndex = 2),
                  badgeCount: pendingCount.maybeWhen(
                    data: (count) => count,
                    orElse: () => 0,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textPrimaryDark,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 10,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.black, size: 22),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final int badgeCount;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badgeCount = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppTheme.accentGold.withOpacity(0.1) 
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 22,
                  color: isSelected 
                      ? AppTheme.accentGold 
                      : AppTheme.textMutedDark,
                ),
                if (isSelected) ...[
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: AppTheme.accentGold,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ).animate().fadeIn(duration: 200.ms).slideX(begin: -0.2),
                ],
              ],
            ),
            if (badgeCount > 0)
              Positioned(
                top: -6,
                right: -6,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: AppTheme.statusFailed,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    badgeCount > 9 ? '9+' : '$badgeCount',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ).animate(onPlay: (c) => c.repeat())
                  .shimmer(duration: 1500.ms, delay: 3000.ms),
              ),
          ],
        ),
      ),
    );
  }
}
