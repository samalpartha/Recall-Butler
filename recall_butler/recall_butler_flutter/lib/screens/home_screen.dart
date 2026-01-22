import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/vibrant_theme.dart';
import '../providers/documents_provider.dart';
import '../providers/suggestions_provider.dart';
import 'ai_agent_screen.dart';
import 'knowledge_graph_viz_screen.dart';
import 'chat_screen.dart';
import 'search_screen.dart';
import 'ingest_screen.dart';
import 'activity_screen.dart';
import 'voice_capture_screen.dart';
import 'camera_capture_screen.dart';
import 'analytics_dashboard_screen.dart';
import 'calendar_screen.dart';
import 'smart_reminders_screen.dart';
import 'workspaces_screen.dart';
import 'web5_profile_screen.dart';
import 'help_screen.dart';
import 'accessibility_screen.dart';
import 'settings_screen.dart';
import 'auth_screen.dart';

/// Vibrant Home Screen with Analytics & Quick Actions
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with TickerProviderStateMixin {
  late AnimationController _chartController;
  late AnimationController _fabController;
  int _selectedNavIndex = 0;
  bool _showQuickActions = false;
  String? _hoveredLabel;

  final List<double> _weeklyData = [0.4, 0.6, 0.5, 0.8, 0.7, 0.9, 0.75];

  // Quick actions for the semicircle menu
  late final List<Map<String, dynamic>> _quickActions;

  // Main screens for bottom nav
  late final List<Widget> _mainScreens;

  @override
  void initState() {
    super.initState();
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
    
    _fabController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    
    _quickActions = [
      {'icon': LucideIcons.plus, 'label': 'Add', 'color': VibrantTheme.primaryGreen, 'action': () => _navigateTo(const IngestScreen())},
      {'icon': LucideIcons.bot, 'label': 'AI Agent', 'color': VibrantTheme.primaryPurple, 'action': () => _navigateTo(const AiAgentScreen())},
      {'icon': LucideIcons.messageCircle, 'label': 'Chat', 'color': VibrantTheme.primaryPink, 'action': () => _navigateTo(const ChatScreen())},
      {'icon': LucideIcons.mic, 'label': 'Voice', 'color': VibrantTheme.primaryOrange, 'action': () => _navigateTo(const VoiceCaptureScreen())},
      {'icon': LucideIcons.camera, 'label': 'Scan', 'color': VibrantTheme.primaryCyan, 'action': () => _navigateTo(const CameraCaptureScreen())},
      {'icon': LucideIcons.network, 'label': 'Graph', 'color': VibrantTheme.primaryBlue, 'action': () => _navigateTo(const KnowledgeGraphVizScreen())},
      {'icon': LucideIcons.barChart3, 'label': 'Analytics', 'color': Colors.deepPurple, 'action': () => _navigateTo(const AnalyticsDashboardScreen())},
      {'icon': LucideIcons.calendar, 'label': 'Calendar', 'color': Colors.indigo, 'action': () => _navigateTo(const CalendarScreen())},
      {'icon': LucideIcons.bell, 'label': 'Reminders', 'color': VibrantTheme.primaryYellow, 'action': () => _navigateTo(const SmartRemindersScreen())},
      {'icon': LucideIcons.users, 'label': 'Teams', 'color': Colors.teal, 'action': () => _navigateTo(const WorkspacesScreen())},
    ];
    
    _mainScreens = [
      _buildHomeContent(),
      const SearchScreen(),
      const ChatScreen(),
      const ActivityScreen(),
    ];
  }

  @override
  void dispose() {
    _chartController.dispose();
    _fabController.dispose();
    super.dispose();
  }

  void _toggleQuickActions() {
    setState(() {
      _showQuickActions = !_showQuickActions;
      _hoveredLabel = null;
    });
    if (_showQuickActions) {
      _fabController.forward();
    } else {
      _fabController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: VibrantTheme.gradientBackground,
        ),
        child: Stack(
          children: [
            // Main content based on selected nav
            SafeArea(
              child: _selectedNavIndex == 0 
                ? CustomScrollView(
                    slivers: [
                      SliverToBoxAdapter(child: _buildAppBar()),
                      SliverToBoxAdapter(child: _buildGreeting()),
                      SliverToBoxAdapter(child: _buildQuickStats()),
                      SliverToBoxAdapter(child: _buildActivityChart()),
                      SliverToBoxAdapter(child: _buildQuickActionsGrid()),
                      SliverToBoxAdapter(child: _buildRecentMemories()),
                      SliverToBoxAdapter(child: _buildAiSuggestions()),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  )
                : _mainScreens[_selectedNavIndex],
            ),
            
            // Semicircle quick actions overlay
            if (_showQuickActions) ...[
              // Backdrop with blur effect
              GestureDetector(
                onTap: _toggleQuickActions,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                  ),
                ).animate().fadeIn(duration: 200.ms),
              ),
              
              // Semicircle menu items
              ..._buildSemicircleMenu(screenSize),
              
              // Label tooltip
              if (_hoveredLabel != null)
                Positioned(
                  bottom: 180,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      decoration: BoxDecoration(
                        color: VibrantTheme.bgCard,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: VibrantTheme.primaryPurple.withOpacity(0.3),
                            blurRadius: 15,
                          ),
                        ],
                      ),
                      child: Text(
                        _hoveredLabel!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
                  ),
                ),
            ],
          ],
        ),
      ),
      
      // Bottom Navigation
      bottomNavigationBar: _buildBottomNav(),
      
      // FAB
      floatingActionButton: _buildFAB(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }

  List<Widget> _buildSemicircleMenu(Size screenSize) {
    final List<Widget> items = [];
    final centerX = screenSize.width / 2;
    final centerY = screenSize.height - 50; // Position above FAB
    final radius = 140.0; // Radius of the semicircle
    
    // Calculate angles for semicircle (180 degrees, from left to right)
    final totalItems = _quickActions.length;
    final startAngle = math.pi; // Start from left (180 degrees)
    final endAngle = 0.0; // End at right (0 degrees)
    final angleStep = (startAngle - endAngle) / (totalItems - 1);
    
    for (int i = 0; i < totalItems; i++) {
      final action = _quickActions[i];
      final angle = startAngle - (angleStep * i);
      
      // Calculate position on semicircle
      final x = centerX + radius * math.cos(angle) - 28; // -28 to center the 56px button
      final y = centerY - radius * math.sin(angle) - 28;
      
      items.add(
        AnimatedBuilder(
          animation: _fabController,
          builder: (context, child) {
            final rawProgress = CurvedAnimation(
              parent: _fabController,
              curve: Interval(
                i * 0.05,
                0.5 + i * 0.05,
                curve: Curves.easeOut,
              ),
            ).value;
            
            // Clamp opacity to valid range (0.0 to 1.0)
            final opacity = rawProgress.clamp(0.0, 1.0);
            final scale = rawProgress.clamp(0.0, 1.5); // Allow slight overshoot for bounce
            
            return Positioned(
              left: x,
              top: y,
              child: Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: _buildSemicircleItem(action, i),
                ),
              ),
            );
          },
        ),
      );
    }
    
    return items;
  }

  Widget _buildSemicircleItem(Map<String, dynamic> action, int index) {
    final color = action['color'] as Color;
    final label = action['label'] as String;
    final isMobile = Theme.of(context).platform == TargetPlatform.android || 
                     Theme.of(context).platform == TargetPlatform.iOS;
    
    return MouseRegion(
      onEnter: (_) => setState(() => _hoveredLabel = label),
      onExit: (_) => setState(() => _hoveredLabel = null),
      child: GestureDetector(
        onTap: () {
          _toggleQuickActions();
          (action['action'] as Function)();
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: color,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.5),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                action['icon'] as IconData,
                color: Colors.white,
                size: 26,
              ),
            ),
            // Show label on mobile, hide on web (web uses hover tooltip)
            if (isMobile) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.7),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHomeContent() {
    return const SizedBox(); // Placeholder, actual content in CustomScrollView
  }

  void _navigateTo(Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (context) => screen));
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: VibrantTheme.bgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(LucideIcons.logOut, color: Colors.red),
            SizedBox(width: 12),
            Text('Sign Out'),
          ],
        ),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: VibrantTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              AuthManager().logout();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (route) => false,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Sign Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          // Profile avatar with menu
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'settings') {
                _navigateTo(const SettingsScreen());
              } else if (value == 'logout') {
                _showLogoutDialog();
              }
            },
            offset: const Offset(0, 55),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            color: VibrantTheme.bgCard,
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'settings',
                child: Row(
                  children: [
                    Icon(LucideIcons.settings, color: VibrantTheme.primaryPurple, size: 20),
                    const SizedBox(width: 12),
                    const Text('Settings'),
                  ],
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(LucideIcons.logOut, color: Colors.red, size: 20),
                    const SizedBox(width: 12),
                    const Text('Sign Out', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: VibrantTheme.gradientPrimary,
                boxShadow: [
                  BoxShadow(
                    color: VibrantTheme.primaryPurple.withOpacity(0.4),
                    blurRadius: 15,
                  ),
                ],
              ),
              child: const Icon(LucideIcons.user, color: Colors.white, size: 24),
            ),
          ),
          
          const SizedBox(width: 12),
          
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recall Butler',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '✨ Premium',
                  style: TextStyle(
                    color: VibrantTheme.primaryPurple,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Notification bell
          GestureDetector(
            onTap: () => _navigateTo(const SmartRemindersScreen()),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: VibrantTheme.bgCard,
              ),
              child: Stack(
                children: [
                  const Icon(LucideIcons.bell, size: 22),
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: VibrantTheme.primaryPink,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(width: 8),
          
          // Settings
          GestureDetector(
            onTap: () => _navigateTo(const SettingsScreen()),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: VibrantTheme.bgCard,
              ),
              child: const Icon(LucideIcons.settings, size: 22),
            ),
          ),
        ],
      ),
    ).animate().fadeIn().slideY(begin: -0.2);
  }

  Widget _buildGreeting() {
    final hour = DateTime.now().hour;
    String greeting;
    IconData icon;
    
    if (hour < 12) {
      greeting = 'Good Morning';
      icon = LucideIcons.sunrise;
    } else if (hour < 17) {
      greeting = 'Good Afternoon';
      icon = LucideIcons.sun;
    } else {
      greeting = 'Good Evening';
      icon = LucideIcons.moon;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: VibrantTheme.primaryYellow, size: 28),
              const SizedBox(width: 8),
              Text(
                greeting,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  foreground: Paint()
                    ..shader = const LinearGradient(
                      colors: [VibrantTheme.primaryPurple, VibrantTheme.primaryPink],
                    ).createShader(const Rect.fromLTWH(0, 0, 200, 40)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Ready to capture some memories?',
            style: TextStyle(
              color: VibrantTheme.textSecondary,
              fontSize: 16,
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1);
  }

  Widget _buildQuickStats() {
    final documents = ref.watch(documentsProvider);
    final suggestions = ref.watch(suggestionsProvider);
    
    final docCount = documents.when(
      data: (docs) => docs.length.toString(),
      loading: () => '...',
      error: (_, __) => '0',
    );
    
    final suggestionCount = suggestions.when(
      data: (suggs) => suggs.length.toString(),
      loading: () => '...',
      error: (_, __) => '0',
    );

    final stats = [
      {'icon': LucideIcons.fileText, 'value': docCount, 'label': 'Memories', 'color': VibrantTheme.primaryPurple},
      {'icon': LucideIcons.search, 'value': '89', 'label': 'Searches', 'color': VibrantTheme.primaryBlue},
      {'icon': LucideIcons.sparkles, 'value': suggestionCount, 'label': 'Suggestions', 'color': VibrantTheme.primaryPink},
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: stats.asMap().entries.map((entry) {
          final index = entry.key;
          final stat = entry.value;
          
          return Expanded(
            child: GestureDetector(
              onTap: () {
                if (index == 1) setState(() => _selectedNavIndex = 1);
                if (index == 2) setState(() => _selectedNavIndex = 3);
              },
              child: Container(
                margin: EdgeInsets.only(
                  left: index == 0 ? 0 : 6,
                  right: index == stats.length - 1 ? 0 : 6,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: VibrantTheme.bgCard,
                  border: Border.all(
                    color: (stat['color'] as Color).withOpacity(0.3),
                  ),
                ),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: (stat['color'] as Color).withOpacity(0.2),
                      ),
                      child: Icon(
                        stat['icon'] as IconData,
                        color: stat['color'] as Color,
                        size: 20,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      stat['value'] as String,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: stat['color'] as Color,
                      ),
                    ),
                    Text(
                      stat['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        color: VibrantTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ).animate(delay: (200 + index * 100).ms)
                .fadeIn()
                .scale(begin: const Offset(0.9, 0.9)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildActivityChart() {
    return GestureDetector(
      onTap: () => _navigateTo(const AnalyticsDashboardScreen()),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              VibrantTheme.primaryPurple.withOpacity(0.15),
              VibrantTheme.primaryPink.withOpacity(0.1),
            ],
          ),
          border: Border.all(
            color: VibrantTheme.primaryPurple.withOpacity(0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Activity',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Tap to see full analytics',
                      style: TextStyle(
                        color: VibrantTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    color: VibrantTheme.primaryGreen.withOpacity(0.2),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(LucideIcons.trendingUp, color: VibrantTheme.primaryGreen, size: 16),
                      SizedBox(width: 4),
                      Text(
                        '+23%',
                        style: TextStyle(
                          color: VibrantTheme.primaryGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),
            
            // Animated bar chart
            SizedBox(
              height: 140,
              child: AnimatedBuilder(
                animation: _chartController,
                builder: (context, _) {
                  return Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(7, (index) {
                      final days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
                      final height = _weeklyData[index] * 100 * _chartController.value;
                      final isToday = index == DateTime.now().weekday - 1;
                      
                      return Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            width: 28,
                            height: height,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              gradient: isToday
                                ? VibrantTheme.gradientPrimary
                                : LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [
                                      VibrantTheme.primaryPurple.withOpacity(0.3),
                                      VibrantTheme.primaryPurple.withOpacity(0.1),
                                    ],
                                  ),
                              boxShadow: isToday
                                ? [
                                    BoxShadow(
                                      color: VibrantTheme.primaryPurple.withOpacity(0.5),
                                      blurRadius: 12,
                                    ),
                                  ]
                                : null,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            days[index],
                            style: TextStyle(
                              color: isToday
                                ? VibrantTheme.primaryPurple
                                : VibrantTheme.textSecondary,
                              fontWeight: isToday ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    }),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildQuickActionsGrid() {
    final actions = [
      {'icon': LucideIcons.bot, 'label': 'AI Agent', 'color': VibrantTheme.primaryPurple, 'gradient': VibrantTheme.gradientPrimary, 'screen': const AiAgentScreen()},
      {'icon': LucideIcons.network, 'label': 'Graph', 'color': VibrantTheme.primaryCyan, 'gradient': VibrantTheme.gradientSecondary, 'screen': const KnowledgeGraphVizScreen()},
      {'icon': LucideIcons.mic, 'label': 'Voice', 'color': VibrantTheme.primaryPink, 'gradient': VibrantTheme.gradientPrimary, 'screen': const VoiceCaptureScreen()},
      {'icon': LucideIcons.camera, 'label': 'Scan', 'color': VibrantTheme.primaryOrange, 'gradient': VibrantTheme.gradientWarning, 'screen': const CameraCaptureScreen()},
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Quick Actions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: actions.asMap().entries.map((entry) {
              final index = entry.key;
              final action = entry.value;
              
              return Expanded(
                child: GestureDetector(
                  onTap: () => _navigateTo(action['screen'] as Widget),
                  child: Container(
                    margin: EdgeInsets.only(
                      left: index == 0 ? 0 : 4,
                      right: index == actions.length - 1 ? 0 : 4,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      gradient: action['gradient'] as LinearGradient,
                      boxShadow: [
                        BoxShadow(
                          color: (action['color'] as Color).withOpacity(0.4),
                          blurRadius: 15,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(
                          action['icon'] as IconData,
                          color: Colors.white,
                          size: 28,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          action['label'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate(delay: (500 + index * 80).ms)
                  .fadeIn()
                  .slideY(begin: 0.2),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentMemories() {
    final documents = ref.watch(documentsProvider);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Recent Memories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _selectedNavIndex = 1),
                child: Text(
                  'See All',
                  style: TextStyle(color: VibrantTheme.primaryPurple),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          documents.when(
            data: (docs) {
              if (docs.isEmpty) {
                return _buildEmptyMemories();
              }
              return Column(
                children: docs.take(3).toList().asMap().entries.map((entry) {
                  final index = entry.key;
                  final doc = entry.value;
                  
                  return GestureDetector(
                    onTap: () => setState(() => _selectedNavIndex = 1),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: VibrantTheme.bgCard,
                        border: Border.all(
                          color: VibrantTheme.primaryPurple.withOpacity(0.2),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              color: VibrantTheme.primaryPurple.withOpacity(0.2),
                            ),
                            child: Icon(
                              LucideIcons.fileText,
                              color: VibrantTheme.primaryPurple,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  doc.title,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  doc.sourceType,
                                  style: TextStyle(
                                    color: VibrantTheme.textSecondary,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(
                            LucideIcons.chevronRight,
                            color: VibrantTheme.textSecondary,
                          ),
                        ],
                      ),
                    ),
                  ).animate(delay: (700 + index * 100).ms)
                    .fadeIn()
                    .slideX(begin: 0.1);
                }).toList(),
              );
            },
            loading: () => const Center(
              child: CircularProgressIndicator(color: VibrantTheme.primaryPurple),
            ),
            error: (_, __) => _buildEmptyMemories(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMemories() {
    return GestureDetector(
      onTap: () => _toggleQuickActions(),
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: VibrantTheme.bgCard,
          border: Border.all(color: VibrantTheme.primaryPurple.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: VibrantTheme.primaryPurple.withOpacity(0.2),
              ),
              child: Icon(
                LucideIcons.folderOpen,
                color: VibrantTheme.primaryPurple,
                size: 40,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'No memories yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first memory',
              style: TextStyle(color: VibrantTheme.textSecondary),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 700.ms);
  }

  Widget _buildAiSuggestions() {
    final suggestions = ref.watch(suggestionsProvider);
    
    return GestureDetector(
      onTap: () => setState(() => _selectedNavIndex = 3),
      child: Container(
        margin: const EdgeInsets.all(20),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              VibrantTheme.primaryPink.withOpacity(0.15),
              VibrantTheme.primaryOrange.withOpacity(0.1),
            ],
          ),
          border: Border.all(
            color: VibrantTheme.primaryPink.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: VibrantTheme.gradientPrimary,
                  ),
                  child: const Icon(LucideIcons.sparkles, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'AI Suggestions',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  'Tap to view all',
                  style: TextStyle(
                    color: VibrantTheme.primaryPink,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            suggestions.when(
              data: (suggs) {
                if (suggs.isEmpty) {
                  return _buildSuggestionItem(
                    'No suggestions yet. Add more memories!',
                    LucideIcons.lightbulb,
                  );
                }
                return Column(
                  children: suggs.take(2).map((s) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _buildSuggestionItem(s.title, LucideIcons.lightbulb),
                  )).toList(),
                );
              },
              loading: () => _buildSuggestionItem('Loading suggestions...', LucideIcons.loader2),
              error: (_, __) => _buildSuggestionItem('Could not load suggestions', LucideIcons.alertCircle),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.1);
  }

  Widget _buildSuggestionItem(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: VibrantTheme.primaryPink, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: VibrantTheme.primaryPink.withOpacity(0.2),
          ),
          child: const Icon(LucideIcons.chevronRight, color: VibrantTheme.primaryPink, size: 16),
        ),
      ],
    );
  }

  Widget _buildBottomNav() {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: VibrantTheme.bgCard,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(0, LucideIcons.home, 'Home'),
          _buildNavItem(1, LucideIcons.search, 'Search'),
          const SizedBox(width: 60), // Space for FAB
          _buildNavItem(2, LucideIcons.messageCircle, 'Chat'),
          _buildNavItem(3, LucideIcons.activity, 'Activity'),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label) {
    final isSelected = _selectedNavIndex == index;
    
    return GestureDetector(
      onTap: () {
        if (index == 2) {
          // Chat opens in new screen
          _navigateTo(const ChatScreen());
        } else {
          setState(() => _selectedNavIndex = index);
        }
      },
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: isSelected
                ? VibrantTheme.primaryPurple.withOpacity(0.2)
                : Colors.transparent,
            ),
            child: Icon(
              icon,
              color: isSelected
                ? VibrantTheme.primaryPurple
                : VibrantTheme.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              color: isSelected
                ? VibrantTheme.primaryPurple
                : VibrantTheme.textSecondary,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFAB() {
    return GestureDetector(
      onTap: _toggleQuickActions,
      child: AnimatedBuilder(
        animation: _fabController,
        builder: (context, child) {
          return Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF2D5A8A), Color(0xFF4FACFE)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF4FACFE).withOpacity(0.5 + _fabController.value * 0.3),
                  blurRadius: 20 + _fabController.value * 10,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Transform.rotate(
              angle: _fabController.value * math.pi / 4,
              child: Icon(
                _showQuickActions ? LucideIcons.x : LucideIcons.plus,
                color: Colors.white,
                size: 28,
              ),
            ),
          );
        },
      ),
    );
  }
}
