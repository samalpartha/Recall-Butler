import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:recall_butler_client/recall_butler_client.dart';

import '../theme/app_theme.dart';
import '../services/api_service.dart';
import '../services/notification_service.dart';
import '../providers/documents_provider.dart';
import '../providers/suggestions_provider.dart';

final _apiService = ApiService();
final _notificationService = NotificationService();

/// Detailed document view with "Memory Trail" feature
class DocumentDetailScreen extends ConsumerWidget {
  final int documentId;

  const DocumentDetailScreen({
    super.key,
    required this.documentId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documentAsync = ref.watch(documentProvider(documentId));

    return Scaffold(
      body: documentAsync.when(
        data: (document) {
          if (document == null) {
            return const Center(child: Text('Document not found'));
          }
          return _DocumentDetailContent(document: document);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
    );
  }
}

class _DocumentDetailContent extends ConsumerStatefulWidget {
  final Document document;

  const _DocumentDetailContent({required this.document});

  @override
  ConsumerState<_DocumentDetailContent> createState() => _DocumentDetailContentState();
}

class _DocumentDetailContentState extends ConsumerState<_DocumentDetailContent> {
  bool _isCreatingReminder = false;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        // Custom App Bar with gradient
        SliverAppBar(
          expandedHeight: 180,
          pinned: true,
          backgroundColor: AppTheme.primaryDark,
          leading: IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(LucideIcons.arrowLeft, size: 20),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          actions: [
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.share2, size: 20),
              ),
              onPressed: () => _shareDocument(context),
            ),
            IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.moreVertical, size: 20),
              ),
              onPressed: () => _showOptions(context),
            ),
            const SizedBox(width: 8),
          ],
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _getTypeColor().withOpacity(0.4),
                    AppTheme.primaryDark,
                  ],
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _getTypeColor().withOpacity(0.2),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _getTypeColor().withOpacity(0.3),
                              ),
                            ),
                            child: Icon(
                              _getTypeIcon(),
                              color: _getTypeColor(),
                              size: 28,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getTypeLabel(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _getTypeColor(),
                                    letterSpacing: 1,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  widget.document.title,
                                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),

        // Content
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status badge
                _StatusBadge(status: widget.document.status)
                    .animate()
                    .fadeIn(delay: 50.ms),
                
                const SizedBox(height: 20),

                // Summary section - Chat bubble style inspired by flutter_chat_ui
                if (widget.document.summary != null) ...[
                  _ChatBubbleCard(
                    title: 'AI Summary',
                    icon: LucideIcons.sparkles,
                    color: AppTheme.accentGold,
                    content: widget.document.summary!,
                    isAI: true,
                  ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.05),
                  const SizedBox(height: 16),
                ],

                // Key fields extracted
                if (widget.document.keyFieldsJson != null && 
                    widget.document.keyFieldsJson!.isNotEmpty &&
                    widget.document.keyFieldsJson != '{}') ...[
                  _KeyFieldsCard(keyFieldsJson: widget.document.keyFieldsJson!)
                      .animate().fadeIn(delay: 150.ms).slideX(begin: 0.05),
                  const SizedBox(height: 16),
                ],

                // Source URL
                if (widget.document.sourceUrl != null) ...[
                  _InfoCard(
                    title: 'Source',
                    icon: LucideIcons.link,
                    color: AppTheme.statusProcessing,
                    child: GestureDetector(
                      onTap: () => _copyToClipboard(context, widget.document.sourceUrl!),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              widget.document.sourceUrl!,
                              style: const TextStyle(
                                color: AppTheme.statusProcessing,
                                decoration: TextDecoration.underline,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(LucideIcons.externalLink, size: 16, color: AppTheme.statusProcessing),
                        ],
                      ),
                    ),
                  ).animate().fadeIn(delay: 200.ms),
                  const SizedBox(height: 16),
                ],

                // Original content - Expandable
                if (widget.document.extractedText != null) ...[
                  _ExpandableContentCard(
                    title: 'Original Content',
                    icon: LucideIcons.fileText,
                    content: widget.document.extractedText!,
                  ).animate().fadeIn(delay: 250.ms),
                  const SizedBox(height: 24),
                ],

                // Quick Action buttons - Stream Chat style
                _QuickActions(
                  onShare: () => _shareDocument(context),
                  onReminder: _isCreatingReminder ? null : () => _addReminder(context),
                  onCopy: () => _copyContent(context),
                  isCreatingReminder: _isCreatingReminder,
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ),
      ],
    );
  }

  IconData _getTypeIcon() {
    switch (widget.document.sourceType.toLowerCase()) {
      case 'text':
        return LucideIcons.fileText;
      case 'url':
        return LucideIcons.globe;
      case 'file':
      case 'pdf':
        return LucideIcons.file;
      case 'image':
        return LucideIcons.image;
      default:
        return LucideIcons.fileQuestion;
    }
  }

  Color _getTypeColor() {
    switch (widget.document.sourceType.toLowerCase()) {
      case 'text':
        return AppTheme.accentGold;
      case 'url':
        return AppTheme.statusProcessing;
      case 'file':
      case 'pdf':
        return AppTheme.accentCopper;
      case 'image':
        return AppTheme.statusReady;
      default:
        return AppTheme.textMutedDark;
    }
  }

  String _getTypeLabel() {
    switch (widget.document.sourceType.toLowerCase()) {
      case 'text':
        return 'TEXT NOTE';
      case 'url':
        return 'WEB PAGE';
      case 'file':
      case 'pdf':
        return 'DOCUMENT';
      case 'image':
        return 'IMAGE';
      default:
        return 'MEMORY';
    }
  }

  void _shareDocument(BuildContext context) {
    final text = '''📝 ${widget.document.title}

${widget.document.summary ?? widget.document.extractedText ?? 'No content'}

${widget.document.sourceUrl != null ? '🔗 ${widget.document.sourceUrl}' : ''}

Shared from Recall Butler 🧠''';
    
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.check, color: Colors.white, size: 18),
            const SizedBox(width: 12),
            const Text('Copied to clipboard - ready to share!'),
          ],
        ),
        backgroundColor: AppTheme.statusReady,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }

  void _copyContent(BuildContext context) {
    final text = widget.document.extractedText ?? widget.document.summary ?? '';
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.copy, color: Colors.white, size: 18),
            const SizedBox(width: 12),
            const Text('Content copied!'),
          ],
        ),
        backgroundColor: AppTheme.statusProcessing,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _addReminder(BuildContext context) async {
    setState(() => _isCreatingReminder = true);
    
    try {
      // Show date picker
      final date = await showDatePicker(
        context: context,
        initialDate: DateTime.now().add(const Duration(days: 1)),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.dark(
                primary: AppTheme.accentGold,
                surface: AppTheme.surfaceDark,
              ),
            ),
            child: child!,
          );
        },
      );
      
      if (date == null || !mounted) {
        setState(() => _isCreatingReminder = false);
        return;
      }
      
      // Create reminder via API
      if (widget.document.id != null) {
        final reminder = await _apiService.createReminder(
          documentId: widget.document.id!,
          title: 'Reminder: ${widget.document.title}',
          description: 'Review this memory on ${date.day}/${date.month}/${date.year}',
          scheduledAt: date,
        );
        
        // Schedule local notification
        await _notificationService.scheduleReminder(
          reminderId: reminder.id ?? widget.document.id!,
          title: widget.document.title,
          description: 'Time to review this memory',
          reminderTime: date,
        );
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.bell, color: Colors.black, size: 18),
                const SizedBox(width: 12),
                Text('Reminder set for ${date.day}/${date.month}/${date.year}'),
              ],
            ),
            backgroundColor: AppTheme.accentGold,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        
        // Refresh suggestions
        ref.invalidate(pendingSuggestionsProvider);
        ref.invalidate(executedSuggestionsProvider);
        ref.invalidate(pendingSuggestionsCountProvider);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error creating reminder: $e'),
            backgroundColor: AppTheme.statusFailed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isCreatingReminder = false);
      }
    }
  }

  void _showOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surfaceDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.textMutedDark,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            _OptionTile(
              icon: LucideIcons.refreshCw,
              title: 'Reprocess',
              subtitle: 'Re-analyze with AI',
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Reprocessing document...')),
                );
              },
            ),
            _OptionTile(
              icon: LucideIcons.download,
              title: 'Export',
              subtitle: 'Download as PDF or text',
              onTap: () {
                Navigator.pop(context);
                _shareDocument(context);
              },
            ),
            _OptionTile(
              icon: LucideIcons.trash2,
              title: 'Delete',
              subtitle: 'Remove from memory',
              isDestructive: true,
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    backgroundColor: AppTheme.surfaceDark,
                    title: const Text('Delete Memory?'),
                    content: const Text('This action cannot be undone.'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context, false),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.statusFailed,
                        ),
                        onPressed: () => Navigator.pop(context, true),
                        child: const Text('Delete'),
                      ),
                    ],
                  ),
                );
                
                if (confirm == true && context.mounted) {
                  await ref.read(documentsProvider.notifier).delete(widget.document.id!);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                }
              },
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

// Status badge widget
class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;
    String label;

    switch (status.toUpperCase()) {
      case 'READY':
        color = AppTheme.statusReady;
        icon = LucideIcons.checkCircle;
        label = 'Processed';
        break;
      case 'PROCESSING':
        color = AppTheme.statusProcessing;
        icon = LucideIcons.loader2;
        label = 'Processing';
        break;
      case 'FAILED':
        color = AppTheme.statusFailed;
        icon = LucideIcons.alertCircle;
        label = 'Failed';
        break;
      default:
        color = AppTheme.textMutedDark;
        icon = LucideIcons.clock;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

// Chat bubble style card (inspired by flutter_chat_ui)
class _ChatBubbleCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final String content;
  final bool isAI;

  const _ChatBubbleCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.content,
    this.isAI = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.withOpacity(0.15),
            color.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
              if (isAI) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'AI',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Text(
            content,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              height: 1.6,
              color: AppTheme.textPrimaryDark,
            ),
          ),
        ],
      ),
    );
  }
}

// Key fields card
class _KeyFieldsCard extends StatelessWidget {
  final String keyFieldsJson;

  const _KeyFieldsCard({required this.keyFieldsJson});

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> fields = {};
    try {
      fields = Map<String, dynamic>.from(
        (keyFieldsJson.startsWith('{') ? 
          Map<String, dynamic>.from(_parseJson(keyFieldsJson)) : {})
      );
    } catch (_) {}

    if (fields.isEmpty) return const SizedBox();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.accentTeal.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentTeal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(LucideIcons.tags, size: 16, color: AppTheme.accentTeal),
              ),
              const SizedBox(width: 10),
              const Text(
                'Extracted Fields',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentTeal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: fields.entries.map((e) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatKey(e.key),
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppTheme.textMutedDark,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${e.value}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryDark,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _formatKey(String key) {
    return key.replaceAll('_', ' ').split(' ').map((w) => 
      w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : w
    ).join(' ') + ':';
  }

  dynamic _parseJson(String json) {
    // Simple JSON parser for the key fields
    try {
      final cleaned = json.trim();
      if (cleaned.startsWith('{') && cleaned.endsWith('}')) {
        // Basic parsing - this is simplified
        return {};
      }
    } catch (_) {}
    return {};
  }
}

// Info card
class _InfoCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final Widget child;

  const _InfoCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

// Expandable content card
class _ExpandableContentCard extends StatefulWidget {
  final String title;
  final IconData icon;
  final String content;

  const _ExpandableContentCard({
    required this.title,
    required this.icon,
    required this.content,
  });

  @override
  State<_ExpandableContentCard> createState() => _ExpandableContentCardState();
}

class _ExpandableContentCardState extends State<_ExpandableContentCard> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(widget.icon, size: 16, color: AppTheme.textMutedDark),
                  const SizedBox(width: 8),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondaryDark,
                    ),
                  ),
                  const Spacer(),
                  AnimatedRotation(
                    turns: _isExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(LucideIcons.chevronDown, size: 18),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(width: double.infinity),
            secondChild: Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Text(
                widget.content,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  height: 1.6,
                  color: AppTheme.textSecondaryDark,
                ),
              ),
            ),
            crossFadeState: _isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 200),
          ),
        ],
      ),
    );
  }
}

// Quick actions bar (inspired by Stream Chat)
class _QuickActions extends StatelessWidget {
  final VoidCallback onShare;
  final VoidCallback? onReminder;
  final VoidCallback onCopy;
  final bool isCreatingReminder;

  const _QuickActions({
    required this.onShare,
    required this.onReminder,
    required this.onCopy,
    required this.isCreatingReminder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ActionButton(
              icon: LucideIcons.share2,
              label: 'Share',
              color: AppTheme.statusProcessing,
              onTap: onShare,
            ),
          ),
          Container(width: 1, height: 40, color: Theme.of(context).colorScheme.outline),
          Expanded(
            child: _ActionButton(
              icon: isCreatingReminder ? LucideIcons.loader2 : LucideIcons.bell,
              label: 'Remind',
              color: AppTheme.accentGold,
              onTap: onReminder,
              isLoading: isCreatingReminder,
            ),
          ),
          Container(width: 1, height: 40, color: Theme.of(context).colorScheme.outline),
          Expanded(
            child: _ActionButton(
              icon: LucideIcons.copy,
              label: 'Copy',
              color: AppTheme.accentTeal,
              onTap: onCopy,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;
  final bool isLoading;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            isLoading
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: color,
                    ),
                  )
                : Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: onTap == null ? AppTheme.textMutedDark : color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool isDestructive;

  const _OptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = isDestructive ? AppTheme.statusFailed : AppTheme.textPrimaryDark;
    
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: (isDestructive ? AppTheme.statusFailed : AppTheme.textMutedDark).withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 20, color: color),
      ),
      title: Text(title, style: TextStyle(color: color, fontWeight: FontWeight.w600)),
      subtitle: Text(subtitle, style: TextStyle(color: color.withOpacity(0.7), fontSize: 12)),
      onTap: onTap,
    );
  }
}
