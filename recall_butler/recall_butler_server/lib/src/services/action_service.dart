import 'package:serverpod/serverpod.dart';
import '../generated/protocol.dart';
import 'ai_service.dart';
import 'logger_service.dart';
import 'dart:convert';

class ActionService {
  static final ActionService _instance = ActionService._internal();
  factory ActionService() => _instance;
  ActionService._internal();

  final _aiService = AIService();

  Future<ButlerAction?> parseAction(Session session, String text) async {
    logger.info('Parsing action from text: \$text');

    // 1. Construct prompt
    final prompt = '''
You are a smart personal assistant. Your job is to extract actionable tasks from user input.
The user input is: "\$text"

Available Action Types:
- CreateReminder: Title (string), DueAt (datetime ISO8601), Priority (low/medium/high)
- SendEmail: Recipient (string, email), Subject (string), Body (string)
- ScheduleEvent: Title (string), StartTime (datetime ISO8601), DurationMinutes (int) -- NOT IMPLEMENTED YET

If the input matches one of these intents with high confidence (>0.8), return a JSON object with the following structure:
{
  "type": "CreateReminder" | "SendEmail",
  "confidence": 0.0-1.0,
  "description": "Short summary of action",
  "data": { ... specific fields ... }
}

If no action is detected or confidence is low, return field "type": "None".
Return ONLY raw JSON.
''';

    // 2. Call LLM
    final response = await _aiService.chat(systemPrompt: "You are a JSON parser.", prompt: prompt);
    
    if (response == null) return null;

    try {
      final json = jsonDecode(response);
      if (json['type'] == 'None') return null;

      final confidence = (json['confidence'] as num).toDouble();
      final description = json['description'] as String;
      final data = json['data'] as Map<String, dynamic>;

      if (json['type'] == 'CreateReminder') {
        return CreateReminderAction(
          userId: 0, // Set by caller
          description: description,
          confidence: confidence,
          status: ActionStatus.proposed,
          createdAt: DateTime.now(),
          title: data['title'],
          dueAt: DateTime.parse(data['dueAt']),
          priority: data['priority'],
        );
      } else if (json['type'] == 'SendEmail') {
        return SendEmailAction(
           userId: 0, // Set by caller
          description: description,
          confidence: confidence,
          status: ActionStatus.proposed,
          createdAt: DateTime.now(),
          recipient: data['recipient'],
          subject: data['subject'],
          body: data['body'],
        );
      }
      
      return null;
    } catch (e) {
      logger.error('Failed to parse action JSON', error: e, context: {'response': response});
      return null;
    }
  }
}
