import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:recall_butler_client/recall_butler_client.dart';

import '../theme/app_theme.dart';
import '../providers/suggestions_provider.dart';
import '../providers/documents_provider.dart';
import '../widgets/suggestion_card.dart';
import '../services/notification_service.dart';

/// Activity screen - Suggestions, reminders, and recent activity
class ActivityScreen extends ConsumerWidget {
  const ActivityScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingSuggestions = ref.watch(pendingSuggestionsProvider);
    final executedSuggestions = ref.watch(executedSuggestionsProvider);
    final recentActivity = ref.watch(recentActivityProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: Row(
              children: [
                const Icon(LucideIcons.bellRing, size: 24),
                const SizedBox(width: 12),
                const Text('Activity'),
              ],
            ).animate().fadeIn(duration: 300.ms),
          ),

          // Pending Suggestions Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.accentGold.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.lightbulb,
                      size: 20,
                      color: AppTheme.accentGold,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Butler Suggestions',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ).animate().fadeIn(delay: 100.ms),
            ),
          ),

          // Pending suggestions list
          pendingSuggestions.when(
            data: (suggestions) {
              if (suggestions.isEmpty) {
                return SliverToBoxAdapter(
                  child: _EmptySuggestions()
                      .animate()
                      .fadeIn(delay: 200.ms),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: SuggestionCard(
                          suggestion: suggestions[index],
                          onApprove: () async {
                            await ref.read(suggestionsProvider.notifier).approve(suggestions[index].id!);
                            ref.invalidate(pendingSuggestionsProvider);
                            ref.invalidate(executedSuggestionsProvider);
                            ref.invalidate(recentActivityProvider);
                            ref.invalidate(pendingSuggestionsCountProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('✓ Suggestion approved!'),
                                  backgroundColor: AppTheme.statusReady,
                                ),
                              );
                            }
                          },
                          onDismiss: () async {
                            await ref.read(suggestionsProvider.notifier).dismiss(suggestions[index].id!);
                            ref.invalidate(pendingSuggestionsProvider);
                            ref.invalidate(executedSuggestionsProvider);
                            ref.invalidate(recentActivityProvider);
                            ref.invalidate(pendingSuggestionsCountProvider);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Suggestion dismissed'),
                                  backgroundColor: AppTheme.textMutedDark,
                                ),
                              );
                            }
                          },
                        ).animate()
                            .fadeIn(delay: (200 + index * 100).ms)
                            .slideX(begin: 0.1),
                      );
                    },
                    childCount: suggestions.length,
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
            error: (e, _) => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Text('Error loading suggestions: $e'),
              ),
            ),
          ),

          // Scheduled Actions Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.statusProcessing.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.clock,
                      size: 20,
                      color: AppTheme.statusProcessing,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Scheduled',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ).animate().fadeIn(delay: 300.ms),
            ),
          ),

          // Executed/scheduled suggestions
          executedSuggestions.when(
            data: (suggestions) {
              if (suggestions.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            LucideIcons.calendar,
                            color: AppTheme.textMutedDark,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            'No scheduled actions yet',
                            style: TextStyle(color: AppTheme.textMutedDark),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 350.ms),
                  ),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final suggestion = suggestions[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _ScheduledItem(suggestion: suggestion)
                            .animate()
                            .fadeIn(delay: (400 + index * 50).ms),
                      );
                    },
                    childCount: suggestions.length,
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
          ),

          // Recent Activity Section
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.statusReady.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      LucideIcons.activity,
                      size: 20,
                      color: AppTheme.statusReady,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Recent Activity',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ).animate().fadeIn(delay: 400.ms),
            ),
          ),

          // Activity list
          recentActivity.when(
            data: (activities) {
              if (activities.isEmpty) {
                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'No recent activity',
                      style: TextStyle(color: AppTheme.textMutedDark),
                    ),
                  ).animate().fadeIn(delay: 450.ms),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return _ActivityItem(activity: activities[index])
                          .animate()
                          .fadeIn(delay: (500 + index * 50).ms);
                    },
                    childCount: activities.length,
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}

class _EmptySuggestions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentGold.withOpacity(0.1),
            AppTheme.accentCopper.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accentGold.withOpacity(0.2),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.checkCircle,
              size: 32,
              color: AppTheme.accentGold,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'All caught up!',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'No pending suggestions at the moment',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ScheduledItem extends StatelessWidget {
  final Suggestion suggestion;

  const _ScheduledItem({required this.suggestion});

  @override
  Widget build(BuildContext context) {
    final scheduledAt = suggestion.scheduledAt;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getTypeColor(suggestion.type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _getTypeIcon(suggestion.type),
              size: 20,
              color: _getTypeColor(suggestion.type),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  suggestion.title,
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                if (scheduledAt != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    'Scheduled ${timeago.format(scheduledAt)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppTheme.statusProcessing.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              suggestion.state,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: AppTheme.statusProcessing,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon(String? type) {
    switch (type) {
      case 'reminder':
        return LucideIcons.bell;
      case 'followup':
        return LucideIcons.reply;
      case 'checkin':
        return LucideIcons.plane;
      default:
        return LucideIcons.clipboard;
    }
  }

  Color _getTypeColor(String? type) {
    switch (type) {
      case 'reminder':
        return AppTheme.accentGold;
      case 'followup':
        return AppTheme.statusProcessing;
      case 'checkin':
        return AppTheme.accentCopper;
      default:
        return AppTheme.statusReady;
    }
  }
}

class _ActivityItem extends StatelessWidget {
  final Suggestion activity;

  const _ActivityItem({required this.activity});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: _getActivityColor(activity.type),
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity.title,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 2),
                Text(
                  activity.state,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _getActivityColor(String? type) {
    switch (type) {
      case 'reminder':
        return AppTheme.statusProcessing;
      case 'calendar':
        return AppTheme.statusReady;
      case 'followup':
        return AppTheme.accentGold;
      default:
        return AppTheme.textMutedDark;
    }
  }
}
