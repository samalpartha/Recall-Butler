import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../providers/suggestions_provider.dart';
import '../providers/connectivity_provider.dart';
import '../widgets/offline_indicator.dart';
import '../widgets/command_palette.dart';
import '../widgets/unified_capture.dart';
import '../providers/action_provider.dart';
import '../widgets/action_preview_card.dart';

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
import 'knowledge_graph_viz_screen.dart';
import 'calendar_screen.dart';
import 'smart_reminders_screen.dart';
import 'workspaces_screen.dart';
import 'ai_agent_screen.dart';

/// Main shell with bottom navigation and quick actions
class ShellScreen extends ConsumerStatefulWidget {
  const ShellScreen({super.key});

  @override
  ConsumerState<ShellScreen> createState() => _ShellScreenState();
}

class _ShellScreenState extends ConsumerState<ShellScreen> {
  int _currentIndex = 0;
  bool _showCommandPalette = false;
  
  final List<Widget> _screens = const [
    IngestScreen(),
    SearchScreen(),
    ActivityScreen(),
  ];

  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleKeyEvent);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleKeyEvent);
    super.dispose();
  }

  bool _handleKeyEvent(KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.keyK &&
        (HardwareKeyboard.instance.isMetaPressed || HardwareKeyboard.instance.isControlPressed)) {
      setState(() => _showCommandPalette = !_showCommandPalette);
      return true;
    }
    return false;
  }

  void _handleCommand(String commandId) {
    setState(() => _showCommandPalette = false);
    
    if (commandId.startsWith('action:')) {
      final query = commandId.substring(7);
      ref.read(actionProcessingProvider.notifier).analyzeText(query);
      return;
    }

    switch (commandId) {
      case 'search':
        setState(() => _currentIndex = 1); // Search tab
        break;
      case 'note':
        // TODO: Direct to text note creation
        _currentIndex = 0; // Ingest tab for now
        break;
      case 'voice':
        _openVoice();
        break;
      case 'scan':
        _openCamera();
        break;
      case 'chat':
        _openChat();
        break;
      case 'analytics':
        _openAnalytics();
        break;
      case 'settings':
        // _openSettings();
        break;
    }
  }

  void _openChat() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ChatScreen()),
    );
  }

  void _openVoice() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const VoiceCaptureScreen()),
    );
  }

  void _openCamera() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CameraCaptureScreen()),
    );
  }

  void _openLink() {
     // TODO: Implement link capture dialog or screen
     setState(() => _currentIndex = 0);
  }

  void _openAnalytics() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AnalyticsDashboardScreen()),
    );
  }

  // ... keep other navigation methods if needed, or remove if unused by CommandPalette

  @override
  Widget build(BuildContext context) {
    final pendingCount = ref.watch(pendingSuggestionsCountProvider);
    
    return Scaffold(
      body: Stack(
        children: [
          // Main content
          Column(
            children: [
              const OfflineBanner(),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _screens[_currentIndex],
                ),
              ),
            ],
          ),

          // Command Palette Overlay
          if (_showCommandPalette)
            Positioned.fill(
              child: CommandPalette(
                isVisible: _showCommandPalette,
                onClose: () => setState(() => _showCommandPalette = false),
                onCommandSelected: _handleCommand,
              ),
            ),

          // Action Preview Overlay
          const Positioned(
            bottom: 80,
            left: 0,
            right: 0,
            child: ActionPreviewCard(),
          ),
        ],
      ),

      // Unified Capture FAB
      floatingActionButton: UnifiedCaptureBtn(
        onText: () => setState(() => _currentIndex = 0), // Go to Ingest
        onVoice: _openVoice,
        onCamera: _openCamera,
        onLink: _openLink,
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
