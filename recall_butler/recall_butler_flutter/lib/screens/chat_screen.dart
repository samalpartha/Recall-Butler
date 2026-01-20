import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:uuid/uuid.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/conversation_memory_service.dart';

/// Provider for conversation memory service
final conversationMemoryProvider = Provider<ConversationMemoryService>((ref) {
  final service = ConversationMemoryService();
  service.initialize();
  return service;
});

/// Chat message model
class ChatMessage {
  final String id;
  final String text;
  final bool isUser;
  final DateTime timestamp;
  final List<String>? sources;

  ChatMessage({
    required this.id,
    required this.text,
    required this.isUser,
    required this.timestamp,
    this.sources,
  });
}

/// Provider for chat messages
final chatMessagesProvider = StateNotifierProvider<ChatMessagesNotifier, List<ChatMessage>>((ref) {
  return ChatMessagesNotifier();
});

class ChatMessagesNotifier extends StateNotifier<List<ChatMessage>> {
  ChatMessagesNotifier() : super([
    ChatMessage(
      id: const Uuid().v4(),
      text: "Hello! I'm your Butler. Ask me anything about your saved memories. For example:\n\n• \"When is my next appointment?\"\n• \"What invoices are due this month?\"\n• \"Summarize my recent notes\"",
      isUser: false,
      timestamp: DateTime.now(),
    ),
  ]);

  void addMessage(ChatMessage message) {
    state = [...state, message];
  }

  void clear() {
    state = [
      ChatMessage(
        id: const Uuid().v4(),
        text: "Hello! I'm your Butler. Ask me anything about your saved memories.",
        isUser: false,
        timestamp: DateTime.now(),
      ),
    ];
  }
}

/// Chat screen - conversational AI interface
class ChatScreen extends ConsumerStatefulWidget {
  const ChatScreen({super.key});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final FocusNode _focusNode = FocusNode();
  bool _isLoading = false;
  final _api = ApiService();

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _focusNode.dispose();
    super.dispose();
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

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || _isLoading) return;

    _messageController.clear();
    _focusNode.requestFocus();

    // Save to conversation memory
    final memory = ref.read(conversationMemoryProvider);
    await memory.addUserMessage(text);

    // Add user message
    final userMessage = ChatMessage(
      id: const Uuid().v4(),
      text: text,
      isUser: true,
      timestamp: DateTime.now(),
    );
    ref.read(chatMessagesProvider.notifier).addMessage(userMessage);
    _scrollToBottom();

    setState(() => _isLoading = true);

    try {
      // Get conversation context for better AI responses
      final context = memory.getContextForAI(maxMessages: 5);
      
      // Get AI response from search (with context)
      final response = await _api.search(text);
      
      // Build response with sources
      final sources = response.results
          .take(3)
          .map((r) => '📄 ${r.title}')
          .toList();

      final botMessage = ChatMessage(
        id: const Uuid().v4(),
        text: response.answer,
        isUser: false,
        timestamp: DateTime.now(),
        sources: sources.isNotEmpty ? sources : null,
      );
      
      // Save assistant response to memory
      await memory.addAssistantMessage(
        response.answer,
        relatedDocumentIds: response.results.map((r) => r.documentId.toString()).toList(),
      );
      
      ref.read(chatMessagesProvider.notifier).addMessage(botMessage);
      _scrollToBottom();
    } catch (e) {
      final errorMessage = ChatMessage(
        id: const Uuid().v4(),
        text: "I'm sorry, I couldn't process that request. Please try again.",
        isUser: false,
        timestamp: DateTime.now(),
      );
      ref.read(chatMessagesProvider.notifier).addMessage(errorMessage);
    } finally {
      setState(() => _isLoading = false);
      _scrollToBottom();
    }
  }

  void _showConversationHistory(BuildContext context) {
    final memory = ref.read(conversationMemoryProvider);
    final sessions = memory.sessions;
    final stats = memory.getStatistics();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMutedDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(LucideIcons.history, color: AppTheme.accentGold),
                  const SizedBox(width: 12),
                  Text(
                    'Conversation History',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.cardDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${stats['totalSessions']} chats',
                      style: TextStyle(
                        color: AppTheme.textMutedDark,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Sessions list
            Expanded(
              child: sessions.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            LucideIcons.messageCircle,
                            size: 48,
                            color: AppTheme.textMutedDark,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'No conversation history yet',
                            style: TextStyle(color: AppTheme.textSecondaryDark),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) {
                        final session = sessions[index];
                        return _ConversationHistoryItem(
                          session: session,
                          onTap: () {
                            Navigator.pop(context);
                            // Could load this conversation
                          },
                          onDelete: () async {
                            await memory.deleteSession(session.id);
                            Navigator.pop(context);
                            _showConversationHistory(context);
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatMessagesProvider);

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.arrowLeft),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.accentGold, AppTheme.accentCopper],
                ),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.bot, size: 20, color: Colors.black),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Butler',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                Text(
                  'Ask me anything',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textMutedDark,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(LucideIcons.history, size: 20),
            onPressed: () => _showConversationHistory(context),
            tooltip: 'Conversation history',
          ),
          IconButton(
            icon: const Icon(LucideIcons.trash2, size: 20),
            onPressed: () {
              ref.read(chatMessagesProvider.notifier).clear();
            },
            tooltip: 'Clear chat',
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages list
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (_isLoading && index == messages.length) {
                  return _TypingIndicator();
                }
                return _MessageBubble(
                  message: messages[index],
                  showAnimation: index == messages.length - 1,
                );
              },
            ),
          ),

          // Quick suggestions
          if (messages.length <= 1)
            _QuickSuggestions(
              onTap: (text) {
                _messageController.text = text;
                _sendMessage();
              },
            ),

          // Input area
          _InputArea(
            controller: _messageController,
            focusNode: _focusNode,
            isLoading: _isLoading,
            onSend: _sendMessage,
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool showAnimation;

  const _MessageBubble({
    required this.message,
    this.showAnimation = false,
  });

  @override
  Widget build(BuildContext context) {
    final isUser = message.isUser;

    Widget bubble = Container(
      margin: EdgeInsets.only(
        top: 8,
        bottom: 8,
        left: isUser ? 60 : 0,
        right: isUser ? 0 : 60,
      ),
      child: Column(
        crossAxisAlignment: isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isUser 
                  ? AppTheme.accentGold.withOpacity(0.2)
                  : AppTheme.cardDark,
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 4),
                bottomRight: Radius.circular(isUser ? 4 : 20),
              ),
              border: Border.all(
                color: isUser
                    ? AppTheme.accentGold.withOpacity(0.3)
                    : AppTheme.surfaceDark,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!isUser)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LucideIcons.bot,
                          size: 14,
                          color: AppTheme.accentGold,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Butler',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.accentGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                SelectableText(
                  message.text,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
                ),
                if (message.sources != null && message.sources!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              LucideIcons.fileText,
                              size: 12,
                              color: AppTheme.textMutedDark,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Sources',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.textMutedDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        ...message.sources!.map((s) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            s,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.textSecondaryDark,
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    if (showAnimation) {
      return bubble.animate().fadeIn(duration: 300.ms).slideY(begin: 0.1);
    }
    return bubble;
  }
}

class _TypingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 60, top: 8, bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
          bottomRight: Radius.circular(20),
          bottomLeft: Radius.circular(4),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _Dot(delay: 0),
          const SizedBox(width: 4),
          _Dot(delay: 200),
          const SizedBox(width: 4),
          _Dot(delay: 400),
        ],
      ),
    ).animate().fadeIn();
  }
}

class _Dot extends StatelessWidget {
  final int delay;

  const _Dot({required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: AppTheme.accentGold,
        shape: BoxShape.circle,
      ),
    ).animate(onPlay: (c) => c.repeat())
      .fadeIn(delay: Duration(milliseconds: delay), duration: 300.ms)
      .then()
      .fadeOut(duration: 300.ms);
  }
}

class _QuickSuggestions extends StatelessWidget {
  final Function(String) onTap;

  const _QuickSuggestions({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      '📅 What appointments do I have?',
      '💰 Show my pending invoices',
      '📝 Summarize my recent notes',
      '🔔 What reminders are set?',
    ];

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.map((s) {
          return ActionChip(
            label: Text(s, style: const TextStyle(fontSize: 12)),
            backgroundColor: AppTheme.cardDark,
            side: BorderSide(color: AppTheme.surfaceDark),
            onPressed: () => onTap(s),
          );
        }).toList(),
      ),
    ).animate().fadeIn(delay: 500.ms);
  }
}

class _ConversationHistoryItem extends StatelessWidget {
  final ConversationSession session;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _ConversationHistoryItem({
    required this.session,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, h:mm a');
    final messageCount = session.messages.length;
    final lastMessage = session.messages.isNotEmpty 
        ? session.messages.last.content 
        : 'No messages';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.accentGold.withOpacity(0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            LucideIcons.messageCircle,
            color: AppTheme.accentGold,
            size: 20,
          ),
        ),
        title: Text(
          session.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleSmall,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              lastMessage,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppTheme.textMutedDark,
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  dateFormat.format(session.lastMessageAt),
                  style: TextStyle(
                    color: AppTheme.textMutedDark,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '$messageCount msgs',
                    style: TextStyle(
                      color: AppTheme.textMutedDark,
                      fontSize: 10,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: IconButton(
          icon: Icon(LucideIcons.trash2, size: 18, color: AppTheme.textMutedDark),
          onPressed: onDelete,
        ),
      ),
    );
  }
}

class _InputArea extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isLoading;
  final VoidCallback onSend;

  const _InputArea({
    required this.controller,
    required this.focusNode,
    required this.isLoading,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        border: Border(
          top: BorderSide(color: AppTheme.cardDark),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  onSubmitted: (_) => onSend(),
                  textInputAction: TextInputAction.send,
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'Ask Butler anything...',
                    hintStyle: TextStyle(color: AppTheme.textMutedDark),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: isLoading ? null : onSend,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: isLoading
                        ? [AppTheme.textMutedDark, AppTheme.textMutedDark]
                        : [AppTheme.accentGold, AppTheme.accentCopper],
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Icon(
                  isLoading ? LucideIcons.loader2 : LucideIcons.send,
                  color: Colors.black,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
