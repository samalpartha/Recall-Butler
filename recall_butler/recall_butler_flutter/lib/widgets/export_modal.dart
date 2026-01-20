import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:share_plus/share_plus.dart';

import '../theme/app_theme.dart';

/// Modal for exporting search results as "Evidence Pack"
class ExportModal extends StatefulWidget {
  final String query;
  final String answerText;
  final List<Map<String, dynamic>> sources;

  const ExportModal({
    super.key,
    required this.query,
    required this.answerText,
    required this.sources,
  });

  @override
  State<ExportModal> createState() => _ExportModalState();
}

class _ExportModalState extends State<ExportModal> {
  String _selectedFormat = 'markdown';
  bool _includeSnippets = true;
  bool _includeTimestamps = true;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.9,
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
              // Header
              Padding(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppTheme.accentGold.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.download,
                        color: AppTheme.accentGold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Export Evidence Pack',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          Text(
                            '${widget.sources.length} sources',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ).animate().fadeIn(),

              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Format selection
                    Text(
                      'Export Format',
                      style: Theme.of(context).textTheme.labelLarge,
                    ).animate().fadeIn(delay: 100.ms),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _FormatOption(
                          icon: LucideIcons.fileText,
                          label: 'Markdown',
                          value: 'markdown',
                          selected: _selectedFormat,
                          onTap: () => setState(() => _selectedFormat = 'markdown'),
                        ),
                        const SizedBox(width: 8),
                        _FormatOption(
                          icon: LucideIcons.braces,
                          label: 'JSON',
                          value: 'json',
                          selected: _selectedFormat,
                          onTap: () => setState(() => _selectedFormat = 'json'),
                        ),
                        const SizedBox(width: 8),
                        _FormatOption(
                          icon: LucideIcons.clipboard,
                          label: 'Plain Text',
                          value: 'text',
                          selected: _selectedFormat,
                          onTap: () => setState(() => _selectedFormat = 'text'),
                        ),
                      ],
                    ).animate().fadeIn(delay: 150.ms),

                    const SizedBox(height: 24),

                    // Options
                    Text(
                      'Include',
                      style: Theme.of(context).textTheme.labelLarge,
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 12),
                    _ToggleOption(
                      label: 'Source snippets',
                      value: _includeSnippets,
                      onChanged: (v) => setState(() => _includeSnippets = v),
                    ).animate().fadeIn(delay: 250.ms),
                    _ToggleOption(
                      label: 'Timestamps',
                      value: _includeTimestamps,
                      onChanged: (v) => setState(() => _includeTimestamps = v),
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 24),

                    // Preview
                    Text(
                      'Preview',
                      style: Theme.of(context).textTheme.labelLarge,
                    ).animate().fadeIn(delay: 350.ms),
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Theme.of(context).scaffoldBackgroundColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(context).colorScheme.outline,
                        ),
                      ),
                      child: Text(
                        _generatePreview(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          height: 1.5,
                        ),
                        maxLines: 10,
                        overflow: TextOverflow.fade,
                      ),
                    ).animate().fadeIn(delay: 400.ms),

                    const SizedBox(height: 32),

                    // Export buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _copyToClipboard,
                            icon: const Icon(LucideIcons.copy),
                            label: const Text('Copy'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _shareExport,
                            icon: const Icon(LucideIcons.share2),
                            label: const Text('Share'),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 450.ms),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _generatePreview() {
    switch (_selectedFormat) {
      case 'markdown':
        return _generateMarkdown();
      case 'json':
        return _generateJson();
      default:
        return _generateText();
    }
  }

  String _generateMarkdown() {
    final buffer = StringBuffer();
    buffer.writeln('# Evidence Pack');
    buffer.writeln();
    buffer.writeln('**Query:** ${widget.query}');
    if (_includeTimestamps) {
      buffer.writeln('**Generated:** ${DateTime.now().toIso8601String()}');
    }
    buffer.writeln();
    buffer.writeln('## Answer');
    buffer.writeln();
    buffer.writeln(widget.answerText);
    buffer.writeln();
    buffer.writeln('## Sources');
    buffer.writeln();
    
    for (final source in widget.sources) {
      buffer.writeln('### ${source['title']}');
      if (_includeSnippets && source['snippet'] != null) {
        buffer.writeln();
        buffer.writeln('> ${source['snippet']}');
      }
      buffer.writeln();
    }
    
    return buffer.toString();
  }

  String _generateJson() {
    return '''{
  "query": "${widget.query}",
  "answer": "${widget.answerText.substring(0, widget.answerText.length.clamp(0, 100))}...",
  "sources": ${widget.sources.length}
}''';
  }

  String _generateText() {
    final buffer = StringBuffer();
    buffer.writeln('EVIDENCE PACK');
    buffer.writeln('Query: ${widget.query}');
    buffer.writeln();
    buffer.writeln('Answer:');
    buffer.writeln(widget.answerText);
    return buffer.toString();
  }

  void _copyToClipboard() {
    Clipboard.setData(ClipboardData(text: _generatePreview()));
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Evidence Pack copied to clipboard'),
        backgroundColor: AppTheme.statusReady,
      ),
    );
  }

  void _shareExport() {
    Share.share(_generatePreview(), subject: 'Evidence Pack: ${widget.query}');
    Navigator.pop(context);
  }
}

class _FormatOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final String selected;
  final VoidCallback onTap;

  const _FormatOption({
    required this.icon,
    required this.label,
    required this.value,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = value == selected;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.accentGold.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.accentGold
                  : Theme.of(context).colorScheme.outline,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                color: isSelected ? AppTheme.accentGold : AppTheme.textMutedDark,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? AppTheme.accentGold : AppTheme.textMutedDark,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ToggleOption extends StatelessWidget {
  final String label;
  final bool value;
  final Function(bool) onChanged;

  const _ToggleOption({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppTheme.accentGold,
          ),
        ],
      ),
    );
  }
}
