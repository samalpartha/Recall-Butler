import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';

class ReminderEndpoint extends Endpoint {
  
  Future<List<Reminder>> getReminders(Session session) async {
    // In a real app, filter by session.auth.authenticatedUserId
    return await Reminder.db.find(
      session,
      orderBy: (t) => t.createdAt,
      orderDescending: true,
    );
  }

  Future<Reminder> createReminder(Session session, Reminder reminder) async {
    // Ensure createdAt is set
    reminder.createdAt = DateTime.now().toUtc();
    return await Reminder.db.insertRow(session, reminder);
  }

  Future<Reminder> updateReminder(Session session, Reminder reminder) async {
    reminder.updatedAt = DateTime.now().toUtc();
    return await Reminder.db.updateRow(session, reminder);
  }

  Future<void> deleteReminder(Session session, int id) async {
    await Reminder.db.deleteWhere(session, where: (t) => t.id.equals(id));
  }
}
