import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../services/smart_reminder_service.dart';

/// Provider for smart reminder service
final smartReminderServiceProvider = Provider<SmartReminderService>((ref) {
  final service = SmartReminderService();
  service.initialize();
  return service;
});

/// Provider for pending reminders
final pendingRemindersProvider = Provider<List<SmartReminder>>((ref) {
  return ref.watch(smartReminderServiceProvider).pendingReminders;
});

/// Provider for today's reminders
final todayRemindersProvider = Provider<List<SmartReminder>>((ref) {
  return ref.watch(smartReminderServiceProvider).getTodayReminders();
});

/// Provider for smart suggestions
final smartSuggestionsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return ref.watch(smartReminderServiceProvider).getSmartSuggestions();
});

/// Smart Reminders Screen
class SmartRemindersScreen extends ConsumerStatefulWidget {
  const SmartRemindersScreen({super.key});

  @override
  ConsumerState<SmartRemindersScreen> createState() => _SmartRemindersScreenState();
}

class _SmartRemindersScreenState extends ConsumerState<SmartRemindersScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = ref.watch(smartSuggestionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(LucideIcons.bellRing, color: AppTheme.accentGold, size: 24),
            const SizedBox(width: 12),
            const Text('Smart Reminders'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppTheme.accentGold,
          labelColor: AppTheme.accentGold,
          unselectedLabelColor: AppTheme.textMutedDark,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Upcoming'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: Column(
        children: [
          // Smart suggestions banner
          if (suggestions.isNotEmpty)
            _buildSuggestionsBanner(suggestions),
          
          // Tab content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildTodayTab(),
                _buildUpcomingTab(),
                _buildCompletedTab(),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'smart_reminder_fab',
        onPressed: () => _showCreateReminderSheet(context),
        icon: const Icon(LucideIcons.plus),
        label: const Text('New Reminder'),
        backgroundColor: AppTheme.accentGold,
        foregroundColor: AppTheme.primaryDark,
      ),
    );
  }

  Widget _buildSuggestionsBanner(List<Map<String, dynamic>> suggestions) {
    return Container(
      height: 100,
      margin: const EdgeInsets.all(16),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: suggestions.length,
        itemBuilder: (context, index) {
          final suggestion = suggestions[index];
          return _SuggestionCard(
            icon: suggestion['icon'] ?? '💡',
            title: suggestion['title'] ?? '',
            description: suggestion['description'] ?? '',
            delay: index * 100,
          );
        },
      ),
    ).animate().fadeIn().slideY(begin: -0.1);
  }

  Widget _buildTodayTab() {
    final todayReminders = ref.watch(todayRemindersProvider);

    if (todayReminders.isEmpty) {
      return _buildEmptyState(
        icon: LucideIcons.calendarCheck,
        title: 'No reminders today',
        subtitle: 'Enjoy your free day or create a new reminder',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: todayReminders.length,
      itemBuilder: (context, index) {
        return _ReminderCard(
          reminder: todayReminders[index],
          onComplete: () => _completeReminder(todayReminders[index].id),
          onSnooze: () => _snoozeReminder(todayReminders[index].id),
          onDelete: () => _deleteReminder(todayReminders[index].id),
          delay: index * 100,
        );
      },
    );
  }

  Widget _buildUpcomingTab() {
    final allReminders = ref.watch(pendingRemindersProvider);
    final today = DateTime.now();
    final startOfTomorrow = DateTime(today.year, today.month, today.day + 1);
    
    final upcomingReminders = allReminders
        .where((r) => r.scheduledAt.isAfter(startOfTomorrow))
        .toList();

    if (upcomingReminders.isEmpty) {
      return _buildEmptyState(
        icon: LucideIcons.calendar,
        title: 'No upcoming reminders',
        subtitle: 'Plan ahead by creating reminders for the future',
      );
    }

    // Group by date
    final grouped = <String, List<SmartReminder>>{};
    for (final reminder in upcomingReminders) {
      final dateKey = DateFormat('yyyy-MM-dd').format(reminder.scheduledAt);
      grouped.putIfAbsent(dateKey, () => []);
      grouped[dateKey]!.add(reminder);
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: grouped.length,
      itemBuilder: (context, index) {
        final dateKey = grouped.keys.elementAt(index);
        final reminders = grouped[dateKey]!;
        final date = DateTime.parse(dateKey);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                DateFormat('EEEE, MMM d').format(date),
                style: TextStyle(
                  color: AppTheme.textMutedDark,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
            ...reminders.asMap().entries.map((entry) {
              return _ReminderCard(
                reminder: entry.value,
                onComplete: () => _completeReminder(entry.value.id),
                onSnooze: () => _snoozeReminder(entry.value.id),
                onDelete: () => _deleteReminder(entry.value.id),
                delay: index * 100 + entry.key * 50,
              );
            }),
          ],
        );
      },
    );
  }

  Widget _buildCompletedTab() {
    final completedReminders = ref.watch(smartReminderServiceProvider).completedReminders;

    if (completedReminders.isEmpty) {
      return _buildEmptyState(
        icon: LucideIcons.checkCircle,
        title: 'No completed reminders',
        subtitle: 'Completed reminders will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completedReminders.length,
      itemBuilder: (context, index) {
        final reminder = completedReminders[index];
        return _CompletedReminderCard(
          reminder: reminder,
          delay: index * 50,
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.textMutedDark),
          const SizedBox(height: 16),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(color: AppTheme.textSecondaryDark),
            textAlign: TextAlign.center,
          ),
        ],
      ).animate().fadeIn().scale(begin: const Offset(0.9, 0.9)),
    );
  }

  void _completeReminder(String id) {
    ref.read(smartReminderServiceProvider).completeReminder(id);
    setState(() {});
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Reminder completed! ✓'),
        backgroundColor: AppTheme.statusReady,
      ),
    );
  }

  void _snoozeReminder(String id) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _SnoozeSheet(
        onSnooze: (duration) {
          ref.read(smartReminderServiceProvider).snoozeReminder(id, duration);
          setState(() {});
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Snoozed for ${duration.inMinutes} minutes'),
              backgroundColor: AppTheme.cardDark,
            ),
          );
        },
      ),
    );
  }

  void _deleteReminder(String id) {
    ref.read(smartReminderServiceProvider).deleteReminder(id);
    setState(() {});
  }

  void _showCreateReminderSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CreateReminderSheet(
        onCreate: (title, description, scheduledAt, trigger) async {
          await ref.read(smartReminderServiceProvider).createReminder(
            title: title,
            description: description,
            scheduledAt: scheduledAt,
            trigger: trigger,
          );
          setState(() {});
          if (mounted) Navigator.pop(context);
        },
      ),
    );
  }
}

class _SuggestionCard extends StatelessWidget {
  final String icon;
  final String title;
  final String description;
  final int delay;

  const _SuggestionCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.accentGold.withOpacity(0.15),
            AppTheme.accentTeal.withOpacity(0.15),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: AppTheme.textSecondaryDark,
              fontSize: 12,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(begin: 0.1);
  }
}

class _ReminderCard extends StatelessWidget {
  final SmartReminder reminder;
  final VoidCallback onComplete;
  final VoidCallback onSnooze;
  final VoidCallback onDelete;
  final int delay;

  const _ReminderCard({
    required this.reminder,
    required this.onComplete,
    required this.onSnooze,
    required this.onDelete,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final isOverdue = reminder.scheduledAt.isBefore(DateTime.now());
    final priorityColor = _getPriorityColor(reminder.priority);
    final triggerIcon = _getTriggerIcon(reminder.trigger);

    return Dismissible(
      key: Key(reminder.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: AppTheme.statusReady,
        child: const Icon(LucideIcons.check, color: Colors.white),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: AppTheme.statusFailed,
        child: const Icon(LucideIcons.trash2, color: Colors.white),
      ),
      onDismissed: (direction) {
        if (direction == DismissDirection.startToEnd) {
          onComplete();
        } else {
          onDelete();
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isOverdue 
              ? AppTheme.statusFailed.withOpacity(0.5)
              : priorityColor.withOpacity(0.3),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Priority indicator
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: priorityColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Content
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (isOverdue)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              margin: const EdgeInsets.only(right: 8),
                              decoration: BoxDecoration(
                                color: AppTheme.statusFailed,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'OVERDUE',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          Expanded(
                            child: Text(
                              reminder.title,
                              style: Theme.of(context).textTheme.titleSmall,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reminder.description,
                        style: TextStyle(
                          color: AppTheme.textSecondaryDark,
                          fontSize: 13,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                
                // Actions
                Column(
                  children: [
                    IconButton(
                      icon: Icon(LucideIcons.check, size: 20, color: AppTheme.statusReady),
                      onPressed: onComplete,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(height: 8),
                    IconButton(
                      icon: Icon(LucideIcons.clock, size: 20, color: AppTheme.textMutedDark),
                      onPressed: onSnooze,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            
            // Footer
            Row(
              children: [
                Icon(triggerIcon, size: 14, color: AppTheme.textMutedDark),
                const SizedBox(width: 6),
                Text(
                  timeFormat.format(reminder.scheduledAt),
                  style: TextStyle(
                    color: isOverdue ? AppTheme.statusFailed : AppTheme.textMutedDark,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (reminder.documentTitle != null) ...[
                  const SizedBox(width: 12),
                  Icon(LucideIcons.fileText, size: 14, color: AppTheme.textMutedDark),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      reminder.documentTitle!,
                      style: TextStyle(
                        color: AppTheme.textMutedDark,
                        fontSize: 12,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
                if (reminder.isRecurring) ...[
                  const SizedBox(width: 8),
                  Icon(LucideIcons.repeat, size: 14, color: AppTheme.accentTeal),
                ],
              ],
            ),
          ],
        ),
      ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(begin: 0.05),
    );
  }

  Color _getPriorityColor(ReminderPriority priority) {
    switch (priority) {
      case ReminderPriority.urgent:
        return AppTheme.statusFailed;
      case ReminderPriority.high:
        return AppTheme.accentCopper;
      case ReminderPriority.normal:
        return AppTheme.accentGold;
      case ReminderPriority.low:
        return AppTheme.textMutedDark;
    }
  }

  IconData _getTriggerIcon(ReminderTrigger trigger) {
    switch (trigger) {
      case ReminderTrigger.time:
        return LucideIcons.clock;
      case ReminderTrigger.location:
        return LucideIcons.mapPin;
      case ReminderTrigger.context:
        return LucideIcons.activity;
      case ReminderTrigger.pattern:
        return LucideIcons.brain;
      case ReminderTrigger.meeting:
        return LucideIcons.calendar;
    }
  }
}

class _CompletedReminderCard extends StatelessWidget {
  final SmartReminder reminder;
  final int delay;

  const _CompletedReminderCard({
    required this.reminder,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.cardDark.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(LucideIcons.checkCircle, size: 20, color: AppTheme.statusReady),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  reminder.title,
                  style: TextStyle(
                    color: AppTheme.textSecondaryDark,
                    decoration: TextDecoration.lineThrough,
                  ),
                ),
                if (reminder.completedAt != null)
                  Text(
                    'Completed ${DateFormat('MMM d, h:mm a').format(reminder.completedAt!)}',
                    style: TextStyle(
                      color: AppTheme.textMutedDark,
                      fontSize: 11,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay));
  }
}

class _SnoozeSheet extends StatelessWidget {
  final Function(Duration) onSnooze;

  const _SnoozeSheet({required this.onSnooze});

  @override
  Widget build(BuildContext context) {
    final options = [
      {'label': '15 minutes', 'duration': const Duration(minutes: 15)},
      {'label': '30 minutes', 'duration': const Duration(minutes: 30)},
      {'label': '1 hour', 'duration': const Duration(hours: 1)},
      {'label': '3 hours', 'duration': const Duration(hours: 3)},
      {'label': 'Tomorrow', 'duration': const Duration(days: 1)},
    ];

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Snooze for...',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...options.map((opt) => ListTile(
            leading: const Icon(LucideIcons.clock),
            title: Text(opt['label'] as String),
            onTap: () => onSnooze(opt['duration'] as Duration),
          )),
        ],
      ),
    );
  }
}

class _CreateReminderSheet extends StatefulWidget {
  final Function(String, String, DateTime, ReminderTrigger) onCreate;

  const _CreateReminderSheet({required this.onCreate});

  @override
  State<_CreateReminderSheet> createState() => _CreateReminderSheetState();
}

class _CreateReminderSheetState extends State<_CreateReminderSheet> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _scheduledAt = DateTime.now().add(const Duration(hours: 1));
  ReminderTrigger _trigger = ReminderTrigger.time;

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            'New Reminder',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Title',
              hintText: 'What do you want to remember?',
            ),
          ),
          const SizedBox(height: 16),
          
          TextField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Add more details...',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 16),
          
          // Date/Time picker
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(LucideIcons.calendar),
            title: Text(DateFormat('MMM d, yyyy - h:mm a').format(_scheduledAt)),
            subtitle: const Text('Tap to change'),
            onTap: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _scheduledAt,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
              );
              if (date != null) {
                final time = await showTimePicker(
                  context: context,
                  initialTime: TimeOfDay.fromDateTime(_scheduledAt),
                );
                if (time != null) {
                  setState(() {
                    _scheduledAt = DateTime(
                      date.year, date.month, date.day,
                      time.hour, time.minute,
                    );
                  });
                }
              }
            },
          ),
          const SizedBox(height: 16),
          
          // Trigger type
          DropdownButtonFormField<ReminderTrigger>(
            value: _trigger,
            decoration: const InputDecoration(
              labelText: 'Reminder Type',
            ),
            items: ReminderTrigger.values.map((t) {
              return DropdownMenuItem(
                value: t,
                child: Text(_getTriggerLabel(t)),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null) setState(() => _trigger = value);
            },
          ),
          const SizedBox(height: 24),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                if (_titleController.text.isNotEmpty) {
                  widget.onCreate(
                    _titleController.text,
                    _descriptionController.text,
                    _scheduledAt,
                    _trigger,
                  );
                }
              },
              child: const Text('Create Reminder'),
            ),
          ),
        ],
      ),
    );
  }

  String _getTriggerLabel(ReminderTrigger trigger) {
    switch (trigger) {
      case ReminderTrigger.time:
        return '⏰ Time-based';
      case ReminderTrigger.location:
        return '📍 Location-based';
      case ReminderTrigger.context:
        return '🎯 Context-aware';
      case ReminderTrigger.pattern:
        return '🧠 Pattern-based';
      case ReminderTrigger.meeting:
        return '📅 Meeting prep';
    }
  }
}
