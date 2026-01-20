import 'package:flutter/foundation.dart';

/// Smart reminder model with context awareness
class SmartReminder {
  final String id;
  final String title;
  final String description;
  final DateTime scheduledAt;
  final ReminderTrigger trigger;
  final ReminderPriority priority;
  final int? documentId;
  final String? documentTitle;
  final Map<String, dynamic>? context;
  final bool isRecurring;
  final String? recurrenceRule;
  final bool isCompleted;
  final DateTime? completedAt;

  SmartReminder({
    required this.id,
    required this.title,
    required this.description,
    required this.scheduledAt,
    this.trigger = ReminderTrigger.time,
    this.priority = ReminderPriority.normal,
    this.documentId,
    this.documentTitle,
    this.context,
    this.isRecurring = false,
    this.recurrenceRule,
    this.isCompleted = false,
    this.completedAt,
  });

  SmartReminder copyWith({
    String? title,
    String? description,
    DateTime? scheduledAt,
    ReminderTrigger? trigger,
    ReminderPriority? priority,
    bool? isCompleted,
    DateTime? completedAt,
  }) {
    return SmartReminder(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      scheduledAt: scheduledAt ?? this.scheduledAt,
      trigger: trigger ?? this.trigger,
      priority: priority ?? this.priority,
      documentId: documentId,
      documentTitle: documentTitle,
      context: context,
      isRecurring: isRecurring,
      recurrenceRule: recurrenceRule,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'scheduledAt': scheduledAt.toIso8601String(),
    'trigger': trigger.name,
    'priority': priority.name,
    'documentId': documentId,
    'documentTitle': documentTitle,
    'context': context,
    'isRecurring': isRecurring,
    'recurrenceRule': recurrenceRule,
    'isCompleted': isCompleted,
    'completedAt': completedAt?.toIso8601String(),
  };

  factory SmartReminder.fromMap(Map<String, dynamic> map) => SmartReminder(
    id: map['id'],
    title: map['title'],
    description: map['description'],
    scheduledAt: DateTime.parse(map['scheduledAt']),
    trigger: ReminderTrigger.values.firstWhere(
      (t) => t.name == map['trigger'],
      orElse: () => ReminderTrigger.time,
    ),
    priority: ReminderPriority.values.firstWhere(
      (p) => p.name == map['priority'],
      orElse: () => ReminderPriority.normal,
    ),
    documentId: map['documentId'],
    documentTitle: map['documentTitle'],
    context: map['context'],
    isRecurring: map['isRecurring'] ?? false,
    recurrenceRule: map['recurrenceRule'],
    isCompleted: map['isCompleted'] ?? false,
    completedAt: map['completedAt'] != null 
      ? DateTime.parse(map['completedAt']) 
      : null,
  );
}

enum ReminderTrigger {
  time,        // Standard time-based
  location,    // When arriving/leaving a location
  context,     // Based on activity (e.g., "when I open email")
  pattern,     // Based on learned patterns
  meeting,     // Before a calendar meeting
}

enum ReminderPriority {
  low,
  normal,
  high,
  urgent,
}

/// Smart reminder service with context awareness and pattern learning
class SmartReminderService {
  static final SmartReminderService _instance = SmartReminderService._internal();
  factory SmartReminderService() => _instance;
  SmartReminderService._internal();

  final List<SmartReminder> _reminders = [];
  final Map<String, int> _activityPatterns = {};
  String? _currentLocation;
  String? _currentActivity;

  List<SmartReminder> get reminders => List.unmodifiable(_reminders);
  List<SmartReminder> get pendingReminders => 
    _reminders.where((r) => !r.isCompleted).toList();
  List<SmartReminder> get completedReminders => 
    _reminders.where((r) => r.isCompleted).toList();

  /// Initialize with sample data
  void initialize() {
    _reminders.addAll(_generateSampleReminders());
    debugPrint('🔔 Smart Reminder Service initialized with ${_reminders.length} reminders');
  }

  /// Create a smart reminder
  Future<SmartReminder> createReminder({
    required String title,
    required String description,
    required DateTime scheduledAt,
    ReminderTrigger trigger = ReminderTrigger.time,
    ReminderPriority priority = ReminderPriority.normal,
    int? documentId,
    String? documentTitle,
    Map<String, dynamic>? context,
    bool isRecurring = false,
    String? recurrenceRule,
  }) async {
    final reminder = SmartReminder(
      id: 'rem_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      scheduledAt: scheduledAt,
      trigger: trigger,
      priority: priority,
      documentId: documentId,
      documentTitle: documentTitle,
      context: context,
      isRecurring: isRecurring,
      recurrenceRule: recurrenceRule,
    );

    _reminders.add(reminder);
    _reminders.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
    
    debugPrint('🔔 Created reminder: $title at ${scheduledAt.toIso8601String()}');
    return reminder;
  }

  /// Create a location-based reminder
  Future<SmartReminder> createLocationReminder({
    required String title,
    required String description,
    required String location,
    bool onArrival = true,
    int? documentId,
    String? documentTitle,
  }) async {
    return createReminder(
      title: title,
      description: description,
      scheduledAt: DateTime.now().add(const Duration(days: 365)), // Far future
      trigger: ReminderTrigger.location,
      documentId: documentId,
      documentTitle: documentTitle,
      context: {
        'location': location,
        'onArrival': onArrival,
      },
    );
  }

  /// Create a meeting prep reminder
  Future<SmartReminder> createMeetingReminder({
    required String meetingTitle,
    required DateTime meetingTime,
    required List<int> relatedDocumentIds,
    int minutesBefore = 15,
  }) async {
    return createReminder(
      title: '📅 Prep for: $meetingTitle',
      description: 'Review ${relatedDocumentIds.length} related memories before your meeting',
      scheduledAt: meetingTime.subtract(Duration(minutes: minutesBefore)),
      trigger: ReminderTrigger.meeting,
      priority: ReminderPriority.high,
      context: {
        'meetingTitle': meetingTitle,
        'meetingTime': meetingTime.toIso8601String(),
        'relatedDocuments': relatedDocumentIds,
      },
    );
  }

  /// Create a pattern-based reminder (learns from user behavior)
  Future<SmartReminder?> suggestPatternReminder({
    required int documentId,
    required String documentTitle,
  }) async {
    // Analyze when user typically reviews similar content
    final bestTime = _predictBestReminderTime();
    
    if (bestTime != null) {
      return createReminder(
        title: '💡 Review: $documentTitle',
        description: 'Based on your patterns, this might be a good time to review',
        scheduledAt: bestTime,
        trigger: ReminderTrigger.pattern,
        documentId: documentId,
        documentTitle: documentTitle,
        context: {
          'suggestedBy': 'pattern_learning',
          'confidence': 0.75,
        },
      );
    }
    return null;
  }

  /// Mark reminder as completed
  Future<void> completeReminder(String id) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      _reminders[index] = _reminders[index].copyWith(
        isCompleted: true,
        completedAt: DateTime.now(),
      );
      debugPrint('✅ Completed reminder: ${_reminders[index].title}');
    }
  }

  /// Snooze a reminder
  Future<SmartReminder?> snoozeReminder(String id, Duration duration) async {
    final index = _reminders.indexWhere((r) => r.id == id);
    if (index != -1) {
      final original = _reminders[index];
      _reminders[index] = original.copyWith(
        scheduledAt: DateTime.now().add(duration),
      );
      debugPrint('⏰ Snoozed reminder: ${original.title} for ${duration.inMinutes} minutes');
      return _reminders[index];
    }
    return null;
  }

  /// Delete a reminder
  Future<void> deleteReminder(String id) async {
    _reminders.removeWhere((r) => r.id == id);
    debugPrint('🗑️ Deleted reminder: $id');
  }

  /// Update location (for location-based reminders)
  void updateLocation(String location) {
    final previousLocation = _currentLocation;
    _currentLocation = location;
    
    // Check for location-triggered reminders
    if (previousLocation != location) {
      _checkLocationReminders(location, isArrival: true);
    }
  }

  /// Update current activity (for context-based reminders)
  void updateActivity(String activity) {
    _currentActivity = activity;
    _recordActivityPattern(activity);
    _checkContextReminders(activity);
  }

  /// Get reminders due soon (within next hour)
  List<SmartReminder> getDueReminders() {
    final now = DateTime.now();
    final soon = now.add(const Duration(hours: 1));
    
    return _reminders.where((r) {
      return !r.isCompleted &&
             r.scheduledAt.isAfter(now) &&
             r.scheduledAt.isBefore(soon);
    }).toList();
  }

  /// Get reminders for today
  List<SmartReminder> getTodayReminders() {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    
    return _reminders.where((r) {
      return r.scheduledAt.isAfter(startOfDay) &&
             r.scheduledAt.isBefore(endOfDay);
    }).toList()
      ..sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
  }

  /// Get smart suggestions based on context
  List<Map<String, dynamic>> getSmartSuggestions() {
    final suggestions = <Map<String, dynamic>>[];
    final now = DateTime.now();
    
    // Suggest morning review
    if (now.hour >= 8 && now.hour <= 10) {
      suggestions.add({
        'type': 'morning_review',
        'icon': '☀️',
        'title': 'Morning Review',
        'description': 'Start your day by reviewing yesterday\'s memories',
        'action': 'review_recent',
      });
    }
    
    // Suggest end-of-day capture
    if (now.hour >= 17 && now.hour <= 19) {
      suggestions.add({
        'type': 'daily_capture',
        'icon': '📝',
        'title': 'Daily Capture',
        'description': 'Capture today\'s important moments before you forget',
        'action': 'quick_capture',
      });
    }
    
    // Suggest weekly review on Sundays
    if (now.weekday == DateTime.sunday) {
      suggestions.add({
        'type': 'weekly_review',
        'icon': '📊',
        'title': 'Weekly Review',
        'description': 'Review your week and plan ahead',
        'action': 'weekly_summary',
      });
    }
    
    // Suggest based on pending reminders
    final pending = pendingReminders.length;
    if (pending > 5) {
      suggestions.add({
        'type': 'clear_backlog',
        'icon': '📋',
        'title': 'Clear Your Backlog',
        'description': 'You have $pending pending reminders to review',
        'action': 'view_reminders',
      });
    }
    
    return suggestions;
  }

  // Private methods

  void _checkLocationReminders(String location, {required bool isArrival}) {
    for (final reminder in _reminders) {
      if (reminder.trigger == ReminderTrigger.location &&
          !reminder.isCompleted &&
          reminder.context != null) {
        final reminderLocation = reminder.context!['location'] as String?;
        final onArrival = reminder.context!['onArrival'] as bool? ?? true;
        
        if (reminderLocation == location && onArrival == isArrival) {
          debugPrint('📍 Location reminder triggered: ${reminder.title}');
          // In production, this would show a notification
        }
      }
    }
  }

  void _checkContextReminders(String activity) {
    for (final reminder in _reminders) {
      if (reminder.trigger == ReminderTrigger.context &&
          !reminder.isCompleted &&
          reminder.context != null) {
        final triggerActivity = reminder.context!['activity'] as String?;
        
        if (triggerActivity == activity) {
          debugPrint('🎯 Context reminder triggered: ${reminder.title}');
          // In production, this would show a notification
        }
      }
    }
  }

  void _recordActivityPattern(String activity) {
    final hour = DateTime.now().hour;
    final key = '${activity}_$hour';
    _activityPatterns[key] = (_activityPatterns[key] ?? 0) + 1;
  }

  DateTime? _predictBestReminderTime() {
    // Simple pattern prediction - find most active hour
    if (_activityPatterns.isEmpty) {
      // Default to 9 AM tomorrow
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, 9, 0);
    }
    
    // Find hour with most activity
    int bestHour = 9;
    int maxCount = 0;
    
    for (var hour = 8; hour <= 20; hour++) {
      int count = 0;
      _activityPatterns.forEach((key, value) {
        if (key.endsWith('_$hour')) count += value;
      });
      if (count > maxCount) {
        maxCount = count;
        bestHour = hour;
      }
    }
    
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return DateTime(tomorrow.year, tomorrow.month, tomorrow.day, bestHour, 0);
  }

  List<SmartReminder> _generateSampleReminders() {
    final now = DateTime.now();
    return [
      SmartReminder(
        id: 'rem_sample_1',
        title: '📚 Review meeting notes',
        description: 'Review notes from yesterday\'s project meeting',
        scheduledAt: now.add(const Duration(hours: 1)),
        trigger: ReminderTrigger.time,
        priority: ReminderPriority.high,
        documentId: 1,
        documentTitle: 'Project Meeting Notes',
      ),
      SmartReminder(
        id: 'rem_sample_2',
        title: '💡 Follow up on idea',
        description: 'Research the AI integration concept you saved',
        scheduledAt: now.add(const Duration(hours: 3)),
        trigger: ReminderTrigger.time,
        priority: ReminderPriority.normal,
        documentId: 2,
        documentTitle: 'AI Integration Ideas',
      ),
      SmartReminder(
        id: 'rem_sample_3',
        title: '📍 Check grocery list',
        description: 'Review your shopping list when you arrive',
        scheduledAt: now.add(const Duration(days: 365)),
        trigger: ReminderTrigger.location,
        priority: ReminderPriority.normal,
        context: {
          'location': 'Grocery Store',
          'onArrival': true,
        },
      ),
      SmartReminder(
        id: 'rem_sample_4',
        title: '📅 Prep for client call',
        description: 'Review client history before the call',
        scheduledAt: now.add(const Duration(days: 1, hours: 9)),
        trigger: ReminderTrigger.meeting,
        priority: ReminderPriority.high,
        context: {
          'meetingTitle': 'Client Call - Acme Corp',
          'relatedDocuments': [3, 4, 5],
        },
      ),
      SmartReminder(
        id: 'rem_sample_5',
        title: '🔄 Weekly review',
        description: 'Review and organize this week\'s memories',
        scheduledAt: _getNextSunday(),
        trigger: ReminderTrigger.pattern,
        priority: ReminderPriority.normal,
        isRecurring: true,
        recurrenceRule: 'WEEKLY',
      ),
    ];
  }

  DateTime _getNextSunday() {
    final now = DateTime.now();
    final daysUntilSunday = (DateTime.sunday - now.weekday) % 7;
    final nextSunday = now.add(Duration(days: daysUntilSunday == 0 ? 7 : daysUntilSunday));
    return DateTime(nextSunday.year, nextSunday.month, nextSunday.day, 10, 0);
  }
}
