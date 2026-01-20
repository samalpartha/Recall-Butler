import 'package:flutter/foundation.dart';

/// Calendar event model
class CalendarEvent {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final String? location;
  final List<String> attendees;
  final String? recurrence;
  final bool isAllDay;
  final String? calendarId;
  final String? sourceUrl;

  CalendarEvent({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.location,
    this.attendees = const [],
    this.recurrence,
    this.isAllDay = false,
    this.calendarId,
    this.sourceUrl,
  });

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'description': description,
    'startTime': startTime.toIso8601String(),
    'endTime': endTime.toIso8601String(),
    'location': location,
    'attendees': attendees,
    'recurrence': recurrence,
    'isAllDay': isAllDay,
    'calendarId': calendarId,
    'sourceUrl': sourceUrl,
  };

  factory CalendarEvent.fromMap(Map<String, dynamic> map) => CalendarEvent(
    id: map['id'] ?? '',
    title: map['title'] ?? '',
    description: map['description'],
    startTime: DateTime.parse(map['startTime']),
    endTime: DateTime.parse(map['endTime']),
    location: map['location'],
    attendees: List<String>.from(map['attendees'] ?? []),
    recurrence: map['recurrence'],
    isAllDay: map['isAllDay'] ?? false,
    calendarId: map['calendarId'],
    sourceUrl: map['sourceUrl'],
  );
}

/// Calendar integration service
/// Supports Google Calendar, Apple Calendar (via iCal), and local reminders
class CalendarService {
  static final CalendarService _instance = CalendarService._internal();
  factory CalendarService() => _instance;
  CalendarService._internal();

  bool _isConnected = false;
  String? _connectedProvider;
  List<CalendarEvent> _cachedEvents = [];

  bool get isConnected => _isConnected;
  String? get connectedProvider => _connectedProvider;

  /// Connect to Google Calendar
  Future<bool> connectGoogleCalendar() async {
    try {
      // In production, this would use google_sign_in and googleapis packages
      // For demo, we simulate the connection
      debugPrint('🔗 Connecting to Google Calendar...');
      
      // Simulate OAuth flow
      await Future.delayed(const Duration(seconds: 1));
      
      _isConnected = true;
      _connectedProvider = 'google';
      
      // Load sample events for demo
      _cachedEvents = _generateSampleEvents();
      
      debugPrint('✅ Connected to Google Calendar');
      return true;
    } catch (e) {
      debugPrint('❌ Google Calendar connection failed: $e');
      return false;
    }
  }

  /// Connect to Apple Calendar (iCal)
  Future<bool> connectAppleCalendar() async {
    try {
      debugPrint('🔗 Connecting to Apple Calendar...');
      
      // In production, this would use device_calendar package
      await Future.delayed(const Duration(seconds: 1));
      
      _isConnected = true;
      _connectedProvider = 'apple';
      _cachedEvents = _generateSampleEvents();
      
      debugPrint('✅ Connected to Apple Calendar');
      return true;
    } catch (e) {
      debugPrint('❌ Apple Calendar connection failed: $e');
      return false;
    }
  }

  /// Disconnect from calendar
  Future<void> disconnect() async {
    _isConnected = false;
    _connectedProvider = null;
    _cachedEvents.clear();
    debugPrint('📴 Disconnected from calendar');
  }

  /// Get upcoming events
  Future<List<CalendarEvent>> getUpcomingEvents({int days = 7}) async {
    if (!_isConnected) {
      throw CalendarException('Not connected to any calendar');
    }

    final now = DateTime.now();
    final endDate = now.add(Duration(days: days));

    return _cachedEvents.where((event) {
      return event.startTime.isAfter(now) && event.startTime.isBefore(endDate);
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Get today's events
  Future<List<CalendarEvent>> getTodayEvents() async {
    if (!_isConnected) {
      throw CalendarException('Not connected to any calendar');
    }

    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));

    return _cachedEvents.where((event) {
      return event.startTime.isAfter(startOfDay) && event.startTime.isBefore(endOfDay);
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  /// Create a new calendar event
  Future<CalendarEvent> createEvent({
    required String title,
    String? description,
    required DateTime startTime,
    required DateTime endTime,
    String? location,
    List<String> attendees = const [],
    bool isAllDay = false,
  }) async {
    if (!_isConnected) {
      throw CalendarException('Not connected to any calendar');
    }

    final event = CalendarEvent(
      id: 'evt_${DateTime.now().millisecondsSinceEpoch}',
      title: title,
      description: description,
      startTime: startTime,
      endTime: endTime,
      location: location,
      attendees: attendees,
      isAllDay: isAllDay,
    );

    _cachedEvents.add(event);
    debugPrint('📅 Created event: $title');
    
    return event;
  }

  /// Create a reminder from a document
  Future<CalendarEvent> createReminderFromDocument({
    required int documentId,
    required String documentTitle,
    required DateTime reminderTime,
    String? notes,
  }) async {
    return createEvent(
      title: '📌 Review: $documentTitle',
      description: notes ?? 'Reminder to review this memory from Recall Butler',
      startTime: reminderTime,
      endTime: reminderTime.add(const Duration(minutes: 30)),
    );
  }

  /// Sync reminders from Recall Butler to calendar
  Future<int> syncRemindersToCalendar(List<Map<String, dynamic>> reminders) async {
    if (!_isConnected) {
      throw CalendarException('Not connected to any calendar');
    }

    int synced = 0;
    for (final reminder in reminders) {
      try {
        await createEvent(
          title: reminder['title'] ?? 'Recall Butler Reminder',
          description: reminder['description'],
          startTime: DateTime.parse(reminder['scheduledAt']),
          endTime: DateTime.parse(reminder['scheduledAt']).add(const Duration(minutes: 30)),
        );
        synced++;
      } catch (e) {
        debugPrint('Failed to sync reminder: $e');
      }
    }
    
    debugPrint('📅 Synced $synced reminders to calendar');
    return synced;
  }

  /// Find relevant documents for upcoming meetings
  Future<List<Map<String, dynamic>>> suggestDocumentsForMeetings(
    List<CalendarEvent> events,
    Future<List<dynamic>> Function(String query) searchFunction,
  ) async {
    final suggestions = <Map<String, dynamic>>[];

    for (final event in events) {
      // Search for documents related to meeting title/attendees
      final searchTerms = [
        event.title,
        ...event.attendees.take(3),
        event.location ?? '',
      ].where((s) => s.isNotEmpty).join(' ');

      if (searchTerms.isNotEmpty) {
        try {
          final results = await searchFunction(searchTerms);
          if (results.isNotEmpty) {
            suggestions.add({
              'event': event.toMap(),
              'relevantDocuments': results.take(3).toList(),
              'reason': 'Related to "${event.title}"',
            });
          }
        } catch (e) {
          debugPrint('Search failed for event ${event.title}: $e');
        }
      }
    }

    return suggestions;
  }

  /// Generate sample events for demo
  List<CalendarEvent> _generateSampleEvents() {
    final now = DateTime.now();
    return [
      CalendarEvent(
        id: 'evt_1',
        title: 'Team Standup',
        description: 'Daily sync with the team',
        startTime: DateTime(now.year, now.month, now.day, 9, 0),
        endTime: DateTime(now.year, now.month, now.day, 9, 30),
        location: 'Conference Room A',
        attendees: ['alice@example.com', 'bob@example.com'],
      ),
      CalendarEvent(
        id: 'evt_2',
        title: 'Project Review',
        description: 'Q1 project progress review',
        startTime: now.add(const Duration(hours: 2)),
        endTime: now.add(const Duration(hours: 3)),
        location: 'Zoom',
        attendees: ['manager@example.com'],
      ),
      CalendarEvent(
        id: 'evt_3',
        title: 'Client Meeting - Acme Corp',
        description: 'Discuss new requirements',
        startTime: now.add(const Duration(days: 1, hours: 10)),
        endTime: now.add(const Duration(days: 1, hours: 11)),
        location: 'Client Office',
        attendees: ['john@acme.com', 'jane@acme.com'],
      ),
      CalendarEvent(
        id: 'evt_4',
        title: 'Hackathon Demo',
        description: 'Present Recall Butler',
        startTime: now.add(const Duration(days: 2, hours: 14)),
        endTime: now.add(const Duration(days: 2, hours: 15)),
        location: 'Main Stage',
      ),
      CalendarEvent(
        id: 'evt_5',
        title: 'Weekly Planning',
        description: 'Plan next week\'s tasks',
        startTime: now.add(const Duration(days: 3, hours: 11)),
        endTime: now.add(const Duration(days: 3, hours: 12)),
        recurrence: 'WEEKLY',
      ),
    ];
  }
}

/// Calendar exception
class CalendarException implements Exception {
  final String message;
  CalendarException(this.message);
  
  @override
  String toString() => 'CalendarException: $message';
}
