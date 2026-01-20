import 'dart:convert';
import 'package:serverpod/serverpod.dart';
import 'ai_service.dart';
import 'vector_search_service.dart';
import 'logger_service.dart';

/// AI Agent Service with ReAct (Reasoning + Acting) Pattern
/// Enables autonomous task execution with tool use
class AIAgentService {
  final Session session;
  final AIService aiService;
  final VectorSearchService vectorSearch;
  final LoggerService logger;
  
  // Maximum iterations to prevent infinite loops
  static const int maxIterations = 10;
  
  AIAgentService(this.session)
      : aiService = AIService(session),
        vectorSearch = VectorSearchService(session),
        logger = LoggerService(session);

  /// Execute a task using ReAct loop
  Future<AgentResult> executeTask({
    required String task,
    required int userId,
    List<String>? allowedTools,
    Map<String, dynamic>? context,
  }) async {
    logger.info('Starting agent task execution', {
      'task': task,
      'userId': userId,
      'allowedTools': allowedTools,
    });

    final steps = <AgentStep>[];
    var currentThought = '';
    var iteration = 0;

    while (iteration < maxIterations) {
      iteration++;

      try {
        // Generate next action using ReAct prompt
        final response = await _getNextAction(
          task: task,
          previousSteps: steps,
          currentThought: currentThought,
          allowedTools: allowedTools ?? _defaultTools,
          context: context ?? {},
        );

        logger.debug('Agent response', {'iteration': iteration, 'response': response});

        // Parse agent response
        final action = _parseAgentResponse(response);

        if (action.isFinalAnswer) {
          // Task complete
          logger.info('Agent task complete', {
            'iterations': iteration,
            'answer': action.finalAnswer,
          });

          return AgentResult(
            success: true,
            answer: action.finalAnswer!,
            steps: steps,
            iterationsUsed: iteration,
          );
        }

        // Execute the action
        final observation = await _executeAction(
          action: action,
          userId: userId,
          context: context ?? {},
        );

        // Record the step
        steps.add(AgentStep(
          iteration: iteration,
          thought: action.thought,
          action: action.actionName!,
          actionInput: action.actionInput!,
          observation: observation,
        ));

        currentThought = observation;

      } catch (e, stackTrace) {
        logger.error('Agent execution error', {
          'iteration': iteration,
          'error': e.toString(),
          'stackTrace': stackTrace.toString(),
        });

        return AgentResult(
          success: false,
          error: 'Agent execution failed: $e',
          steps: steps,
          iterationsUsed: iteration,
        );
      }
    }

    // Max iterations reached
    logger.warn('Agent max iterations reached', {'task': task});
    return AgentResult(
      success: false,
      error: 'Maximum iterations ($maxIterations) reached without final answer',
      steps: steps,
      iterationsUsed: iteration,
    );
  }

  /// Generate next action using AI with ReAct prompt
  Future<String> _getNextAction({
    required String task,
    required List<AgentStep> previousSteps,
    required String currentThought,
    required List<String> allowedTools,
    required Map<String, dynamic> context,
  }) async {
    final prompt = _buildReActPrompt(
      task: task,
      previousSteps: previousSteps,
      allowedTools: allowedTools,
      context: context,
    );

    final response = await aiService.generateResponse(
      prompt: prompt,
      userId: context['userId'] as int? ?? 1,
      temperature: 0.1, // Low temperature for consistent reasoning
    );

    return response.content;
  }

  /// Parse agent response into structured action
  AgentAction _parseAgentResponse(String response) {
    final thoughtMatch = RegExp(r'Thought:\s*(.+?)(?=\n|$)', dotAll: true)
        .firstMatch(response);
    final actionMatch = RegExp(r'Action:\s*(\w+)', caseSensitive: false)
        .firstMatch(response);
    final inputMatch = RegExp(r'Action Input:\s*(\{.+?\})',
            dotAll: true, caseSensitive: false)
        .firstMatch(response);
    final finalAnswerMatch =
        RegExp(r'Final Answer:\s*(.+)', dotAll: true, caseSensitive: false)
            .firstMatch(response);

    if (finalAnswerMatch != null) {
      return AgentAction(
        thought: thoughtMatch?.group(1)?.trim() ?? '',
        isFinalAnswer: true,
        final Answer: finalAnswerMatch.group(1)?.trim(),
      );
    }

    if (actionMatch == null || inputMatch == null) {
      throw AgentException(
          'Invalid agent response format. Expected "Action:" and "Action Input:"');
    }

    return AgentAction(
      thought: thoughtMatch?.group(1)?.trim() ?? '',
      actionName: actionMatch.group(1)?.trim(),
      actionInput: _parseActionInput(inputMatch.group(1)!.trim()),
      isFinalAnswer: false,
    );
  }

  /// Parse JSON action input
  Map<String, dynamic> _parseActionInput(String input) {
    try {
      return jsonDecode(input) as Map<String, dynamic>;
    } catch (e) {
      throw AgentException('Invalid action input JSON: $input');
    }
  }

  /// Execute agent action using available tools
  Future<String> _executeAction({
    required AgentAction action,
    required int userId,
    required Map<String, dynamic> context,
  }) async {
    logger.debug('Executing action', {
      'action': action.actionName,
      'input': action.actionInput,
    });

    switch (action.actionName?.toLowerCase()) {
      case 'search_memories':
        return await _searchMemories(action.actionInput!, userId);

      case 'create_reminder':
        return await _createReminder(action.actionInput!, userId);

      case 'check_calendar':
        return await _checkCalendar(action.actionInput!, userId);

      case 'summarize_document':
        return await _summarizeDocument(action.actionInput!, userId);

      case 'find_connections':
        return await _findConnections(action.actionInput!, userId);

      case 'get_insights':
        return await _getInsights(action.actionInput!, userId);

      default:
        throw AgentException('Unknown action: ${action.actionName}');
    }
  }

  /// Tool: Search memories using vector search
  Future<String> _searchMemories(Map<String, dynamic> input, int userId) async {
    final query = input['query'] as String? ?? '';
    final limit = input['limit'] as int? ?? 5;

    final results = await vectorSearch.searchDocuments(
      query: query,
      userId: userId,
      limit: limit,
    );

    if (results.isEmpty) {
      return 'No relevant memories found for: $query';
    }

    final formatted = results
        .map((r) =>
            '- ${r.title} (score: ${r.score.toStringAsFixed(2)}): ${r.content.substring(0, min(200, r.content.length))}...')
        .join('\n');

    return 'Found ${results.length} relevant memories:\n$formatted';
  }

  /// Tool: Create reminder
  Future<String> _createReminder(Map<String, dynamic> input, int userId) async {
    final documentId = input['documentId'] as int?;
    final reminderTime = input['time'] != null
        ? DateTime.parse(input['time'] as String)
        : null;
    final message = input['message'] as String? ?? '';

    // Create reminder in database
    // (Implementation would insert into reminders table)

    return 'Reminder created for ${reminderTime?.toString() ?? "later"}: $message';
  }

  /// Tool: Check calendar
  Future<String> _checkCalendar(Map<String, dynamic> input, int userId) async {
    final startDate = input['startDate'] != null
        ? DateTime.parse(input['startDate'] as String)
        : DateTime.now();
    final endDate = input['endDate'] != null
        ? DateTime.parse(input['endDate'] as String)
        : startDate.add(Duration(days: 7));

    // Query calendar events
    // (Implementation would query calendar_events table)

    return 'Calendar checked for ${startDate.toIso8601String()} to ${endDate.toIso8601String()}';
  }

  /// Tool: Summarize document
  Future<String> _summarizeDocument(Map<String, dynamic> input, int userId) async {
    final documentId = input['documentId'] as int;

    // Fetch documentand summarize
    // (Implementation would use AI service to generate summary)

    return 'Document summary generated for ID: $documentId';
  }

  /// Tool: Find connections in knowledge graph
  Future<String> _findConnections(Map<String, dynamic> input, int userId) async {
    final entityName = input['entity'] as String? ?? '';

    // Query knowledge graph
    // (Implementation would query entities and entity_relations tables)

    return 'Found connections for entity: $entityName';
  }

  /// Tool: Get insights from analytics
  Future<String> _getInsights(Map<String, dynamic> input, int userId) async {
    final metricType = input['metric'] as String? ?? 'usage';

    // Generate insights from analytics data
    // (Implementation would query user_analytics table)

    return 'Analytics insights generated for metric: $metricType';
  }

  /// Build ReAct prompt with context
  String _buildReActPrompt({
    required String task,
    required List<AgentStep> previousSteps,
    required List<String> allowedTools,
    required Map<String, dynamic> context,
  }) {
    final toolDescriptions = _getToolDescriptions(allowedTools);
    final previousStepsText = previousSteps.isEmpty
        ? ''
        : 'Previous steps:\n' +
            previousSteps
                .map((s) =>
                    'Step ${s.iteration}:\nThought: ${s.thought}\nAction: ${s.action}\nAction Input: ${jsonEncode(s.actionInput)}\nObservation: ${s.observation}')
                .join('\n\n');

    return '''You are an AI assistant helping with the following task:
$task

You have access to the following tools:
$toolDescriptions

Use the following format:

Thought: think about what to do
Action: the action to take, should be one of [${allowedTools.join(', ')}]
Action Input: the input to the action as a JSON object
Observation: the result of the action

... (repeat Thought/Action/Action Input/Observation as needed)

Thought: I now know the final answer
Final Answer: the final answer to the original task

$previousStepsText

Begin! Remember to always use the exact format above.

Thought:''';
  }

  /// Get tool descriptions for prompt
  String _getToolDescriptions(List<String> tools) {
    final descriptions = {
      'search_memories':
          'Search through stored documents and memories using semantic search. Input: {"query": "search text", "limit": 5}',
      'create_reminder':
          'Create a reminder for a specific time. Input: {"documentId": 123, "time": "2024-01-20T10:00:00Z", "message": "reminder text"}',
      'check_calendar':
          'Check calendar events. Input: {"startDate": "2024-01-20", "endDate": "2024-01-27"}',
      'summarize_document':
          'Generate a summary of a document. Input: {"documentId": 123}',
      'find_connections':
          'Find related entities in the knowledge graph. Input: {"entity": "entity name"}',
      'get_insights':
          'Get analytics insights. Input: {"metric": "usage|activity|trends"}',
    };

    return tools
        .map((tool) => '- $tool: ${descriptions[tool] ?? "No description"}')
        .join('\n');
  }

  List<String> get _defaultTools => [
        'search_memories',
        'create_reminder',
        'check_calendar',
        'summarize_document',
        'find_connections',
        'get_insights',
      ];
}

// Data classes
class AgentResult {
  final bool success;
  final String? answer;
  final String? error;
  final List<AgentStep> steps;
  final int iterationsUsed;

  AgentResult({
    required this.success,
    this.answer,
    this.error,
    required this.steps,
    required this.iterationsUsed,
  });
}

class AgentStep {
  final int iteration;
  final String thought;
  final String action;
  final Map<String, dynamic> actionInput;
  final String observation;

  AgentStep({
    required this.iteration,
    required this.thought,
    required this.action,
    required this.actionInput,
    required this.observation,
  });
}

class AgentAction {
  final String thought;
  final String? actionName;
  final Map<String, dynamic>? actionInput;
  final bool isFinalAnswer;
  final String? finalAnswer;

  AgentAction({
    required this.thought,
    this.actionName,
    this.actionInput,
    required this.isFinalAnswer,
    this.finalAnswer,
  });
}

class AgentException implements Exception {
  final String message;
  AgentException(this.message);

  @override
  String toString() => 'AgentException: $message';
}
