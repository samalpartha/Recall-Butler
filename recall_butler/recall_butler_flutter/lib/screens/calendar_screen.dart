import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../services/calendar_service.dart';

/// Provider for calendar service
final calendarServiceProvider = Provider<CalendarService>((ref) => CalendarService());

/// Provider for connection status
final calendarConnectedProvider = StateProvider<bool>((ref) {
  return ref.watch(calendarServiceProvider).isConnected;
});

/// Provider for upcoming events
final upcomingEventsProvider = FutureProvider<List<CalendarEvent>>((ref) async {
  final calendar = ref.watch(calendarServiceProvider);
  if (!calendar.isConnected) return [];
  return calendar.getUpcomingEvents(days: 7);
});

/// Calendar Integration Screen
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  bool _isConnecting = false;

  @override
  Widget build(BuildContext context) {
    final calendar = ref.watch(calendarServiceProvider);
    final isConnected = calendar.isConnected;
    final events = ref.watch(upcomingEventsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(LucideIcons.calendar, color: AppTheme.accentGold, size: 24),
            const SizedBox(width: 12),
            const Text('Calendar'),
          ],
        ),
        actions: [
          if (isConnected)
            IconButton(
              icon: const Icon(LucideIcons.refreshCw),
              onPressed: () => ref.invalidate(upcomingEventsProvider),
            ),
        ],
      ),
      body: isConnected
          ? _buildConnectedView(events)
          : _buildConnectView(),
    );
  }

  Widget _buildConnectView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const SizedBox(height: 40),
          
          // Hero illustration
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  AppTheme.accentGold.withOpacity(0.15),
                  Colors.transparent,
                ],
              ),
            ),
            child: Icon(
              LucideIcons.calendarDays,
              size: 100,
              color: AppTheme.accentGold,
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
          
          const SizedBox(height: 32),
          
          Text(
            'Connect Your Calendar',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 100.ms),
          
          const SizedBox(height: 12),
          
          Text(
            'Sync your calendar to get smart reminders before meetings and auto-suggest relevant memories.',
            style: TextStyle(
              color: AppTheme.textSecondaryDark,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 200.ms),
          
          const SizedBox(height: 48),
          
          // Google Calendar button
          _CalendarConnectButton(
            iconWidget: const FaIcon(FontAwesomeIcons.google, size: 24, color: Colors.white),
            title: 'Google Calendar',
            subtitle: 'Connect your Google account',
            isLoading: _isConnecting,
            onTap: () => _connectCalendar('google'),
          ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
          
          const SizedBox(height: 16),
          
          // Apple Calendar button
          _CalendarConnectButton(
            iconWidget: const FaIcon(FontAwesomeIcons.apple, size: 28, color: Colors.white),
            title: 'Apple Calendar',
            subtitle: 'Connect your iCloud calendar',
            isLoading: _isConnecting,
            onTap: () => _connectCalendar('apple'),
          ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
          
          const SizedBox(height: 48),
          
          // Features list
          _buildFeaturesList(),
        ],
      ),
    );
  }

  Widget _buildFeaturesList() {
    final features = [
      {'icon': LucideIcons.bell, 'text': 'Get reminders before meetings'},
      {'icon': LucideIcons.search, 'text': 'Auto-suggest relevant memories'},
      {'icon': LucideIcons.refreshCw, 'text': 'Sync reminders to calendar'},
      {'icon': LucideIcons.brain, 'text': 'AI-powered meeting prep'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'What you\'ll get:',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 16),
        ...features.asMap().entries.map((entry) {
          final feature = entry.value;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    feature['icon'] as IconData,
                    color: AppTheme.accentGold,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  feature['text'] as String,
                  style: TextStyle(color: AppTheme.textSecondaryDark),
                ),
              ],
            ),
          ).animate().fadeIn(delay: Duration(milliseconds: 500 + entry.key * 100));
        }),
      ],
    );
  }

  Widget _buildConnectedView(AsyncValue<List<CalendarEvent>> events) {
    final calendar = ref.watch(calendarServiceProvider);

    return Column(
      children: [
        // Connection status banner
        Container(
          padding: const EdgeInsets.all(16),
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppTheme.statusReady.withOpacity(0.15),
                AppTheme.accentTeal.withOpacity(0.15),
              ],
            ),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.statusReady.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.statusReady.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: FaIcon(
                  calendar.connectedProvider == 'google' 
                    ? FontAwesomeIcons.google 
                    : FontAwesomeIcons.apple,
                  color: AppTheme.statusReady,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Connected to ${calendar.connectedProvider == 'google' ? 'Google' : 'Apple'} Calendar',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                    Text(
                      'Syncing events and reminders',
                      style: TextStyle(
                        color: AppTheme.textMutedDark,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _disconnect,
                child: Text(
                  'Disconnect',
                  style: TextStyle(color: AppTheme.statusFailed),
                ),
              ),
            ],
          ),
        ).animate().fadeIn().slideY(begin: -0.1),

        // Events list
        Expanded(
          child: events.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (err, _) => Center(
              child: Text('Error: $err', style: TextStyle(color: AppTheme.statusFailed)),
            ),
            data: (eventList) => eventList.isEmpty
                ? _buildNoEventsView()
                : _buildEventsList(eventList),
          ),
        ),
      ],
    );
  }

  Widget _buildNoEventsView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.calendarCheck,
            size: 64,
            color: AppTheme.textMutedDark,
          ),
          const SizedBox(height: 16),
          Text(
            'No upcoming events',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Your calendar is clear for the next 7 days',
            style: TextStyle(color: AppTheme.textSecondaryDark),
          ),
        ],
      ),
    );
  }

  Widget _buildEventsList(List<CalendarEvent> events) {
    // Group events by date
    final groupedEvents = <String, List<CalendarEvent>>{};
    for (final event in events) {
      final dateKey = DateFormat('yyyy-MM-dd').format(event.startTime);
      groupedEvents.putIfAbsent(dateKey, () => []);
      groupedEvents[dateKey]!.add(event);
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: groupedEvents.length,
      itemBuilder: (context, index) {
        final dateKey = groupedEvents.keys.elementAt(index);
        final dayEvents = groupedEvents[dateKey]!;
        final date = DateTime.parse(dateKey);
        final isToday = DateFormat('yyyy-MM-dd').format(DateTime.now()) == dateKey;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isToday 
                        ? AppTheme.accentGold.withOpacity(0.2)
                        : AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isToday 
                        ? 'Today'
                        : DateFormat('EEEE, MMM d').format(date),
                      style: TextStyle(
                        color: isToday ? AppTheme.accentGold : AppTheme.textSecondaryDark,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${dayEvents.length} event${dayEvents.length > 1 ? 's' : ''}',
                    style: TextStyle(
                      color: AppTheme.textMutedDark,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            ...dayEvents.asMap().entries.map((entry) {
              return _EventCard(
                event: entry.value,
                delay: index * 100 + entry.key * 50,
              );
            }),
          ],
        );
      },
    );
  }

  Future<void> _connectCalendar(String provider) async {
    setState(() => _isConnecting = true);
    
    try {
      final calendar = ref.read(calendarServiceProvider);
      bool success;
      
      if (provider == 'google') {
        success = await calendar.connectGoogleCalendar();
      } else {
        success = await calendar.connectAppleCalendar();
      }
      
      if (success) {
        ref.invalidate(upcomingEventsProvider);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Connected to ${provider == 'google' ? 'Google' : 'Apple'} Calendar!'),
              backgroundColor: AppTheme.statusReady,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Connection failed: $e'),
            backgroundColor: AppTheme.statusFailed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConnecting = false);
      }
    }
  }

  Future<void> _disconnect() async {
    final calendar = ref.read(calendarServiceProvider);
    await calendar.disconnect();
    ref.invalidate(upcomingEventsProvider);
    setState(() {});
  }
}

class _CalendarConnectButton extends StatelessWidget {
  final Widget iconWidget;
  final String title;
  final String subtitle;
  final bool isLoading;
  final VoidCallback onTap;

  const _CalendarConnectButton({
    required this.iconWidget,
    required this.title,
    required this.subtitle,
    required this.isLoading,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cardDark,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isLoading ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.cardDark),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: iconWidget),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: AppTheme.textMutedDark,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                Icon(
                  LucideIcons.chevronRight,
                  color: AppTheme.textMutedDark,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EventCard extends StatelessWidget {
  final CalendarEvent event;
  final int delay;

  const _EventCard({
    required this.event,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final timeFormat = DateFormat('h:mm a');
    final isNow = DateTime.now().isAfter(event.startTime) && 
                  DateTime.now().isBefore(event.endTime);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNow 
            ? AppTheme.accentGold.withOpacity(0.5)
            : Colors.transparent,
          width: isNow ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time column
          SizedBox(
            width: 70,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.isAllDay ? 'All day' : timeFormat.format(event.startTime),
                  style: TextStyle(
                    color: isNow ? AppTheme.accentGold : AppTheme.textPrimaryDark,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (!event.isAllDay)
                  Text(
                    timeFormat.format(event.endTime),
                    style: TextStyle(
                      color: AppTheme.textMutedDark,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          
          // Divider
          Container(
            width: 3,
            height: 50,
            margin: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: isNow ? AppTheme.accentGold : AppTheme.accentTeal,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          // Event details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (isNow)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        margin: const EdgeInsets.only(right: 8),
                        decoration: BoxDecoration(
                          color: AppTheme.accentGold,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'NOW',
                          style: TextStyle(
                            color: AppTheme.primaryDark,
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Expanded(
                      child: Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleSmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (event.location != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.mapPin,
                        size: 12,
                        color: AppTheme.textMutedDark,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location!,
                          style: TextStyle(
                            color: AppTheme.textMutedDark,
                            fontSize: 12,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                if (event.attendees.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        LucideIcons.users,
                        size: 12,
                        color: AppTheme.textMutedDark,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.attendees.length} attendee${event.attendees.length > 1 ? 's' : ''}',
                        style: TextStyle(
                          color: AppTheme.textMutedDark,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          
          // Action button
          IconButton(
            icon: Icon(
              LucideIcons.search,
              size: 18,
              color: AppTheme.accentTeal,
            ),
            onPressed: () {
              // Search for related documents
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Searching for memories related to "${event.title}"...'),
                  backgroundColor: AppTheme.cardDark,
                ),
              );
            },
            tooltip: 'Find related memories',
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay)).slideX(begin: 0.05);
  }
}
