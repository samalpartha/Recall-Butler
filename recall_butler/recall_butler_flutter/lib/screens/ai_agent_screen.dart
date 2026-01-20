import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_theme.dart';

/// AI Agent Screen - Interactive AI assistant with tool visualization
class AiAgentScreen extends StatefulWidget {
  const AiAgentScreen({super.key});

  @override
  State<AiAgentScreen> createState() => _AiAgentScreenState();
}

class _AiAgentScreenState extends State<AiAgentScreen> with TickerProviderStateMixin {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<AgentMessage> _messages = [];
  bool _isProcessing = false;
  String? _currentTool;
  List<String> _thinkingSteps = [];

  final List<Map<String, dynamic>> _availableTools = [
    {'name': 'search_memories', 'icon': LucideIcons.search, 'color': AppTheme.accentTeal},
    {'name': 'check_calendar', 'icon': LucideIcons.calendar, 'color': Colors.blue},
    {'name': 'create_reminder', 'icon': LucideIcons.bell, 'color': Colors.orange},
    {'name': 'find_connections', 'icon': LucideIcons.network, 'color': Colors.purple},
    {'name': 'summarize', 'icon': LucideIcons.fileText, 'color': Colors.green},
    {'name': 'get_insights', 'icon': LucideIcons.barChart3, 'color': AppTheme.accentGold},
  ];

  @override
  void initState() {
    super.initState();
    // Add welcome message
    _messages.add(AgentMessage(
      role: 'assistant',
      content: "Hello! I'm your AI Agent. I can help you with complex tasks by using multiple tools. Try asking me something like:\n\n"
          "• \"Find documents about the project and create reminders\"\n"
          "• \"What insights can you give me about my work this week?\"\n"
          "• \"Search for meeting notes and summarize them\"",
      timestamp: DateTime.now(),
    ));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isProcessing) return;

    setState(() {
      _messages.add(AgentMessage(
        role: 'user',
        content: text,
        timestamp: DateTime.now(),
      ));
      _isProcessing = true;
      _thinkingSteps = [];
      _messageController.clear();
    });

    _scrollToBottom();

    // Simulate agent processing with tool use
    await _simulateAgentProcessing(text);
  }

  Future<void> _simulateAgentProcessing(String query) async {
    // Step 1: Thinking
    await _addThinkingStep("Analyzing your request...");
    await Future.delayed(const Duration(milliseconds: 800));

    // Step 2: Tool selection
    setState(() => _currentTool = 'search_memories');
    await _addThinkingStep("Using search_memories tool to find relevant documents...");
    await Future.delayed(const Duration(milliseconds: 1200));

    // Step 3: Another tool
    setState(() => _currentTool = 'find_connections');
    await _addThinkingStep("Finding connections between documents...");
    await Future.delayed(const Duration(milliseconds: 1000));

    // Step 4: Insights
    if (query.toLowerCase().contains('remind') || query.toLowerCase().contains('task')) {
      setState(() => _currentTool = 'create_reminder');
      await _addThinkingStep("Creating smart reminders based on findings...");
      await Future.delayed(const Duration(milliseconds: 800));
    }

    // Final response
    setState(() {
      _currentTool = null;
      _isProcessing = false;
      _messages.add(AgentMessage(
        role: 'assistant',
        content: _generateAgentResponse(query),
        timestamp: DateTime.now(),
        toolsUsed: ['search_memories', 'find_connections'],
        thinkingSteps: List.from(_thinkingSteps),
      ));
      _thinkingSteps = [];
    });

    _scrollToBottom();
  }

  Future<void> _addThinkingStep(String step) async {
    setState(() {
      _thinkingSteps.add(step);
    });
    _scrollToBottom();
  }

  String _generateAgentResponse(String query) {
    if (query.toLowerCase().contains('project')) {
      return "Based on my search, I found **5 documents** related to your project:\n\n"
          "1. **Project Alpha Roadmap** - Last updated 2 days ago\n"
          "2. **Meeting Notes Jan 15** - Contains action items\n"
          "3. **Technical Specs v2** - Referenced in 3 other documents\n\n"
          "🔗 I also found connections to **Budget Planning** and **Team Resources**.\n\n"
          "Would you like me to create reminders for the action items I found?";
    }
    return "I've analyzed your memories and found some interesting insights:\n\n"
        "📊 **This week's highlights:**\n"
        "• 12 new memories captured\n"
        "• Most active topic: Work (45%)\n"
        "• 3 potential connections discovered\n\n"
        "💡 **Suggestions:**\n"
        "• Review the 2 pending suggestions in your inbox\n"
        "• Consider linking 'Q1 Goals' with your recent notes\n\n"
        "Is there anything specific you'd like me to help with?";
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Tool Status Bar
          _buildToolStatusBar(),
          
          // Messages
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_isProcessing ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length && _isProcessing) {
                  return _buildThinkingIndicator();
                }
                return _buildMessageBubble(_messages[index], index);
              },
            ),
          ),
          
          // Input
          _buildInputArea(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryDark,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppTheme.accentGold, AppTheme.accentCopper],
              ),
            ),
            child: const Icon(LucideIcons.bot, color: Colors.black, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'AI Agent',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                _isProcessing ? 'Thinking...' : 'Online',
                style: TextStyle(
                  fontSize: 12,
                  color: _isProcessing ? AppTheme.accentGold : Colors.green,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(LucideIcons.settings2),
          onPressed: () {},
          tooltip: 'Agent Settings',
        ),
      ],
    );
  }

  Widget _buildToolStatusBar() {
    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          bottom: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          Text(
            'Available Tools:',
            style: TextStyle(color: AppTheme.textMutedDark, fontSize: 12),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: _availableTools.map((tool) {
                  final isActive = _currentTool == tool['name'];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: isActive
                          ? (tool['color'] as Color).withOpacity(0.3)
                          : Colors.white.withOpacity(0.05),
                        border: Border.all(
                          color: isActive
                            ? tool['color'] as Color
                            : Colors.white.withOpacity(0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isActive)
                            const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation(Colors.white),
                              ),
                            )
                          else
                            Icon(
                              tool['icon'] as IconData,
                              size: 14,
                              color: tool['color'] as Color,
                            ),
                          const SizedBox(width: 6),
                          Text(
                            (tool['name'] as String).replaceAll('_', ' '),
                            style: TextStyle(
                              fontSize: 11,
                              color: isActive ? Colors.white : AppTheme.textMutedDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(AgentMessage message, int index) {
    final isUser = message.role == 'user';
    
    return Padding(
      padding: EdgeInsets.only(
        bottom: 16,
        left: isUser ? 48 : 0,
        right: isUser ? 0 : 48,
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          // Show tools used
          if (!isUser && message.toolsUsed != null && message.toolsUsed!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Wrap(
                spacing: 6,
                children: message.toolsUsed!.map((tool) {
                  final toolData = _availableTools.firstWhere(
                    (t) => t['name'] == tool,
                    orElse: () => {'icon': LucideIcons.circle, 'color': Colors.grey},
                  );
                  return Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: (toolData['color'] as Color).withOpacity(0.2),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          toolData['icon'] as IconData,
                          size: 12,
                          color: toolData['color'] as Color,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          tool.replaceAll('_', ' '),
                          style: TextStyle(
                            fontSize: 10,
                            color: toolData['color'] as Color,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          
          // Message bubble
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 20),
              ),
              gradient: isUser
                ? LinearGradient(
                    colors: [AppTheme.accentGold, AppTheme.accentCopper],
                  )
                : null,
              color: isUser ? null : AppTheme.surfaceDark,
              border: isUser ? null : Border.all(color: Colors.white.withOpacity(0.05)),
            ),
            child: Text(
              message.content,
              style: TextStyle(
                color: isUser ? Colors.black : Colors.white,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
          
          // Timestamp
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _formatTime(message.timestamp),
              style: TextStyle(
                fontSize: 10,
                color: AppTheme.textMutedDark,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
  }

  Widget _buildThinkingIndicator() {
    return Container(
      margin: const EdgeInsets.only(right: 48, bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: AppTheme.surfaceDark,
        border: Border.all(color: AppTheme.accentGold.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(AppTheme.accentGold),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Agent is thinking...',
                style: TextStyle(
                  color: AppTheme.accentGold,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          if (_thinkingSteps.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...List.generate(_thinkingSteps.length, (index) {
              return Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Row(
                  children: [
                    Icon(
                      index == _thinkingSteps.length - 1
                        ? LucideIcons.loader2
                        : LucideIcons.checkCircle,
                      size: 14,
                      color: index == _thinkingSteps.length - 1
                        ? AppTheme.accentGold
                        : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _thinkingSteps[index],
                        style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.textMutedDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn();
            }),
          ],
        ],
      ),
    ).animate().fadeIn();
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(color: Colors.white.withOpacity(0.05)),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // Suggested actions
            IconButton(
              icon: Icon(LucideIcons.sparkles, color: AppTheme.accentGold),
              onPressed: () => _showSuggestions(),
              tooltip: 'Suggestions',
            ),
            
            // Input field
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  color: Colors.white.withOpacity(0.05),
                  border: Border.all(color: Colors.white.withOpacity(0.1)),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Ask the AI Agent...',
                    hintStyle: TextStyle(color: AppTheme.textMutedDark),
                    border: InputBorder.none,
                  ),
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            
            const SizedBox(width: 8),
            
            // Send button
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppTheme.accentGold, AppTheme.accentCopper],
                ),
              ),
              child: IconButton(
                icon: Icon(
                  _isProcessing ? LucideIcons.loader2 : LucideIcons.send,
                  color: Colors.black,
                ),
                onPressed: _isProcessing ? null : _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSuggestions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...[
              'Find all documents from this week',
              'Create reminders from my recent notes',
              'Show insights about my work patterns',
              'Find connections between my projects',
            ].map((suggestion) => ListTile(
              leading: Icon(LucideIcons.sparkles, color: AppTheme.accentGold),
              title: Text(suggestion),
              onTap: () {
                Navigator.pop(context);
                _messageController.text = suggestion;
                _sendMessage();
              },
            )),
          ],
        ),
      ),
    );
  }

  String _formatTime(DateTime time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}

class AgentMessage {
  final String role;
  final String content;
  final DateTime timestamp;
  final List<String>? toolsUsed;
  final List<String>? thinkingSteps;

  AgentMessage({
    required this.role,
    required this.content,
    required this.timestamp,
    this.toolsUsed,
    this.thinkingSteps,
  });
}
