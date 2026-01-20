import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import 'package:recall_butler_client/recall_butler_client.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class ProcessingIndicator extends StatelessWidget {
  final Document document;

  const ProcessingIndicator({
    super.key,
    required this.document,
  });

  @override
  Widget build(BuildContext context) {
    final (phase, percent, message) = _getProcessingState();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.statusProcessing.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.statusProcessing.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.statusProcessing.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.loader2,
                  size: 18,
                  color: AppTheme.statusProcessing,
                ).animate(onPlay: (c) => c.repeat())
                  .rotate(duration: 1000.ms),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      document.title,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      message,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.statusProcessing,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '$percent%',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.statusProcessing,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: percent / 100,
              backgroundColor: AppTheme.statusProcessing.withOpacity(0.2),
              valueColor: const AlwaysStoppedAnimation(AppTheme.statusProcessing),
              minHeight: 6,
            ),
          ),
          const SizedBox(height: 12),
          // Processing stages
          Row(
            children: [
              _ProcessingStage(
                label: 'Extract',
                isActive: phase == 'EXTRACTING',
                isComplete: _isStageComplete('EXTRACTING', phase),
              ),
              _StageConnector(isComplete: _isStageComplete('EXTRACTING', phase)),
              _ProcessingStage(
                label: 'Chunk',
                isActive: phase == 'CHUNKING',
                isComplete: _isStageComplete('CHUNKING', phase),
              ),
              _StageConnector(isComplete: _isStageComplete('CHUNKING', phase)),
              _ProcessingStage(
                label: 'Embed',
                isActive: phase == 'EMBEDDING',
                isComplete: _isStageComplete('EMBEDDING', phase),
              ),
              _StageConnector(isComplete: _isStageComplete('EMBEDDING', phase)),
              _ProcessingStage(
                label: 'Analyze',
                isActive: phase == 'SUMMARIZING',
                isComplete: _isStageComplete('SUMMARIZING', phase),
              ),
            ],
          ),
        ],
      ),
    );
  }

  (String, int, String) _getProcessingState() {
    switch (document.status) {
      case 'QUEUED':
        return ('QUEUED', 5, 'Waiting in queue...');
      case 'PROCESSING':
        return ('EXTRACTING', 20, 'Extracting text...');
      case 'EMBEDDING':
        return ('EMBEDDING', 60, 'Creating embeddings...');
      default:
        return ('PROCESSING', 40, 'Processing...');
    }
  }

  bool _isStageComplete(String stage, String currentPhase) {
    final stages = ['QUEUED', 'EXTRACTING', 'CHUNKING', 'EMBEDDING', 'SUMMARIZING', 'READY'];
    final currentIndex = stages.indexOf(currentPhase);
    final stageIndex = stages.indexOf(stage);
    return stageIndex < currentIndex;
  }
}

class _ProcessingStage extends StatelessWidget {
  final String label;
  final bool isActive;
  final bool isComplete;

  const _ProcessingStage({
    required this.label,
    required this.isActive,
    required this.isComplete,
  });

  @override
  Widget build(BuildContext context) {
    Color color;
    if (isComplete) {
      color = AppTheme.statusReady;
    } else if (isActive) {
      color = AppTheme.statusProcessing;
    } else {
      color = AppTheme.textMutedDark;
    }

    return Column(
      children: [
        Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            color: isComplete || isActive ? color.withOpacity(0.2) : Colors.transparent,
            shape: BoxShape.circle,
            border: Border.all(color: color, width: 2),
          ),
          child: isComplete
              ? Icon(LucideIcons.check, size: 12, color: color)
              : isActive
                  ? Center(
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ).animate(onPlay: (c) => c.repeat())
                        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1.2, 1.2), duration: 500.ms)
                        .then()
                        .scale(begin: const Offset(1.2, 1.2), end: const Offset(0.8, 0.8), duration: 500.ms),
                    )
                  : null,
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _StageConnector extends StatelessWidget {
  final bool isComplete;

  const _StageConnector({required this.isComplete});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 18),
        decoration: BoxDecoration(
          color: isComplete
              ? AppTheme.statusReady
              : AppTheme.textMutedDark.withOpacity(0.3),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
