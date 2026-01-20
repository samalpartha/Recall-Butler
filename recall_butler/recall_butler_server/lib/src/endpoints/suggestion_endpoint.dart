import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class SuggestionEndpoint extends Endpoint {
  /// Create a custom reminder for a document
  Future<Suggestion> createReminder(
    Session session, {
    required int documentId,
    required String title,
    required String description,
    required DateTime scheduledAt,
    int userId = 1,
  }) async {
    final suggestion = Suggestion(
      documentId: documentId,
      userId: userId,
      type: 'reminder',
      title: title,
      description: description,
      payloadJson: jsonEncode({
        'action': 'reminder',
        'scheduledAt': scheduledAt.toIso8601String(),
      }),
      state: 'ACCEPTED',
      scheduledAt: scheduledAt,
    );
    
    return await Suggestion.db.insertRow(session, suggestion);
  }
  /// Get all suggestions for a user
  Future<List<Suggestion>> getSuggestions(
    Session session, {
    int userId = 1,
    String? state,
  }) async {
    if (state != null) {
      return await Suggestion.db.find(
        session,
        where: (t) => t.userId.equals(userId) & t.state.equals(state),
        orderBy: (t) => t.id,
        orderDescending: true,
      );
    }
    return await Suggestion.db.find(
      session,
      where: (t) => t.userId.equals(userId),
      orderBy: (t) => t.id,
      orderDescending: true,
    );
  }

  /// Get pending suggestions count
  Future<int> getPendingCount(Session session, {int userId = 1}) async {
    final suggestions = await Suggestion.db.find(
      session,
      where: (t) => t.userId.equals(userId) & t.state.equals('PROPOSED'),
    );
    return suggestions.length;
  }

  /// Accept a suggestion
  Future<Suggestion> accept(Session session, int id) async {
    final suggestion = await Suggestion.db.findById(session, id);
    if (suggestion == null) {
      throw Exception('Suggestion not found');
    }
    
    final updated = suggestion.copyWith(
      state: 'ACCEPTED',
      executedAt: DateTime.now(),
    );
    
    return await Suggestion.db.updateRow(session, updated);
  }

  /// Dismiss a suggestion
  Future<Suggestion> dismiss(Session session, int id) async {
    final suggestion = await Suggestion.db.findById(session, id);
    if (suggestion == null) {
      throw Exception('Suggestion not found');
    }
    
    final updated = suggestion.copyWith(state: 'DISMISSED');
    return await Suggestion.db.updateRow(session, updated);
  }

  /// Get suggestion by ID
  Future<Suggestion?> getSuggestion(Session session, int id) async {
    return await Suggestion.db.findById(session, id);
  }
}
