import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

/// Chat message model
class ChatMessage {
  final String id;
  final String content;
  final MessageRole role;
  final DateTime timestamp;
  final List<String>? relatedDocumentIds;
  final Map<String, dynamic>? metadata;
  final bool isBookmarked;

  ChatMessage({
    required this.id,
    required this.content,
    required this.role,
    required this.timestamp,
    this.relatedDocumentIds,
    this.metadata,
    this.isBookmarked = false,
  });

  ChatMessage copyWith({
    String? content,
    bool? isBookmarked,
    Map<String, dynamic>? metadata,
  }) {
    return ChatMessage(
      id: id,
      content: content ?? this.content,
      role: role,
      timestamp: timestamp,
      relatedDocumentIds: relatedDocumentIds,
      metadata: metadata ?? this.metadata,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'content': content,
    'role': role.name,
    'timestamp': timestamp.toIso8601String(),
    'relatedDocumentIds': relatedDocumentIds,
    'metadata': metadata,
    'isBookmarked': isBookmarked,
  };

  factory ChatMessage.fromMap(Map<String, dynamic> map) => ChatMessage(
    id: map['id'],
    content: map['content'],
    role: MessageRole.values.firstWhere(
      (r) => r.name == map['role'],
      orElse: () => MessageRole.user,
    ),
    timestamp: DateTime.parse(map['timestamp']),
    relatedDocumentIds: (map['relatedDocumentIds'] as List?)?.cast<String>(),
    metadata: map['metadata'],
    isBookmarked: map['isBookmarked'] ?? false,
  );
}

enum MessageRole {
  user,
  assistant,
  system,
}

/// Conversation session model
class ConversationSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final DateTime lastMessageAt;
  final List<ChatMessage> messages;
  final Map<String, dynamic>? context;
  final List<String>? tags;

  ConversationSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.lastMessageAt,
    required this.messages,
    this.context,
    this.tags,
  });

  ConversationSession copyWith({
    String? title,
    DateTime? lastMessageAt,
    List<ChatMessage>? messages,
    Map<String, dynamic>? context,
    List<String>? tags,
  }) {
    return ConversationSession(
      id: id,
      title: title ?? this.title,
      createdAt: createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      messages: messages ?? this.messages,
      context: context ?? this.context,
      tags: tags ?? this.tags,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'title': title,
    'createdAt': createdAt.toIso8601String(),
    'lastMessageAt': lastMessageAt.toIso8601String(),
    'messages': messages.map((m) => m.toMap()).toList(),
    'context': context,
    'tags': tags,
  };

  factory ConversationSession.fromMap(Map<String, dynamic> map) => ConversationSession(
    id: map['id'],
    title: map['title'],
    createdAt: DateTime.parse(map['createdAt']),
    lastMessageAt: DateTime.parse(map['lastMessageAt']),
    messages: (map['messages'] as List)
        .map((m) => ChatMessage.fromMap(m))
        .toList(),
    context: map['context'],
    tags: (map['tags'] as List?)?.cast<String>(),
  );
}

/// Conversation memory service with persistent storage and context awareness
class ConversationMemoryService {
  static final ConversationMemoryService _instance = ConversationMemoryService._internal();
  factory ConversationMemoryService() => _instance;
  ConversationMemoryService._internal();

  static const String _storageKey = 'conversation_sessions';
  static const int _maxSessionsToKeep = 50;
  static const int _maxMessagesPerSession = 100;

  List<ConversationSession> _sessions = [];
  ConversationSession? _currentSession;
  SharedPreferences? _prefs;

  List<ConversationSession> get sessions => List.unmodifiable(_sessions);
  ConversationSession? get currentSession => _currentSession;

  /// Initialize the service
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadSessions();
    debugPrint('💬 Conversation Memory initialized with ${_sessions.length} sessions');
  }

  /// Load sessions from storage
  Future<void> _loadSessions() async {
    try {
      final data = _prefs?.getString(_storageKey);
      if (data != null) {
        final List<dynamic> decoded = jsonDecode(data);
        _sessions = decoded
            .map((s) => ConversationSession.fromMap(s))
            .toList();
        _sessions.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));
      }
    } catch (e) {
      debugPrint('Error loading conversation sessions: $e');
      _sessions = [];
    }
  }

  /// Save sessions to storage
  Future<void> _saveSessions() async {
    try {
      // Keep only recent sessions
      if (_sessions.length > _maxSessionsToKeep) {
        _sessions = _sessions.take(_maxSessionsToKeep).toList();
      }
      
      final data = jsonEncode(_sessions.map((s) => s.toMap()).toList());
      await _prefs?.setString(_storageKey, data);
    } catch (e) {
      debugPrint('Error saving conversation sessions: $e');
    }
  }

  /// Start a new conversation session
  Future<ConversationSession> startNewSession({String? title}) async {
    final session = ConversationSession(
      id: 'session_${DateTime.now().millisecondsSinceEpoch}',
      title: title ?? 'New Conversation',
      createdAt: DateTime.now(),
      lastMessageAt: DateTime.now(),
      messages: [],
    );

    _sessions.insert(0, session);
    _currentSession = session;
    await _saveSessions();
    
    debugPrint('💬 Started new conversation: ${session.id}');
    return session;
  }

  /// Resume an existing session
  Future<ConversationSession?> resumeSession(String sessionId) async {
    final session = _sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => throw Exception('Session not found'),
    );
    _currentSession = session;
    debugPrint('💬 Resumed conversation: ${session.id}');
    return session;
  }

  /// Add a user message
  Future<ChatMessage> addUserMessage(
    String content, {
    List<String>? relatedDocumentIds,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentSession == null) {
      await startNewSession();
    }

    final message = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      role: MessageRole.user,
      timestamp: DateTime.now(),
      relatedDocumentIds: relatedDocumentIds,
      metadata: metadata,
    );

    await _addMessage(message);
    return message;
  }

  /// Add an assistant message
  Future<ChatMessage> addAssistantMessage(
    String content, {
    List<String>? relatedDocumentIds,
    Map<String, dynamic>? metadata,
  }) async {
    if (_currentSession == null) {
      await startNewSession();
    }

    final message = ChatMessage(
      id: 'msg_${DateTime.now().millisecondsSinceEpoch}',
      content: content,
      role: MessageRole.assistant,
      timestamp: DateTime.now(),
      relatedDocumentIds: relatedDocumentIds,
      metadata: metadata,
    );

    await _addMessage(message);
    return message;
  }

  /// Add a message to current session
  Future<void> _addMessage(ChatMessage message) async {
    if (_currentSession == null) return;

    final messages = List<ChatMessage>.from(_currentSession!.messages);
    messages.add(message);

    // Trim old messages if needed
    if (messages.length > _maxMessagesPerSession) {
      messages.removeRange(0, messages.length - _maxMessagesPerSession);
    }

    // Update session title based on first user message
    String title = _currentSession!.title;
    if (_currentSession!.messages.isEmpty && message.role == MessageRole.user) {
      title = _generateTitle(message.content);
    }

    _currentSession = _currentSession!.copyWith(
      title: title,
      lastMessageAt: DateTime.now(),
      messages: messages,
    );

    // Update in sessions list
    final index = _sessions.indexWhere((s) => s.id == _currentSession!.id);
    if (index != -1) {
      _sessions[index] = _currentSession!;
    }
    _sessions.sort((a, b) => b.lastMessageAt.compareTo(a.lastMessageAt));

    await _saveSessions();
  }

  /// Generate a title from message content
  String _generateTitle(String content) {
    final cleaned = content.trim();
    if (cleaned.length <= 40) return cleaned;
    return '${cleaned.substring(0, 40)}...';
  }

  /// Get conversation context for AI
  String getContextForAI({int maxMessages = 10}) {
    if (_currentSession == null || _currentSession!.messages.isEmpty) {
      return '';
    }

    final recentMessages = _currentSession!.messages
        .reversed
        .take(maxMessages)
        .toList()
        .reversed;

    final buffer = StringBuffer();
    buffer.writeln('Previous conversation context:');
    
    for (final msg in recentMessages) {
      final role = msg.role == MessageRole.user ? 'User' : 'Assistant';
      buffer.writeln('$role: ${msg.content}');
    }

    return buffer.toString();
  }

  /// Search across all conversations
  List<Map<String, dynamic>> searchConversations(String query) {
    final results = <Map<String, dynamic>>[];
    final queryLower = query.toLowerCase();

    for (final session in _sessions) {
      for (final message in session.messages) {
        if (message.content.toLowerCase().contains(queryLower)) {
          results.add({
            'session': session,
            'message': message,
            'snippet': _extractSnippet(message.content, queryLower),
          });
        }
      }
    }

    return results;
  }

  String _extractSnippet(String content, String query) {
    final index = content.toLowerCase().indexOf(query);
    if (index == -1) return content.substring(0, content.length.clamp(0, 100));
    
    final start = (index - 30).clamp(0, content.length);
    final end = (index + query.length + 50).clamp(0, content.length);
    return '...${content.substring(start, end)}...';
  }

  /// Get bookmarked messages
  List<ChatMessage> getBookmarkedMessages() {
    final bookmarked = <ChatMessage>[];
    for (final session in _sessions) {
      bookmarked.addAll(session.messages.where((m) => m.isBookmarked));
    }
    return bookmarked;
  }

  /// Toggle bookmark on a message
  Future<void> toggleBookmark(String sessionId, String messageId) async {
    final sessionIndex = _sessions.indexWhere((s) => s.id == sessionId);
    if (sessionIndex == -1) return;

    final session = _sessions[sessionIndex];
    final messages = session.messages.map((m) {
      if (m.id == messageId) {
        return m.copyWith(isBookmarked: !m.isBookmarked);
      }
      return m;
    }).toList();

    _sessions[sessionIndex] = session.copyWith(messages: messages);
    
    if (_currentSession?.id == sessionId) {
      _currentSession = _sessions[sessionIndex];
    }

    await _saveSessions();
  }

  /// Delete a session
  Future<void> deleteSession(String sessionId) async {
    _sessions.removeWhere((s) => s.id == sessionId);
    if (_currentSession?.id == sessionId) {
      _currentSession = null;
    }
    await _saveSessions();
    debugPrint('🗑️ Deleted conversation: $sessionId');
  }

  /// Clear all sessions
  Future<void> clearAllSessions() async {
    _sessions.clear();
    _currentSession = null;
    await _prefs?.remove(_storageKey);
    debugPrint('🗑️ Cleared all conversations');
  }

  /// Get session statistics
  Map<String, dynamic> getStatistics() {
    int totalMessages = 0;
    int userMessages = 0;
    int assistantMessages = 0;
    int bookmarkedMessages = 0;

    for (final session in _sessions) {
      totalMessages += session.messages.length;
      userMessages += session.messages.where((m) => m.role == MessageRole.user).length;
      assistantMessages += session.messages.where((m) => m.role == MessageRole.assistant).length;
      bookmarkedMessages += session.messages.where((m) => m.isBookmarked).length;
    }

    return {
      'totalSessions': _sessions.length,
      'totalMessages': totalMessages,
      'userMessages': userMessages,
      'assistantMessages': assistantMessages,
      'bookmarkedMessages': bookmarkedMessages,
      'averageMessagesPerSession': _sessions.isEmpty 
          ? 0 
          : (totalMessages / _sessions.length).round(),
    };
  }

  /// Export conversation as text
  String exportSession(String sessionId) {
    final session = _sessions.firstWhere(
      (s) => s.id == sessionId,
      orElse: () => throw Exception('Session not found'),
    );

    final buffer = StringBuffer();
    buffer.writeln('# ${session.title}');
    buffer.writeln('Created: ${session.createdAt.toIso8601String()}');
    buffer.writeln('---\n');

    for (final message in session.messages) {
      final role = message.role == MessageRole.user ? '👤 You' : '🤖 Butler';
      buffer.writeln('**$role** (${message.timestamp.toIso8601String()})');
      buffer.writeln(message.content);
      buffer.writeln('');
    }

    return buffer.toString();
  }
}
