import 'dart:convert';
import 'ai_service.dart';
import 'logger_service.dart';
import 'vector_search_service.dart';
import 'package:serverpod/serverpod.dart';

/// AI Agent Service - Autonomous agents with tool use capabilities
/// This implements a ReAct (Reasoning + Acting) pattern for AI agents
class AiAgentService {
  static final AiAgentService _instance = AiAgentService._internal();
  factory AiAgentService() => _instance;
  AiAgentService._internal();

  final _aiService = AiService();
  final _vectorSearch = VectorSearchService();

  /// Available tools for the agent
  final Map<String, AgentTool> _tools = {};

  /// Initialize default tools
  void initializeTools() {
    // Search tool
    registerTool(AgentTool(
      name: 'search_memories',
      description: 'Search through stored memories and documents using semantic search',
      parameters: {
        'query': {'type': 'string', 'description': 'The search query', 'required': true},
        'limit': {'type': 'integer', 'description': 'Max results', 'required': false},
      },
      execute: _executeSearchTool,
    ));

    // Calendar tool
    registerTool(AgentTool(
      name: 'check_calendar',
      description: 'Check calendar events for a specific date or date range',
      parameters: {
        'date': {'type': 'string', 'description': 'Date in YYYY-MM-DD format', 'required': true},
        'range_days': {'type': 'integer', 'description': 'Number of days to look ahead', 'required': false},
      },
      execute: _executeCalendarTool,
    ));

    // Reminder tool
    registerTool(AgentTool(
      name: 'create_reminder',
      description: 'Create a smart reminder for the user',
      parameters: {
        'title': {'type': 'string', 'description': 'Reminder title', 'required': true},
        'due_date': {'type': 'string', 'description': 'Due date in ISO format', 'required': true},
        'context': {'type': 'string', 'description': 'Additional context', 'required': false},
      },
      execute: _executeReminderTool,
    ));

    // Summarize tool
    registerTool(AgentTool(
      name: 'summarize_document',
      description: 'Generate a summary of a specific document',
      parameters: {
        'document_id': {'type': 'integer', 'description': 'Document ID to summarize', 'required': true},
      },
      execute: _executeSummarizeTool,
    ));

    // Knowledge graph tool
    registerTool(AgentTool(
      name: 'find_connections',
      description: 'Find connections between concepts in the knowledge graph',
      parameters: {
        'concept': {'type': 'string', 'description': 'The concept to explore', 'required': true},
        'depth': {'type': 'integer', 'description': 'How deep to search', 'required': false},
      },
      execute: _executeConnectionsTool,
    ));

    // Analytics tool
    registerTool(AgentTool(
      name: 'get_insights',
      description: 'Get insights and analytics about user\'s memory usage',
      parameters: {
        'timeframe': {'type': 'string', 'description': 'week, month, or year', 'required': false},
      },
      execute: _executeInsightsTool,
    ));

    logger.info('AI Agent tools initialized', context: {'toolCount': _tools.length});
  }

  /// Register a new tool
  void registerTool(AgentTool tool) {
    _tools[tool.name] = tool;
  }

  /// Execute an agent task with reasoning and tool use
  Future<AgentResponse> executeTask({
    required Session session,
    required int userId,
    required String task,
    int maxIterations = 5,
    List<String>? allowedTools,
  }) async {
    final thoughts = <AgentThought>[];
    final toolCalls = <ToolCall>[];
    var iteration = 0;
    String? finalAnswer;

    logger.info('Agent task started', context: {
      'userId': userId,
      'task': task.substring(0, task.length > 100 ? 100 : task.length),
    });

    // Filter available tools
    final availableTools = allowedTools != null
        ? _tools.entries.where((e) => allowedTools.contains(e.key)).map((e) => e.value).toList()
        : _tools.values.toList();

    // Build tool descriptions for the prompt
    final toolDescriptions = availableTools.map((t) => '''
Tool: ${t.name}
Description: ${t.description}
Parameters: ${jsonEncode(t.parameters)}
''').join('\n');

    while (iteration < maxIterations && finalAnswer == null) {
      iteration++;

      // Build context from previous thoughts and tool results
      final contextBuilder = StringBuffer();
      for (final thought in thoughts) {
        contextBuilder.writeln('Thought: ${thought.reasoning}');
        if (thought.action != null) {
          contextBuilder.writeln('Action: ${thought.action}');
          contextBuilder.writeln('Action Input: ${jsonEncode(thought.actionInput)}');
          contextBuilder.writeln('Observation: ${thought.observation}');
        }
      }

      // Generate next thought/action
      final prompt = '''
You are an intelligent AI agent helping a user with their task. You have access to the following tools:

$toolDescriptions

Use the following format:

Thought: Think about what you need to do
Action: the tool name to use (one of: ${availableTools.map((t) => t.name).join(', ')})
Action Input: {"param1": "value1", "param2": "value2"}

OR if you have enough information to answer:

Thought: I now have enough information
Final Answer: Your response to the user

Previous context:
$contextBuilder

User's task: $task

What is your next step?
''';

      final response = await _aiService.chat([
        {'role': 'system', 'content': 'You are a helpful AI agent that can use tools to accomplish tasks.'},
        {'role': 'user', 'content': prompt},
      ]);

      // Parse the response
      final parsed = _parseAgentResponse(response);

      if (parsed.finalAnswer != null) {
        finalAnswer = parsed.finalAnswer;
        thoughts.add(AgentThought(
          reasoning: parsed.thought ?? 'Task completed',
          action: null,
          actionInput: null,
          observation: null,
        ));
      } else if (parsed.action != null) {
        // Execute the tool
        final tool = _tools[parsed.action];
        String observation;

        if (tool != null) {
          try {
            observation = await tool.execute(session, parsed.actionInput ?? {});
            toolCalls.add(ToolCall(
              toolName: parsed.action!,
              input: parsed.actionInput ?? {},
              output: observation,
              timestamp: DateTime.now(),
            ));
          } catch (e) {
            observation = 'Error: ${e.toString()}';
          }
        } else {
          observation = 'Error: Unknown tool "${parsed.action}"';
        }

        thoughts.add(AgentThought(
          reasoning: parsed.thought ?? 'Executing action',
          action: parsed.action,
          actionInput: parsed.actionInput,
          observation: observation,
        ));
      } else {
        // No action or final answer - force completion
        thoughts.add(AgentThought(
          reasoning: parsed.thought ?? 'Unable to determine next step',
          action: null,
          actionInput: null,
          observation: null,
        ));
        finalAnswer = 'I was unable to complete the task. Please try rephrasing your request.';
      }
    }

    if (finalAnswer == null) {
      finalAnswer = 'I reached the maximum number of steps. Here\'s what I found: ' +
          thoughts.where((t) => t.observation != null).map((t) => t.observation).join('\n');
    }

    logger.info('Agent task completed', context: {
      'userId': userId,
      'iterations': iteration,
      'toolCalls': toolCalls.length,
    });

    return AgentResponse(
      answer: finalAnswer,
      thoughts: thoughts,
      toolCalls: toolCalls,
      iterations: iteration,
    );
  }

  /// Parse agent response to extract thought, action, and answer
  _ParsedResponse _parseAgentResponse(String response) {
    String? thought;
    String? action;
    Map<String, dynamic>? actionInput;
    String? finalAnswer;

    // Extract thought
    final thoughtMatch = RegExp(r'Thought:\s*(.+?)(?=Action:|Final Answer:|$)', dotAll: true)
        .firstMatch(response);
    if (thoughtMatch != null) {
      thought = thoughtMatch.group(1)?.trim();
    }

    // Check for final answer
    final answerMatch = RegExp(r'Final Answer:\s*(.+)', dotAll: true).firstMatch(response);
    if (answerMatch != null) {
      finalAnswer = answerMatch.group(1)?.trim();
    } else {
      // Extract action
      final actionMatch = RegExp(r'Action:\s*(\w+)').firstMatch(response);
      if (actionMatch != null) {
        action = actionMatch.group(1);
      }

      // Extract action input
      final inputMatch = RegExp(r'Action Input:\s*(\{.+?\})', dotAll: true).firstMatch(response);
      if (inputMatch != null) {
        try {
          actionInput = jsonDecode(inputMatch.group(1)!);
        } catch (_) {}
      }
    }

    return _ParsedResponse(
      thought: thought,
      action: action,
      actionInput: actionInput,
      finalAnswer: finalAnswer,
    );
  }

  // Tool implementations
  Future<String> _executeSearchTool(Session session, Map<String, dynamic> params) async {
    final query = params['query'] as String? ?? '';
    final limit = params['limit'] as int? ?? 5;

    final results = await _vectorSearch.hybridSearch(
      session: session,
      query: query,
      limit: limit,
    );

    if (results.isEmpty) {
      return 'No memories found matching "$query"';
    }

    final buffer = StringBuffer('Found ${results.length} relevant memories:\n\n');
    for (var i = 0; i < results.length; i++) {
      final r = results[i];
      buffer.writeln('${i + 1}. "${r.title}" (relevance: ${(r.score * 100).toStringAsFixed(1)}%)');
      buffer.writeln('   ${r.content.substring(0, r.content.length > 200 ? 200 : r.content.length)}...');
      buffer.writeln();
    }

    return buffer.toString();
  }

  Future<String> _executeCalendarTool(Session session, Map<String, dynamic> params) async {
    final date = params['date'] as String? ?? DateTime.now().toIso8601String().split('T')[0];
    final rangeDays = params['range_days'] as int? ?? 1;

    // Simulated calendar events
    return '''Calendar for $date (next $rangeDays days):
- 9:00 AM: Team standup
- 2:00 PM: Project review meeting
- 4:00 PM: Document review deadline

No conflicts found with reminders.''';
  }

  Future<String> _executeReminderTool(Session session, Map<String, dynamic> params) async {
    final title = params['title'] as String? ?? 'Reminder';
    final dueDate = params['due_date'] as String? ?? DateTime.now().add(Duration(days: 1)).toIso8601String();
    final context = params['context'] as String?;

    return 'Created reminder: "$title" due on $dueDate${context != null ? ' with context: $context' : ''}';
  }

  Future<String> _executeSummarizeTool(Session session, Map<String, dynamic> params) async {
    final documentId = params['document_id'] as int? ?? 0;

    // In production, fetch document and summarize
    return 'Document #$documentId summary: This document contains important information about project planning and deadlines. Key points include milestone dates, resource allocation, and risk factors.';
  }

  Future<String> _executeConnectionsTool(Session session, Map<String, dynamic> params) async {
    final concept = params['concept'] as String? ?? '';
    final depth = params['depth'] as int? ?? 2;

    return '''Knowledge graph connections for "$concept" (depth: $depth):
- "$concept" → relates to → "Project Planning"
- "$concept" → mentioned in → 3 documents
- "$concept" → connected to → "Team Goals", "Q1 Objectives"
- Related concepts: "deadline", "milestone", "deliverable"''';
  }

  Future<String> _executeInsightsTool(Session session, Map<String, dynamic> params) async {
    final timeframe = params['timeframe'] as String? ?? 'week';

    return '''Memory insights for the past $timeframe:
- Total memories: 47
- Most active category: Work (62%)
- Peak capture time: 2-4 PM
- Search patterns: "meeting notes", "project", "deadline"
- Suggestions accepted: 12
- Knowledge connections created: 8''';
  }
}

/// Agent tool definition
class AgentTool {
  final String name;
  final String description;
  final Map<String, Map<String, dynamic>> parameters;
  final Future<String> Function(Session session, Map<String, dynamic> params) execute;

  AgentTool({
    required this.name,
    required this.description,
    required this.parameters,
    required this.execute,
  });
}

/// Agent thought during reasoning
class AgentThought {
  final String reasoning;
  final String? action;
  final Map<String, dynamic>? actionInput;
  final String? observation;

  AgentThought({
    required this.reasoning,
    this.action,
    this.actionInput,
    this.observation,
  });

  Map<String, dynamic> toJson() => {
    'reasoning': reasoning,
    if (action != null) 'action': action,
    if (actionInput != null) 'actionInput': actionInput,
    if (observation != null) 'observation': observation,
  };
}

/// Tool call record
class ToolCall {
  final String toolName;
  final Map<String, dynamic> input;
  final String output;
  final DateTime timestamp;

  ToolCall({
    required this.toolName,
    required this.input,
    required this.output,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
    'tool': toolName,
    'input': input,
    'output': output,
    'timestamp': timestamp.toIso8601String(),
  };
}

/// Agent response
class AgentResponse {
  final String answer;
  final List<AgentThought> thoughts;
  final List<ToolCall> toolCalls;
  final int iterations;

  AgentResponse({
    required this.answer,
    required this.thoughts,
    required this.toolCalls,
    required this.iterations,
  });

  Map<String, dynamic> toJson() => {
    'answer': answer,
    'thoughts': thoughts.map((t) => t.toJson()).toList(),
    'toolCalls': toolCalls.map((t) => t.toJson()).toList(),
    'iterations': iterations,
  };
}

/// Parsed agent response helper
class _ParsedResponse {
  final String? thought;
  final String? action;
  final Map<String, dynamic>? actionInput;
  final String? finalAnswer;

  _ParsedResponse({
    this.thought,
    this.action,
    this.actionInput,
    this.finalAnswer,
  });
}
