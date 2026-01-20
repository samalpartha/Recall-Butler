import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:recall_butler_client/recall_butler_client.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';
import '../screens/document_detail_screen.dart';

class DocumentCard extends StatelessWidget {
  final Document document;
  final VoidCallback? onTap;

  const DocumentCard({
    super.key,
    required this.document,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap ?? () => _showDocumentDetail(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: document.isProcessing
                ? AppTheme.statusProcessing.withOpacity(0.3)
                : Theme.of(context).colorScheme.outline,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _SourceIcon(sourceType: document.sourceType),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        document.title,
                        style: Theme.of(context).textTheme.titleMedium,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeago.format(document.createdAt),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                _StatusBadge(status: document.status),
              ],
            ),
            if (document.summary != null && document.summary!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                document.summary!,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  height: 1.5,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            if (document.isProcessing) ...[
              const SizedBox(height: 12),
              LinearProgressIndicator(
                backgroundColor: AppTheme.statusProcessing.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation(AppTheme.statusProcessing),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _showDocumentDetail(BuildContext context) {
    if (document.id != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DocumentDetailScreen(documentId: document.id!),
        ),
      );
    }
  }
}

class _SourceIcon extends StatelessWidget {
  final String sourceType;

  const _SourceIcon({required this.sourceType});

  @override
  Widget build(BuildContext context) {
    IconData icon;
    Color color;

    switch (sourceType.toLowerCase()) {
      case 'text':
        icon = LucideIcons.fileText;
        color = AppTheme.accentGold;
      case 'url':
        icon = LucideIcons.link;
        color = AppTheme.statusProcessing;
      case 'file':
      case 'pdf':
        icon = LucideIcons.file;
        color = AppTheme.accentCopper;
      case 'image':
        icon = LucideIcons.image;
        color = AppTheme.statusReady;
      case 'voice':
        icon = LucideIcons.mic;
        color = Colors.purple;
      default:
        icon = LucideIcons.fileQuestion;
        color = AppTheme.textMutedDark;
    }

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, size: 20, color: color),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    IconData? icon;

    switch (status.toUpperCase()) {
      case 'QUEUED':
        color = AppTheme.statusWarning;
        label = 'Queued';
        icon = LucideIcons.clock;
      case 'PROCESSING':
      case 'EMBEDDING':
        color = AppTheme.statusProcessing;
        label = 'Processing';
        icon = LucideIcons.loader2;
      case 'READY':
        color = AppTheme.statusReady;
        label = 'Ready';
        icon = LucideIcons.checkCircle;
      case 'FAILED':
        color = AppTheme.statusFailed;
        label = 'Failed';
        icon = LucideIcons.alertCircle;
      default:
        color = AppTheme.textMutedDark;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _DocumentDetailSheet extends StatelessWidget {
  final Document document;

  const _DocumentDetailSheet({required this.document});

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
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
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      children: [
                        _SourceIcon(sourceType: document.sourceType),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            document.title,
                            style: Theme.of(context).textTheme.headlineMedium,
                          ),
                        ),
                      ],
                    ).animate().fadeIn().slideY(begin: 0.1),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _StatusBadge(status: document.status),
                        const SizedBox(width: 12),
                        Text(
                          timeago.format(document.createdAt),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 24),
                    if (document.summary != null) ...[
                      _SectionHeader(title: 'Summary'),
                      const SizedBox(height: 8),
                      Text(
                        document.summary!,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          height: 1.6,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                    if (document.extractedText != null && document.extractedText!.isNotEmpty) ...[
                      const SizedBox(height: 24),
                      _SectionHeader(title: 'Content'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).scaffoldBackgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          document.extractedText!,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            height: 1.6,
                          ),
                          maxLines: 20,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                    ],
                    if (document.sourceUrl != null) ...[
                      const SizedBox(height: 24),
                      _SectionHeader(title: 'Source'),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.statusProcessing.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.link, size: 16, color: AppTheme.statusProcessing),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                document.sourceUrl!,
                                style: TextStyle(color: AppTheme.statusProcessing),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 300.ms),
                    ],
                    const SizedBox(height: 32),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {},
                            icon: const Icon(LucideIcons.share2),
                            label: const Text('Share'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {},
                            icon: const Icon(LucideIcons.bellPlus),
                            label: const Text('Add Reminder'),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 16,
          decoration: BoxDecoration(
            color: AppTheme.accentGold,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: AppTheme.textSecondaryDark,
          ),
        ),
      ],
    );
  }
}
