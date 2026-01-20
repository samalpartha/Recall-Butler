import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'dart:convert';
import 'package:recall_butler_client/recall_butler_client.dart';
import '../theme/app_theme.dart';

class SuggestionCard extends StatelessWidget {
  final Suggestion suggestion;
  final VoidCallback onApprove;
  final VoidCallback onDismiss;

  const SuggestionCard({
    super.key,
    required this.suggestion,
    required this.onApprove,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    Map<String, dynamic> payload = {};
    try {
      payload = jsonDecode(suggestion.payloadJson);
    } catch (_) {}
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getTypeColor().withOpacity(0.15),
            _getTypeColor().withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _getTypeColor().withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _getTypeColor().withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _getTypeIcon(),
                        size: 24,
                        color: _getTypeColor(),
                      ),
                    ),
                    const SizedBox(width: 12),
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
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            suggestion.title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  suggestion.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    height: 1.5,
                  ),
                ),
                // Show payload details
                if (payload.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  _PayloadDetails(payload: payload, typeColor: _getTypeColor()),
                ],
              ],
            ),
          ),
          // Actions
          Container(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onDismiss,
                    icon: const Icon(LucideIcons.x, size: 18),
                    label: const Text('Dismiss'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textMutedDark,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(LucideIcons.check, size: 18),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getTypeColor(),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getTypeIcon() {
    switch (suggestion.type) {
      case 'reminder':
        return LucideIcons.bell;
      case 'followup':
        return LucideIcons.reply;
      case 'checkin':
        return LucideIcons.plane;
      case 'summary':
        return LucideIcons.fileText;
      default:
        return LucideIcons.lightbulb;
    }
  }

  Color _getTypeColor() {
    switch (suggestion.type) {
      case 'reminder':
        return AppTheme.accentGold;
      case 'followup':
        return AppTheme.statusProcessing;
      case 'checkin':
        return AppTheme.accentCopper;
      case 'summary':
        return AppTheme.statusReady;
      default:
        return AppTheme.accentGold;
    }
  }

  String _getTypeLabel() {
    switch (suggestion.type) {
      case 'reminder':
        return 'PAYMENT REMINDER';
      case 'followup':
        return 'FOLLOW-UP ACTION';
      case 'checkin':
        return 'TRAVEL CHECK-IN';
      case 'summary':
        return 'DOCUMENT SUMMARY';
      default:
        return 'BUTLER SUGGESTION';
    }
  }
}

class _PayloadDetails extends StatelessWidget {
  final Map<String, dynamic> payload;
  final Color typeColor;

  const _PayloadDetails({
    required this.payload,
    required this.typeColor,
  });

  @override
  Widget build(BuildContext context) {
    final details = <Widget>[];

    if (payload['dueDate'] != null) {
      details.add(_DetailChip(
        icon: LucideIcons.calendar,
        label: 'Due: ${payload['dueDate']}',
        color: typeColor,
      ));
    }

    if (payload['amount'] != null) {
      details.add(_DetailChip(
        icon: LucideIcons.dollarSign,
        label: payload['amount'],
        color: typeColor,
      ));
    }

    if (payload['vendor'] != null) {
      details.add(_DetailChip(
        icon: LucideIcons.building,
        label: payload['vendor'],
        color: typeColor,
      ));
    }

    if (payload['flightDate'] != null) {
      details.add(_DetailChip(
        icon: LucideIcons.planeTakeoff,
        label: payload['flightDate'],
        color: typeColor,
      ));
    }

    if (payload['confirmation'] != null) {
      details.add(_DetailChip(
        icon: LucideIcons.hash,
        label: payload['confirmation'],
        color: typeColor,
      ));
    }

    if (details.isEmpty) return const SizedBox();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: details,
    );
  }
}

class _DetailChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _DetailChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
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
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
