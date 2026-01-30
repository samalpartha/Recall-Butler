import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'logger_service.dart';

class ActionExecutor {
  static final ActionExecutor _instance = ActionExecutor._internal();
  factory ActionExecutor() => _instance;
  ActionExecutor._internal();

  Future<bool> execute(Session session, ButlerAction action) async {
    logger.info('Executing action: ${action.runtimeType} - ${action.description}');

    try {
      if (action is CreateReminderAction) {
        return await _executeCreateReminder(session, action);
      } else if (action is SendEmailAction) {
        return await _executeSendEmail(session, action);
      } else {
        logger.warning('Unknown action type: ${action.runtimeType}');
        return false;
      }
    } catch (e) {
      logger.error('Failed to execute action', error: e);
      return false;
    }
  }

  Future<bool> _executeCreateReminder(Session session, CreateReminderAction action) async {
    logger.info('Creating REMINDER: "${action.title}" due at ${action.dueAt}');
    
    try {
      var reminder = Reminder(
        userId: 1, // Default user ID
        title: action.title,
        description: action.description.isNotEmpty ? action.description : null,
        dueAt: action.dueAt,
        isCompleted: false,
        priority: _mapPriority(action.priority ?? 'low'),
        createdAt: DateTime.now().toUtc(),
      );

      await Reminder.db.insertRow(session, reminder);
      logger.info('Reminder created: ${reminder.id}');
      return true;
    } catch (e) {
      logger.error('Failed to create reminder', error: e);
      return false;
    }
  }

  Future<bool> _executeSendEmail(Session session, SendEmailAction action) async {
    // In a real app, use Mailer or similar.
    logger.info('Sending EMAIL to ${action.recipient}: "${action.subject}"');
    
    // Simulating success
    await Future.delayed(Duration(seconds: 1));
    return true;
  }

  int _mapPriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'high': return 3;
      case 'medium': return 2;
      case 'low': 
      default: return 1;
    }
  }
}
