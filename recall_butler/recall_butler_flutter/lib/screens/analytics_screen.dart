import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'dart:math' as math;

import '../theme/app_theme.dart';
import '../providers/connectivity_provider.dart';

/// Provider for analytics data
final analyticsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getAnalytics();
});

final insightsProvider = FutureProvider<Map<String, dynamic>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return api.getInsights();
});

/// Analytics Dashboard Screen
class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analytics = ref.watch(analyticsProvider);
    final insights = ref.watch(insightsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(LucideIcons.barChart3, color: AppTheme.accentGold, size: 24),
            const SizedBox(width: 12),
            const Text('Analytics'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.refreshCw),
            onPressed: () {
              ref.invalidate(analyticsProvider);
              ref.invalidate(insightsProvider);
            },
          ),
        ],
      ),
      body: analytics.when(
        loading: () => _buildLoadingState(),
        error: (err, _) => _buildErrorState(err.toString()),
        data: (data) => _buildDashboard(data, insights),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _animationController,
            builder: (context, child) {
              return Transform.rotate(
                angle: _animationController.value * 2 * math.pi,
                child: Icon(
                  LucideIcons.loader2,
                  size: 48,
                  color: AppTheme.accentGold,
                ),
              );
            },
          ),
          const SizedBox(height: 16),
          Text(
            'Loading analytics...',
            style: TextStyle(color: AppTheme.textSecondaryDark),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(LucideIcons.alertCircle, size: 64, color: AppTheme.statusFailed),
          const SizedBox(height: 16),
          Text(
            'Failed to load analytics',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(color: AppTheme.textMutedDark),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ref.invalidate(analyticsProvider);
              ref.invalidate(insightsProvider);
            },
            icon: const Icon(LucideIcons.refreshCw),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboard(
    Map<String, dynamic> data,
    AsyncValue<Map<String, dynamic>> insightsData,
  ) {
    final documents = data['documents'] as Map<String, dynamic>? ?? {};
    final suggestions = data['suggestions'] as Map<String, dynamic>? ?? {};
    final searches = data['searches'] as Map<String, dynamic>? ?? {};

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Insights Section
          insightsData.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (insightData) => _buildInsightsSection(insightData),
          ),
          const SizedBox(height: 24),

          // Overview Stats
          Text(
            'Overview',
            style: Theme.of(context).textTheme.headlineSmall,
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
          const SizedBox(height: 16),

          // Stats Grid
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.4,
            children: [
              _StatCard(
                icon: LucideIcons.fileText,
                label: 'Total Memories',
                value: '${documents['total'] ?? 0}',
                trend: '+${documents['thisWeek'] ?? 0} this week',
                color: AppTheme.accentGold,
                delay: 200,
              ),
              _StatCard(
                icon: LucideIcons.lightbulb,
                label: 'Suggestions',
                value: '${suggestions['total'] ?? 0}',
                trend: '${suggestions['pending'] ?? 0} pending',
                color: AppTheme.accentTeal,
                delay: 300,
              ),
              _StatCard(
                icon: LucideIcons.search,
                label: 'Searches',
                value: '${searches['total'] ?? 0}',
                trend: '+${searches['thisWeek'] ?? 0} this week',
                color: AppTheme.statusProcessing,
                delay: 400,
              ),
              _StatCard(
                icon: LucideIcons.checkCircle,
                label: 'Acceptance Rate',
                value: '${(suggestions['acceptanceRate'] ?? 0).toStringAsFixed(0)}%',
                trend: 'of suggestions',
                color: AppTheme.statusReady,
                delay: 500,
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Activity Chart
          _buildActivityChart(documents),
          const SizedBox(height: 32),

          // Document Types
          _buildDocumentTypesChart(),
          const SizedBox(height: 32),

          // Memory Growth Visualization
          _buildMemoryGrowth(documents),
        ],
      ),
    );
  }

  Widget _buildInsightsSection(Map<String, dynamic> data) {
    final insights = (data['insights'] as List?) ?? [];
    if (insights.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(LucideIcons.sparkles, color: AppTheme.accentGold, size: 20),
            const SizedBox(width: 8),
            Text(
              'Insights',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ).animate().fadeIn().slideX(begin: -0.1),
        const SizedBox(height: 12),
        ...insights.asMap().entries.map((entry) {
          final insight = entry.value as Map<String, dynamic>;
          return _InsightCard(
            icon: insight['icon'] ?? '💡',
            title: insight['title'] ?? '',
            description: insight['description'] ?? '',
            priority: insight['priority'] ?? 'low',
            delay: entry.key * 100 + 100,
          );
        }),
      ],
    );
  }

  Widget _buildActivityChart(Map<String, dynamic> documents) {
    final total = documents['total'] ?? 0;
    final thisMonth = documents['thisMonth'] ?? 0;
    final thisWeek = documents['thisWeek'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardDark.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.activity, color: AppTheme.accentGold, size: 20),
              const SizedBox(width: 8),
              Text(
                'Memory Activity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Activity bars
          _ActivityBar(
            label: 'This Week',
            value: thisWeek,
            maxValue: math.max(total, 1),
            color: AppTheme.accentGold,
            delay: 600,
          ),
          const SizedBox(height: 16),
          _ActivityBar(
            label: 'This Month',
            value: thisMonth,
            maxValue: math.max(total, 1),
            color: AppTheme.accentTeal,
            delay: 700,
          ),
          const SizedBox(height: 16),
          _ActivityBar(
            label: 'All Time',
            value: total,
            maxValue: math.max(total, 1),
            color: AppTheme.statusProcessing,
            delay: 800,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.1);
  }

  Widget _buildDocumentTypesChart() {
    // Simulated document types - in production, this comes from API
    final types = [
      {'type': 'Text Notes', 'count': 45, 'color': AppTheme.accentGold},
      {'type': 'URLs', 'count': 28, 'color': AppTheme.accentTeal},
      {'type': 'Files', 'count': 15, 'color': AppTheme.statusProcessing},
      {'type': 'Voice', 'count': 8, 'color': AppTheme.accentCopper},
      {'type': 'Images', 'count': 4, 'color': Colors.purple},
    ];

    final total = types.fold<int>(0, (sum, t) => sum + (t['count'] as int));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.cardDark.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.pieChart, color: AppTheme.accentGold, size: 20),
              const SizedBox(width: 8),
              Text(
                'Memory Types',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Donut chart placeholder
          Center(
            child: SizedBox(
              height: 180,
              width: 180,
              child: CustomPaint(
                painter: _DonutChartPainter(
                  types.map((t) => MapEntry(
                    t['color'] as Color,
                    (t['count'] as int) / math.max(total, 1),
                  )).toList(),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        '$total',
                        style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'memories',
                        style: TextStyle(
                          color: AppTheme.textMutedDark,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ).animate().scale(delay: 900.ms, duration: 500.ms),
          const SizedBox(height: 20),
          
          // Legend
          Wrap(
            spacing: 16,
            runSpacing: 8,
            children: types.map((t) {
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: t['color'] as Color,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${t['type']} (${t['count']})',
                    style: TextStyle(
                      color: AppTheme.textSecondaryDark,
                      fontSize: 12,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 850.ms).slideY(begin: 0.1);
  }

  Widget _buildMemoryGrowth(Map<String, dynamic> documents) {
    final growth = documents['growth'] ?? 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentGold.withOpacity(0.15),
            AppTheme.accentTeal.withOpacity(0.15),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentGold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(LucideIcons.trendingUp, color: AppTheme.accentGold, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Memory Growth',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  'Your memory library is growing steadily. Keep adding valuable content!',
                  style: TextStyle(
                    color: AppTheme.textSecondaryDark,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Text(
                  '${growth.toStringAsFixed(0)}%',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    color: AppTheme.accentGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'this month',
                  style: TextStyle(
                    color: AppTheme.textMutedDark,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.1);
  }
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String trend;
  final Color color;
  final int delay;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.trend,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              Icon(LucideIcons.arrowUpRight, color: color, size: 16),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(color: AppTheme.textMutedDark, fontSize: 12),
          ),
          Text(
            trend,
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).scale(begin: const Offset(0.9, 0.9));
  }
}

// Insight Card Widget
class _InsightCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final String priority;
  final int delay;

  const _InsightCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.priority,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final priorityColor = priority == 'high'
        ? AppTheme.statusFailed
        : priority == 'medium'
            ? AppTheme.statusWarning
            : AppTheme.statusReady;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: priorityColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    color: AppTheme.textSecondaryDark,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(begin: 0.1);
  }
}

// Activity Bar Widget
class _ActivityBar extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;
  final Color color;
  final int delay;

  const _ActivityBar({
    required this.label,
    required this.value,
    required this.maxValue,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final progress = value / math.max(maxValue, 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(color: AppTheme.textSecondaryDark, fontSize: 13),
            ),
            Text(
              '$value',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.primaryDark,
            valueColor: AlwaysStoppedAnimation(color),
            minHeight: 8,
          ),
        ).animate().slideX(begin: -1, delay: Duration(milliseconds: delay), duration: 600.ms),
      ],
    );
  }
}

// Donut Chart Painter
class _DonutChartPainter extends CustomPainter {
  final List<MapEntry<Color, double>> segments;

  _DonutChartPainter(this.segments);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    const strokeWidth = 24.0;
    final rect = Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    double startAngle = -math.pi / 2;

    for (final segment in segments) {
      final sweepAngle = segment.value * 2 * math.pi;
      final paint = Paint()
        ..color = segment.key
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.butt;

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);
      startAngle += sweepAngle;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
