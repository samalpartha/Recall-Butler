import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../theme/app_theme.dart';

/// Beautiful Analytics Dashboard with animated charts
class AnalyticsDashboardScreen extends StatefulWidget {
  const AnalyticsDashboardScreen({super.key});

  @override
  State<AnalyticsDashboardScreen> createState() => _AnalyticsDashboardScreenState();
}

class _AnalyticsDashboardScreenState extends State<AnalyticsDashboardScreen>
    with TickerProviderStateMixin {
  late AnimationController _chartController;
  
  // Sample data
  final _weeklyData = [0.3, 0.5, 0.7, 0.4, 0.8, 0.6, 0.9];
  final _categoryData = {'Work': 0.35, 'Personal': 0.25, 'Ideas': 0.2, 'Learning': 0.2};

  @override
  void initState() {
    super.initState();
    _chartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..forward();
  }

  @override
  void dispose() {
    _chartController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: CustomScrollView(
        slivers: [
          // Custom App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: AppTheme.primaryDark,
            flexibleSpace: FlexibleSpaceBar(
              title: const Text(
                'Analytics',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.accentGold.withOpacity(0.2),
                      AppTheme.primaryDark,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.download),
                onPressed: () {},
                tooltip: 'Export Report',
              ),
              IconButton(
                icon: const Icon(LucideIcons.settings),
                onPressed: () {},
                tooltip: 'Settings',
              ),
            ],
          ),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(16),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Quick Stats Row
                _buildQuickStats(),
                const SizedBox(height: 24),
                
                // Activity Chart
                _buildActivityChart(),
                const SizedBox(height: 24),
                
                // Category Breakdown
                _buildCategoryBreakdown(),
                const SizedBox(height: 24),
                
                // Insights Grid
                _buildInsightsGrid(),
                const SizedBox(height: 24),
                
                // AI Recommendations
                _buildAiRecommendations(),
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStats() {
    final stats = [
      {'icon': LucideIcons.fileText, 'value': '247', 'label': 'Memories', 'color': AppTheme.accentGold},
      {'icon': LucideIcons.search, 'value': '89', 'label': 'Searches', 'color': AppTheme.accentTeal},
      {'icon': LucideIcons.lightbulb, 'value': '32', 'label': 'Insights', 'color': AppTheme.accentCopper},
      {'icon': LucideIcons.brain, 'value': '156', 'label': 'AI Chats', 'color': Colors.purple},
    ];

    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: stats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, index) {
          final stat = stats[index];
          return _buildStatCard(
            icon: stat['icon'] as IconData,
            value: stat['value'] as String,
            label: stat['label'] as String,
            color: stat['color'] as Color,
          ).animate(delay: (100 * index).ms)
            .fadeIn()
            .slideX(begin: 0.2);
        },
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
  }) {
    return Container(
      width: 140,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.2),
            color.withOpacity(0.05),
          ],
        ),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 24),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textMutedDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityChart() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppTheme.surfaceDark,
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Weekly Activity',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Memories captured per day',
                    style: TextStyle(color: AppTheme.textMutedDark),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: Colors.green.withOpacity(0.2),
                ),
                child: const Row(
                  children: [
                    Icon(LucideIcons.trendingUp, color: Colors.green, size: 16),
                    SizedBox(width: 4),
                    Text(
                      '+23%',
                      style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 32),
          
          // Animated Bar Chart
          SizedBox(
            height: 180,
            child: AnimatedBuilder(
              animation: _chartController,
              builder: (context, _) {
                return Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: List.generate(7, (index) {
                    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                    final height = _weeklyData[index] * 150 * _chartController.value;
                    final isToday = index == 6;
                    
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Container(
                          width: 32,
                          height: height,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: isToday
                                ? [AppTheme.accentGold, AppTheme.accentCopper]
                                : [
                                    AppTheme.accentGold.withOpacity(0.3),
                                    AppTheme.accentGold.withOpacity(0.1),
                                  ],
                            ),
                            boxShadow: isToday
                              ? [
                                  BoxShadow(
                                    color: AppTheme.accentGold.withOpacity(0.4),
                                    blurRadius: 10,
                                  ),
                                ]
                              : null,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          days[index],
                          style: TextStyle(
                            color: isToday ? AppTheme.accentGold : AppTheme.textMutedDark,
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
    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildCategoryBreakdown() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        color: AppTheme.surfaceDark,
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Category Distribution',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          
          Row(
            children: [
              // Donut Chart
              SizedBox(
                width: 150,
                height: 150,
                child: AnimatedBuilder(
                  animation: _chartController,
                  builder: (context, _) {
                    return CustomPaint(
                      painter: DonutChartPainter(
                        data: _categoryData,
                        progress: _chartController.value,
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 24),
              
              // Legend
              Expanded(
                child: Column(
                  children: _categoryData.entries.map((entry) {
                    final colors = [
                      AppTheme.accentGold,
                      AppTheme.accentTeal,
                      AppTheme.accentCopper,
                      Colors.purple,
                    ];
                    final index = _categoryData.keys.toList().indexOf(entry.key);
                    
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: colors[index],
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              entry.key,
                              style: const TextStyle(fontWeight: FontWeight.w500),
                            ),
                          ),
                          Text(
                            '${(entry.value * 100).toInt()}%',
                            style: TextStyle(
                              color: colors[index],
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }

  Widget _buildInsightsGrid() {
    final insights = [
      {
        'icon': LucideIcons.clock,
        'title': 'Peak Hours',
        'value': '2-4 PM',
        'subtitle': 'Most active capture time',
        'color': AppTheme.accentGold,
      },
      {
        'icon': LucideIcons.zap,
        'title': 'Memory Streak',
        'value': '12 days',
        'subtitle': 'Current streak',
        'color': Colors.orange,
      },
      {
        'icon': LucideIcons.target,
        'title': 'Suggestions',
        'value': '87%',
        'subtitle': 'Acceptance rate',
        'color': Colors.green,
      },
      {
        'icon': LucideIcons.network,
        'title': 'Connections',
        'value': '156',
        'subtitle': 'Knowledge links',
        'color': AppTheme.accentTeal,
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.2,
      ),
      itemCount: insights.length,
      itemBuilder: (context, index) {
        final insight = insights[index];
        return _buildInsightCard(
          icon: insight['icon'] as IconData,
          title: insight['title'] as String,
          value: insight['value'] as String,
          subtitle: insight['subtitle'] as String,
          color: insight['color'] as Color,
        ).animate(delay: (100 * index + 500).ms)
          .fadeIn()
          .scale(begin: const Offset(0.9, 0.9));
      },
    );
  }

  Widget _buildInsightCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.surfaceDark,
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(color: AppTheme.textMutedDark, fontSize: 12),
              ),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            subtitle,
            style: TextStyle(color: AppTheme.textMutedDark, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildAiRecommendations() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentGold.withOpacity(0.15),
            AppTheme.accentCopper.withOpacity(0.1),
          ],
        ),
        border: Border.all(color: AppTheme.accentGold.withOpacity(0.3)),
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
                  color: AppTheme.accentGold.withOpacity(0.2),
                ),
                child: Icon(LucideIcons.sparkles, color: AppTheme.accentGold),
              ),
              const SizedBox(width: 12),
              Text(
                'AI Recommendations',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildRecommendationItem(
            'You have 5 unlinked documents that might be related to "Project Alpha"',
            LucideIcons.link,
          ),
          const SizedBox(height: 12),
          _buildRecommendationItem(
            'Consider setting reminders for 3 pending tasks mentioned in your notes',
            LucideIcons.bell,
          ),
          const SizedBox(height: 12),
          _buildRecommendationItem(
            'Your "Ideas" category has grown 40% - consider creating a new workspace',
            LucideIcons.folderPlus,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.1);
  }

  Widget _buildRecommendationItem(String text, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.accentGold, size: 18),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14),
          ),
        ),
        Icon(LucideIcons.chevronRight, color: AppTheme.textMutedDark, size: 18),
      ],
    );
  }
}

/// Custom donut chart painter
class DonutChartPainter extends CustomPainter {
  final Map<String, double> data;
  final double progress;

  DonutChartPainter({required this.data, required this.progress});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;
    const strokeWidth = 25.0;

    final colors = [
      AppTheme.accentGold,
      AppTheme.accentTeal,
      AppTheme.accentCopper,
      Colors.purple,
    ];

    var startAngle = -math.pi / 2;
    var index = 0;

    for (final entry in data.entries) {
      final sweepAngle = 2 * math.pi * entry.value * progress;
      
      final paint = Paint()
        ..color = colors[index]
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle - 0.05,
        false,
        paint,
      );

      startAngle += sweepAngle;
      index++;
    }

    // Center circle
    final centerPaint = Paint()
      ..color = AppTheme.surfaceDark
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - strokeWidth / 2 - 5, centerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
