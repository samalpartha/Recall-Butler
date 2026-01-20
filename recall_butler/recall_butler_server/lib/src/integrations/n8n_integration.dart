import 'dart:convert';
import 'package:http/http.dart' as http;

/// ═══════════════════════════════════════════════════════════════════════════════
/// 🔄 RECALL BUTLER - N8N WORKFLOW AUTOMATION INTEGRATION
/// ═══════════════════════════════════════════════════════════════════════════════
/// 
/// Integrates with n8n workflow automation to enable:
/// - Automated reminder notifications
/// - Cross-app data synchronization
/// - Custom Butler actions via workflows
/// - 400+ app integrations without code
/// ═══════════════════════════════════════════════════════════════════════════════

class N8nIntegration {
  final String baseUrl;
  final String? apiKey;

  N8nIntegration({
    this.baseUrl = 'http://localhost:5678',
    this.apiKey,
  });

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (apiKey != null) 'X-N8N-API-KEY': apiKey!,
  };

  /// Trigger a webhook workflow
  Future<Map<String, dynamic>> triggerWebhook({
    required String webhookPath,
    required Map<String, dynamic> data,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/webhook/$webhookPath'),
      headers: _headers,
      body: jsonEncode(data),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('n8n webhook failed: ${response.statusCode}');
    }
  }

  /// Trigger reminder workflow
  Future<void> triggerReminderWorkflow({
    required int userId,
    required int documentId,
    required String title,
    required String description,
    required DateTime scheduledAt,
    String? email,
    String? phoneNumber,
  }) async {
    await triggerWebhook(
      webhookPath: 'recall-butler/reminder',
      data: {
        'user_id': userId,
        'document_id': documentId,
        'title': title,
        'description': description,
        'scheduled_at': scheduledAt.toIso8601String(),
        'email': email,
        'phone': phoneNumber,
        'channels': ['email', 'push', 'sms'],
      },
    );
  }

  /// Trigger document processing workflow
  Future<void> triggerDocumentWorkflow({
    required int documentId,
    required String sourceType,
    required String content,
  }) async {
    await triggerWebhook(
      webhookPath: 'recall-butler/document',
      data: {
        'document_id': documentId,
        'source_type': sourceType,
        'content': content,
        'actions': ['summarize', 'extract_entities', 'generate_suggestions'],
      },
    );
  }

  /// Trigger notification workflow
  Future<void> triggerNotification({
    required int userId,
    required String type,
    required String title,
    required String body,
    Map<String, dynamic>? data,
  }) async {
    await triggerWebhook(
      webhookPath: 'recall-butler/notification',
      data: {
        'user_id': userId,
        'type': type,
        'title': title,
        'body': body,
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }

  /// Trigger sync workflow (sync with external services)
  Future<void> triggerSyncWorkflow({
    required int userId,
    required List<String> services,
  }) async {
    await triggerWebhook(
      webhookPath: 'recall-butler/sync',
      data: {
        'user_id': userId,
        'services': services, // e.g., ['google_calendar', 'notion', 'slack']
        'timestamp': DateTime.now().toIso8601String(),
      },
    );
  }
}

/// Predefined n8n workflow templates for Recall Butler
class N8nWorkflowTemplates {
  /// Reminder notification workflow
  static Map<String, dynamic> reminderWorkflow = {
    'name': 'Recall Butler - Reminder Notification',
    'nodes': [
      {
        'name': 'Webhook',
        'type': 'n8n-nodes-base.webhook',
        'parameters': {
          'path': 'recall-butler/reminder',
          'httpMethod': 'POST',
        },
      },
      {
        'name': 'Check Time',
        'type': 'n8n-nodes-base.if',
        'parameters': {
          'conditions': {
            'dateTime': [
              {
                'value1': '={{$json["scheduled_at"]}}',
                'operation': 'beforeOrEquals',
                'value2': '={{$now}}',
              },
            ],
          },
        },
      },
      {
        'name': 'Send Email',
        'type': 'n8n-nodes-base.emailSend',
        'parameters': {
          'toEmail': '={{$json["email"]}}',
          'subject': 'Reminder: {{$json["title"]}}',
          'text': '{{$json["description"]}}',
        },
      },
      {
        'name': 'Send Push',
        'type': 'n8n-nodes-base.httpRequest',
        'parameters': {
          'url': 'https://fcm.googleapis.com/fcm/send',
          'method': 'POST',
        },
      },
    ],
  };

  /// Document processing workflow
  static Map<String, dynamic> documentProcessingWorkflow = {
    'name': 'Recall Butler - Document Processing',
    'nodes': [
      {
        'name': 'Webhook',
        'type': 'n8n-nodes-base.webhook',
        'parameters': {
          'path': 'recall-butler/document',
          'httpMethod': 'POST',
        },
      },
      {
        'name': 'AI Summarize',
        'type': 'n8n-nodes-base.openAi',
        'parameters': {
          'operation': 'text',
          'prompt': 'Summarize: {{$json["content"]}}',
        },
      },
      {
        'name': 'Extract Entities',
        'type': 'n8n-nodes-base.openAi',
        'parameters': {
          'operation': 'text',
          'prompt': 'Extract dates, amounts, names from: {{$json["content"]}}',
        },
      },
      {
        'name': 'Update Database',
        'type': 'n8n-nodes-base.httpRequest',
        'parameters': {
          'url': 'http://localhost:8180/api/document/update',
          'method': 'POST',
        },
      },
    ],
  };

  /// Multi-service sync workflow
  static Map<String, dynamic> syncWorkflow = {
    'name': 'Recall Butler - Multi-Service Sync',
    'nodes': [
      {
        'name': 'Webhook',
        'type': 'n8n-nodes-base.webhook',
        'parameters': {
          'path': 'recall-butler/sync',
          'httpMethod': 'POST',
        },
      },
      {
        'name': 'Google Calendar',
        'type': 'n8n-nodes-base.googleCalendar',
        'parameters': {
          'operation': 'getAll',
        },
      },
      {
        'name': 'Notion',
        'type': 'n8n-nodes-base.notion',
        'parameters': {
          'operation': 'getAll',
        },
      },
      {
        'name': 'Merge Results',
        'type': 'n8n-nodes-base.merge',
      },
      {
        'name': 'Import to Butler',
        'type': 'n8n-nodes-base.httpRequest',
        'parameters': {
          'url': 'http://localhost:8180/api/document/batch-create',
          'method': 'POST',
        },
      },
    ],
  };
}
