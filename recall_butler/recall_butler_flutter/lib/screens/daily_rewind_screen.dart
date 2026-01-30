import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../theme/app_theme.dart';
import '../providers/documents_provider.dart';

class DailyRewindScreen extends ConsumerStatefulWidget {
  const DailyRewindScreen({super.key});

  @override
  ConsumerState<DailyRewindScreen> createState() => _DailyRewindScreenState();
}

class _DailyRewindScreenState extends ConsumerState<DailyRewindScreen> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentIndex = 0;
  bool _isFlipped = false;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onCardTap() {
    setState(() {
      _isFlipped = !_isFlipped;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Determine the time of day for the greeting
    final hour = DateTime.now().hour;
    String greeting = 'Your Daily Rewind';
    if (hour < 12) greeting = 'Morning Recall';
    else if (hour > 18) greeting = 'Evening Reflection';

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Stack(
        children: [
          // Ambient Background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.5,
                  colors: [
                    Colors.deepPurple.withOpacity(0.2),
                    AppTheme.primaryDark,
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Header
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        greeting,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.accentGold.withOpacity(0.5)),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.flame, size: 16, color: AppTheme.accentGold),
                            const SizedBox(width: 4),
                            const Text(
                              'Day 3',
                              style: TextStyle(
                                color: AppTheme.accentGold,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Progress Indicator
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: (_currentIndex + 1) / 5, // Mock total of 5 items
                      backgroundColor: Colors.white.withOpacity(0.1),
                    valueColor: const AlwaysStoppedAnimation(Colors.deepPurple),
                      minHeight: 4,
                    ),
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Cards PageView
                Expanded(
                  child: PageView.builder(
                    controller: _pageController,
                    onPageChanged: (index) {
                      setState(() {
                        _currentIndex = index;
                        _isFlipped = false; // Reset flip on slide
                      });
                    },
                    itemCount: 5, // Mock data count
                    itemBuilder: (context, index) {
                      // Parallax / Scale effect
                      return AnimatedBuilder(
                        animation: _pageController,
                        builder: (context, child) {
                          double value = 1.0;
                          if (_pageController.position.haveDimensions) {
                            value = _pageController.page! - index;
                            value = (1 - (value.abs() * 0.2)).clamp(0.0, 1.0);
                          }
                          return Center(
                            child: SizedBox(
                              height: Curves.easeOut.transform(value) * MediaQuery.of(context).size.height * 0.6,
                              width: Curves.easeOut.transform(value) * 400,
                              child: child,
                            ),
                          );
                        },
                        child: _RewindCard(
                          index: index,
                          isFlipped: _currentIndex == index ? _isFlipped : false,
                          onTap: _onCardTap,
                        ),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Action Buttons
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _ActionButton(
                        icon: LucideIcons.x,
                        color: Colors.redAccent,
                        onTap: () {
                           if (_currentIndex < 4) {
                             _pageController.nextPage(duration: 300.ms, curve: Curves.easeOut);
                           }
                        },
                      ),
                      const SizedBox(width: 32),
                      _ActionButton(
                        icon: LucideIcons.rotateCcw,
                        color: Colors.white54,
                        isSmall: true,
                        onTap: () => setState(() => _isFlipped = !_isFlipped),
                      ),
                      const SizedBox(width: 32),
                      _ActionButton(
                        icon: LucideIcons.check,
                        color: Colors.greenAccent,
                        onTap: () {
                           if (_currentIndex < 4) {
                             _pageController.nextPage(duration: 300.ms, curve: Curves.easeOut);
                           }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewindCard extends StatelessWidget {
  final int index;
  final bool isFlipped;
  final VoidCallback onTap;

  const _RewindCard({
    required this.index,
    required this.isFlipped,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    // Mock Data based on index
    final data = _getMockData(index);

    return GestureDetector(
      onTap: onTap,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: isFlipped ? 180 : 0),
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutBack,
        builder: (context, value, child) {
          final isFront = value < 90;
          return Transform(
            // 3D Rotation effect
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..rotateY((value * math.pi / 180)),
            alignment: Alignment.center,
            child: isFront
                ? _buildFront(context, data)
                : Transform(
                    transform: Matrix4.identity()..rotateY(math.pi),
                    alignment: Alignment.center,
                    child: _buildBack(context, data),
                  ),
          );
        },
      ),
    );
  }

  Widget _buildFront(BuildContext context, Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Content
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: (data['color'] as Color).withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(data['icon'] as IconData, size: 48, color: data['color'] as Color),
                ),
                const SizedBox(height: 32),
                Text(
                  'Do you remember?',
                  style: TextStyle(
                    color: AppTheme.textMutedDark,
                    fontSize: 14,
                    letterSpacing: 2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  data['question'] as String,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 48),
                Text(
                  'Tap to reveal',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.3),
                    fontSize: 12,
                  ),
                ).animate(onPlay: (c) => c.repeat()).fadeIn(duration: 800.ms).then().fadeOut(duration: 800.ms),
              ],
            ),
          ),
          
          // Corner badge
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: (data['color'] as Color).withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                data['tag'] as String,
                style: TextStyle(
                  color: data['color'] as Color,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBack(BuildContext context, Map<String, dynamic> data) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            // AppTheme.bgCard, // Fallback
            AppTheme.cardDark,
            AppTheme.primaryDark,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: (data['color'] as Color).withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: (data['color'] as Color).withOpacity(0.2),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              data['answer_title'] as String,
              style: TextStyle(
                color: data['color'] as Color,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              data['answer_body'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 40),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(LucideIcons.calendar, size: 14, color: AppTheme.textMutedDark),
                  const SizedBox(width: 8),
                  Text(
                    data['date'] as String,
                    style: TextStyle(color: AppTheme.textMutedDark, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Map<String, dynamic> _getMockData(int index) {
    final list = [
      {
        'color': AppTheme.accentTeal,
        'icon': LucideIcons.lightbulb,
        'tag': 'Insight',
        'question': 'What was the key takeaway from the "Project Alpha" meeting?',
        'answer_title': 'Meeting Notes: Alpha Kickoff',
        'answer_body': 'We decided to prioritize the mobile UI over the web dashboard for Q1 due to user feedback.',
        'date': '2 days ago',
      },
      {
        'color': Colors.deepPurpleAccent,
        'icon': LucideIcons.quote,
        'tag': 'Quote',
        'question': 'Who said "Design is intelligence made visible"?',
        'answer_title': 'Design Inspiration',
        'answer_body': 'Alina Wheeler using this quote in your moodboard for the new brand identity.',
        'date': 'Last week',
      },
      {
        'color': AppTheme.accentGold,
        'icon': LucideIcons.brainCircuit,
        'tag': 'Idea',
        'question': 'You had an idea about "Smart Stacks". What was it?',
        'answer_title': 'Voice Note: Feature Ideas',
        'answer_body': 'Auto-grouping memories based on semantic similarity using embedding clusters.',
        'date': 'Yesterday',
      },
      {
        'color': Colors.pinkAccent,
        'icon': LucideIcons.heart,
        'tag': 'Memory',
        'question': 'Where did you go for your anniversary dinner?',
        'answer_title': 'Photo: Anniversary',
        'answer_body': 'Le Coucou. You loved the pike quorumelles and took a photo of the dessert.',
        'date': '3 months ago',
      },
      {
        'color': Colors.blueAccent,
        'icon': LucideIcons.code,
        'tag': 'Tech',
        'question': 'What library did you save for "Graph Visualization"?',
        'answer_title': 'Bookmark: Flutter Libraries',
        'answer_body': 'flutter_force_directed_graph. You noted it handles up to 500 nodes smoothly.',
        'date': '5 days ago',
      },
    ];
    return list[index % list.length];
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool isSmall;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    final size = isSmall ? 48.0 : 64.0;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 10,
              offset: const Offset(0, 5),
            ),
          ],
          border: Border.all(
            color: isSmall ? Colors.white24 : color.withOpacity(0.3),
            width: 2,
          ),
        ),
        child: Icon(
          icon,
          color: color,
          size: size * 0.45,
        ),
      ).animate(target: 1).scale(
        begin: const Offset(0.9, 0.9),
        end: const Offset(1, 1),
        duration: 200.ms,
      ),
    );
  }
}
