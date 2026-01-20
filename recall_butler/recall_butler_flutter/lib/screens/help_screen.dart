import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_theme.dart';

/// Comprehensive Help & Guide Screen
class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  String? _expandedSection;

  final List<_HelpSection> _sections = [
    _HelpSection(
      id: 'getting_started',
      icon: LucideIcons.rocket,
      title: 'Getting Started',
      color: AppTheme.accentGold,
      items: [
        _HelpItem(
          title: 'What is Recall Butler?',
          content: 'Recall Butler is your AI-powered personal assistant that helps you remember everything. '
              'Upload documents, paste text, save URLs, and let Butler organize and recall information for you.',
          icon: LucideIcons.brain,
        ),
        _HelpItem(
          title: 'Adding Your First Memory',
          content: '1. Tap the + button at the bottom right\n'
              '2. Choose how to add: Upload, Paste, URL, Voice, or Camera\n'
              '3. Give it a title and submit\n'
              '4. Butler will process and index it for instant recall!',
          icon: LucideIcons.plus,
        ),
        _HelpItem(
          title: 'Searching Your Memories',
          content: 'Go to the Search tab and ask anything in natural language:\n'
              '• "What invoices are due?"\n'
              '• "When is my next appointment?"\n'
              '• "Summarize my meeting notes"\n'
              'Butler uses AI to find relevant information and provide answers.',
          icon: LucideIcons.search,
        ),
      ],
    ),
    _HelpSection(
      id: 'features',
      icon: LucideIcons.sparkles,
      title: 'Features Guide',
      color: Colors.purple,
      items: [
        _HelpItem(
          title: '📥 Memories Tab',
          content: 'Your home base for adding and viewing memories.\n\n'
              '• Upload: Add files (PDF, images, documents)\n'
              '• Paste: Quick paste from clipboard\n'
              '• URL: Save web pages and articles\n'
              '• Recent memories are shown below',
          icon: LucideIcons.inbox,
        ),
        _HelpItem(
          title: '🔍 Search Tab',
          content: 'AI-powered semantic search across all your memories.\n\n'
              '• Ask questions in natural language\n'
              '• Get AI-generated answers with sources\n'
              '• Click results to see full documents\n'
              '• Works offline with cached data!',
          icon: LucideIcons.search,
        ),
        _HelpItem(
          title: '🔔 Activity Tab',
          content: 'Butler\'s proactive suggestions and reminders.\n\n'
              '• Payment reminders extracted from invoices\n'
              '• Follow-up suggestions from emails\n'
              '• Calendar event reminders\n'
              '• Tap Accept or Dismiss to manage',
          icon: LucideIcons.bell,
        ),
        _HelpItem(
          title: '💬 Chat with Butler',
          content: 'Have a conversation with your personal AI assistant.\n\n'
              '• Ask questions about your memories\n'
              '• Get summaries and insights\n'
              '• Natural conversation flow\n'
              '• Tap + → Chat with Butler',
          icon: LucideIcons.messageCircle,
        ),
        _HelpItem(
          title: '🎤 Voice Notes',
          content: 'Capture thoughts hands-free.\n\n'
              '• Tap + → Voice Note\n'
              '• Speak clearly into your microphone\n'
              '• Butler transcribes and saves\n'
              '• Great for meeting notes and ideas!',
          icon: LucideIcons.mic,
        ),
        _HelpItem(
          title: '📷 Scan Documents',
          content: 'Capture text from physical documents.\n\n'
              '• Tap + → Scan Document\n'
              '• Use camera or select from gallery\n'
              '• OCR extracts text automatically\n'
              '• Perfect for receipts and business cards',
          icon: LucideIcons.camera,
        ),
        _HelpItem(
          title: '💚 Mood Check-in',
          content: 'Track your mental wellness.\n\n'
              '• Daily mood tracking with emojis\n'
              '• Tag your feelings\n'
              '• Private journaling\n'
              '• Breathing exercises when you need calm',
          icon: LucideIcons.heart,
        ),
        _HelpItem(
          title: '✨ Personalize',
          content: 'Make Butler work for YOU.\n\n'
              '• Quick profiles: Kids, Senior, Low Vision\n'
              '• Adjust text size (80% - 200%)\n'
              '• High contrast mode\n'
              '• 15+ language options\n'
              '• Voice control settings',
          icon: LucideIcons.sparkles,
        ),
        _HelpItem(
          title: '🔐 Web5 Identity',
          content: 'Own your data with decentralized identity.\n\n'
              '• Create your own DID (Decentralized ID)\n'
              '• Store memories in your Web Node\n'
              '• Share securely with Verifiable Credentials\n'
              '• No vendor lock-in - you control your data!',
          icon: LucideIcons.fingerprint,
        ),
        _HelpItem(
          title: '⚡ Real-time Updates',
          content: 'Stay in sync with live updates.\n\n'
              '• SSE for instant notifications\n'
              '• WebSocket for bidirectional sync\n'
              '• Streaming AI responses\n'
              '• Auto-reconnect when offline',
          icon: LucideIcons.radio,
        ),
      ],
    ),
    _HelpSection(
      id: 'innovations',
      icon: LucideIcons.rocket,
      title: 'Innovation Features',
      color: Colors.blue,
      items: [
        _HelpItem(
          title: '🔗 MCP Protocol',
          content: 'Model Context Protocol integration.\n\n'
              '• 13 AI tools exposed via MCP\n'
              '• Works with Cursor, Claude Desktop\n'
              '• Enterprise-grade AI integration\n'
              '• First hackathon project with MCP!',
          icon: LucideIcons.link,
        ),
        _HelpItem(
          title: '🌐 Web5 Decentralized',
          content: 'Self-sovereign identity & storage.\n\n'
              '• DID (Decentralized Identifier)\n'
              '• DWN (Decentralized Web Node)\n'
              '• Verifiable Credentials for sharing\n'
              '• Your data, your control',
          icon: LucideIcons.globe,
        ),
        _HelpItem(
          title: '🔄 n8n Workflow',
          content: 'Connect to 400+ apps.\n\n'
              '• Visual workflow automation\n'
              '• Webhook triggers for reminders\n'
              '• Sync with Google, Notion, Slack\n'
              '• No-code integrations',
          icon: LucideIcons.workflow,
        ),
        _HelpItem(
          title: '🤖 OpenRouter AI',
          content: 'Multi-model AI access.\n\n'
              '• Claude 3.5 Sonnet (default)\n'
              '• GPT-4, Llama, Gemini available\n'
              '• Semantic search with RAG\n'
              '• Streaming responses',
          icon: LucideIcons.brain,
        ),
      ],
    ),
    _HelpSection(
      id: 'offline',
      icon: LucideIcons.wifiOff,
      title: 'Offline Mode',
      color: AppTheme.statusProcessing,
      items: [
        _HelpItem(
          title: 'Works Without Internet',
          content: 'Recall Butler works even when you\'re offline!\n\n'
              '• View cached documents\n'
              '• Basic text search available\n'
              '• Add new memories (sync later)\n'
              '• Red banner shows offline status',
          icon: LucideIcons.cloudOff,
        ),
        _HelpItem(
          title: 'Auto-Sync',
          content: 'When you reconnect:\n\n'
              '• Pending items sync automatically\n'
              '• Blue banner shows sync progress\n'
              '• No action needed from you!\n'
              '• All data safely backed up',
          icon: LucideIcons.refreshCw,
        ),
      ],
    ),
    _HelpSection(
      id: 'tips',
      icon: LucideIcons.lightbulb,
      title: 'Pro Tips',
      color: AppTheme.accentCopper,
      items: [
        _HelpItem(
          title: 'Best Practices',
          content: '• Add titles that describe content well\n'
              '• Use voice notes for quick capture\n'
              '• Check Activity tab for Butler suggestions\n'
              '• Search using natural questions\n'
              '• Accept helpful reminders, dismiss others',
          icon: LucideIcons.checkCircle,
        ),
        _HelpItem(
          title: 'Keyboard Shortcuts (Web)',
          content: '• Ctrl/Cmd + K: Quick search\n'
              '• Ctrl/Cmd + N: New memory\n'
              '• Ctrl/Cmd + /: Show help\n'
              '• Escape: Close modals',
          icon: LucideIcons.keyboard,
        ),
        _HelpItem(
          title: 'Privacy & Security',
          content: '• All data stored securely\n'
              '• Local cache encrypted\n'
              '• Private journal entries stay private\n'
              '• You control what Butler sees',
          icon: LucideIcons.shield,
        ),
      ],
    ),
    _HelpSection(
      id: 'support',
      icon: LucideIcons.helpCircle,
      title: 'Get Support',
      color: AppTheme.statusReady,
      items: [
        _HelpItem(
          title: 'Contact Us',
          content: 'Need help? We\'re here for you!\n\n'
              '• Email: support@recallbutler.app\n'
              '• Twitter: @RecallButler\n'
              '• In-app feedback: Settings → Send Feedback',
          icon: LucideIcons.mail,
        ),
        _HelpItem(
          title: 'Report a Bug',
          content: 'Found something wrong?\n\n'
              '1. Go to Settings\n'
              '2. Tap "Report Bug"\n'
              '3. Describe what happened\n'
              '4. We\'ll fix it ASAP!',
          icon: LucideIcons.bug,
        ),
        _HelpItem(
          title: 'Feature Request',
          content: 'Have an idea to make Butler better?\n\n'
              '• We love hearing from users!\n'
              '• Submit via Settings → Feature Request\n'
              '• Vote on community suggestions',
          icon: LucideIcons.messageSquarePlus,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.helpCircle, size: 20, color: AppTheme.accentGold),
            const SizedBox(width: 8),
            const Text('Help & Guide'),
          ],
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.accentGold.withOpacity(0.2),
                  AppTheme.accentCopper.withOpacity(0.1),
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppTheme.accentGold.withOpacity(0.3)),
            ),
            child: Column(
              children: [
                const Icon(LucideIcons.brain, size: 48, color: AppTheme.accentGold),
                const SizedBox(height: 12),
                Text(
                  'Welcome to Recall Butler',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your AI-powered personal assistant that never forgets',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

          const SizedBox(height: 24),

          // Quick actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.titleMedium,
          ).animate().fadeIn(delay: 150.ms),
          const SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: _QuickHelpButton(
                  icon: LucideIcons.play,
                  label: 'Watch Tutorial',
                  color: Colors.red,
                  onTap: () => _showTutorial(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _QuickHelpButton(
                  icon: LucideIcons.messageCircle,
                  label: 'Ask Butler',
                  color: AppTheme.accentGold,
                  onTap: () => Navigator.pop(context),
                ),
              ),
            ],
          ).animate().fadeIn(delay: 200.ms),

          const SizedBox(height: 24),

          // Help sections
          ...List.generate(_sections.length, (index) {
            final section = _sections[index];
            final isExpanded = _expandedSection == section.id;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isExpanded 
                      ? section.color.withOpacity(0.5) 
                      : Theme.of(context).colorScheme.outline,
                ),
              ),
              child: Column(
                children: [
                  // Header
                  InkWell(
                    onTap: () {
                      setState(() {
                        _expandedSection = isExpanded ? null : section.id;
                      });
                    },
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: section.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(section.icon, color: section.color, size: 24),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  section.title,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '${section.items.length} topics',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0,
                            duration: const Duration(milliseconds: 200),
                            child: Icon(
                              LucideIcons.chevronDown,
                              color: section.color,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  // Expandable content
                  AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity),
                    secondChild: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      child: Column(
                        children: section.items.map((item) => _buildHelpItem(item, section.color)).toList(),
                      ),
                    ),
                    crossFadeState: isExpanded 
                        ? CrossFadeState.showSecond 
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 200),
                  ),
                ],
              ),
            ).animate().fadeIn(delay: (250 + index * 50).ms);
          }),

          const SizedBox(height: 24),

          // Version info
          Center(
            child: Column(
              children: [
                Text(
                  'Recall Butler v1.0.0',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Built with Flutter + Serverpod',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textMutedDark,
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 500.ms),

          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildHelpItem(_HelpItem item, Color color) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.icon, size: 18, color: color),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showTutorial(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _TutorialModal(),
    );
  }
}

class _QuickHelpButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickHelpButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TutorialModal extends StatefulWidget {
  @override
  State<_TutorialModal> createState() => _TutorialModalState();
}

class _TutorialModalState extends State<_TutorialModal> {
  int _currentStep = 0;

  final List<Map<String, dynamic>> _steps = [
    {
      'title': 'Welcome to Recall Butler! 🎩',
      'content': 'Your AI-powered personal assistant that helps you remember everything important.',
      'icon': LucideIcons.brain,
      'color': AppTheme.accentGold,
    },
    {
      'title': 'Add Memories',
      'content': 'Tap the + button to add memories via text, URL, voice, or camera. Butler organizes everything for you.',
      'icon': LucideIcons.plus,
      'color': Colors.blue,
    },
    {
      'title': 'Search Anything',
      'content': 'Ask questions in plain English. Butler searches across all your memories and provides AI-powered answers.',
      'icon': LucideIcons.search,
      'color': Colors.purple,
    },
    {
      'title': 'Get Reminders',
      'content': 'Butler proactively suggests reminders, follow-ups, and actions based on your documents.',
      'icon': LucideIcons.bell,
      'color': AppTheme.accentCopper,
    },
    {
      'title': 'Personalize Your Experience',
      'content': 'Make Butler work for you with accessibility options, language settings, and display preferences.',
      'icon': LucideIcons.sparkles,
      'color': Colors.deepPurple,
    },
    {
      'title': 'You\'re Ready! 🚀',
      'content': 'Start adding your first memory and experience the power of AI-assisted recall.',
      'icon': LucideIcons.checkCircle,
      'color': AppTheme.statusReady,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final step = _steps[_currentStep];
    
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey[600],
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: (step['color'] as Color).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      step['icon'] as IconData,
                      size: 48,
                      color: step['color'] as Color,
                    ),
                  ).animate().scale(duration: 300.ms),
                  const SizedBox(height: 24),
                  Text(
                    step['title'] as String,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 16),
                  Text(
                    step['content'] as String,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ).animate().fadeIn(delay: 200.ms),
                  const Spacer(),
                  // Progress dots
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_steps.length, (index) {
                      return Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: index == _currentStep ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: index == _currentStep 
                              ? step['color'] as Color 
                              : Colors.grey[600],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 24),
                  // Navigation buttons
                  Row(
                    children: [
                      if (_currentStep > 0)
                        TextButton(
                          onPressed: () {
                            setState(() => _currentStep--);
                          },
                          child: const Text('Back'),
                        )
                      else
                        const SizedBox(width: 80),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () {
                          if (_currentStep < _steps.length - 1) {
                            setState(() => _currentStep++);
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: step['color'] as Color,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                        ),
                        child: Text(
                          _currentStep < _steps.length - 1 ? 'Next' : 'Get Started',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpSection {
  final String id;
  final IconData icon;
  final String title;
  final Color color;
  final List<_HelpItem> items;

  const _HelpSection({
    required this.id,
    required this.icon,
    required this.title,
    required this.color,
    required this.items,
  });
}

class _HelpItem {
  final String title;
  final String content;
  final IconData icon;

  const _HelpItem({
    required this.title,
    required this.content,
    required this.icon,
  });
}
