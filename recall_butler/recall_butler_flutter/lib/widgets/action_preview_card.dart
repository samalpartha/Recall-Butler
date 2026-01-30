import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:recall_butler_client/recall_butler_client.dart';
import '../providers/action_provider.dart';
import '../theme/vibrant_theme.dart';

class ActionPreviewCard extends ConsumerStatefulWidget {
  const ActionPreviewCard({super.key});

  @override
  ConsumerState<ActionPreviewCard> createState() => _ActionPreviewCardState();
}

class _ActionPreviewCardState extends ConsumerState<ActionPreviewCard> {
  bool _isExecuting = false;

  @override
  Widget build(BuildContext context) {
    final action = ref.watch(currentActionProvider);

    if (action == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: VibrantTheme.bgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: VibrantTheme.primaryPurple.withOpacity(0.5)),
        boxShadow: [
          BoxShadow(
            color: VibrantTheme.primaryPurple.withOpacity(0.2),
            blurRadius: 20,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildHeader(action),
          const SizedBox(height: 16),
          _buildContent(action),
          const SizedBox(height: 20),
          _buildActionButtons(ref),
        ],
      ),
    ).animate().fadeIn().slideY(begin: 0.2);
  }

  Widget _buildHeader(ButlerAction action) {
    IconData icon;
    String title;
    Color color;

    if (action is CreateReminderAction) {
      icon = LucideIcons.bell;
      title = 'Create Reminder';
      color = VibrantTheme.primaryYellow;
    } else if (action is SendEmailAction) {
      icon = LucideIcons.mail;
      title = 'Draft Email';
      color = VibrantTheme.primaryBlue;
    } else {
      icon = LucideIcons.zap;
      title = 'Suggested Action';
      color = VibrantTheme.primaryPurple;
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: VibrantTheme.primaryGreen.withOpacity(0.2),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '${(action.confidence * 100).toInt()}% Confidence',
            style: const TextStyle(
              color: VibrantTheme.primaryGreen,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(ButlerAction action) {
    if (action is CreateReminderAction) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('Title', action.title, isBold: true),
          const SizedBox(height: 8),
          _buildDetailRow(
            'Due', 
            action.dueAt != null 
                ? DateFormat('MMM d, h:mm a').format(action.dueAt!) 
                : 'No specific time'
          ),
          const SizedBox(height: 8),
          _buildDetailRow('Priority', action.priority.toString().toUpperCase()),
        ],
      );
    } else if (action is SendEmailAction) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow('To', action.recipient),
          const SizedBox(height: 8),
          _buildDetailRow('Subject', action.subject, isBold: true),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: Text(
              action.body,
              style: TextStyle(
                color: VibrantTheme.textSecondary,
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      );
    }
    return Text(action.description);
  }

  Widget _buildDetailRow(String label, String value, {bool isBold = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 70,
          child: Text(
            label,
            style: TextStyle(
              color: VibrantTheme.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(WidgetRef ref) {
    if (_isExecuting) {
       return const Center(child: CircularProgressIndicator());
    }
  
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () {
              ref.read(actionProcessingProvider.notifier).clear();
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: Colors.grey),
            ),
            child: const Text('Cancel', style: TextStyle(color: Colors.white)),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              setState(() => _isExecuting = true);
              final success = await ref.read(actionProcessingProvider.notifier).executeCurrentAction();
              
              if (mounted) {
                setState(() => _isExecuting = false);
                if (success) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Action executed successfully!'),
                      backgroundColor: VibrantTheme.primaryGreen,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to execute action.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              backgroundColor: (ref.read(currentActionProvider) is CreateReminderAction) 
                ? VibrantTheme.primaryYellow 
                : VibrantTheme.primaryBlue,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              shadowColor: (ref.read(currentActionProvider) is CreateReminderAction) 
                ? VibrantTheme.primaryYellow.withOpacity(0.5) 
                : VibrantTheme.primaryBlue.withOpacity(0.5),
              elevation: 8,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 Icon(LucideIcons.playCircle, size: 20, color: Colors.black87),
                 SizedBox(width: 8),
                 Text('Execute', style: TextStyle(color: Colors.black87, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
