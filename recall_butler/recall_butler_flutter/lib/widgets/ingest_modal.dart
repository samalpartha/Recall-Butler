import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';

import '../theme/app_theme.dart';
import '../providers/documents_provider.dart';

enum IngestMode { text, url, file }

class IngestModal extends ConsumerStatefulWidget {
  final PlatformFile? initialFile;
  final String? initialText;
  final IngestMode initialMode;

  const IngestModal({
    super.key,
    this.initialFile,
    this.initialText,
    this.initialMode = IngestMode.text,
  });

  @override
  ConsumerState<IngestModal> createState() => _IngestModalState();
}

class _IngestModalState extends ConsumerState<IngestModal> {
  late IngestMode _mode;
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  final _urlController = TextEditingController();
  PlatformFile? _selectedFile;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.initialMode;
    if (widget.initialText != null) {
      _contentController.text = widget.initialText!;
      _mode = IngestMode.text;
    }
    if (widget.initialFile != null) {
      _selectedFile = widget.initialFile;
      _titleController.text = widget.initialFile!.name;
      _mode = IngestMode.file;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
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
                        LucideIcons.plus,
                        color: AppTheme.accentGold,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Add Memory',
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(LucideIcons.x),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ).animate().fadeIn().slideY(begin: -0.1),
              // Mode selector
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    _ModeTab(
                      icon: LucideIcons.fileText,
                      label: 'Text',
                      isSelected: _mode == IngestMode.text,
                      onTap: () => setState(() => _mode = IngestMode.text),
                    ),
                    const SizedBox(width: 8),
                    _ModeTab(
                      icon: LucideIcons.link,
                      label: 'URL',
                      isSelected: _mode == IngestMode.url,
                      onTap: () => setState(() => _mode = IngestMode.url),
                    ),
                    const SizedBox(width: 8),
                    _ModeTab(
                      icon: LucideIcons.upload,
                      label: 'File',
                      isSelected: _mode == IngestMode.file,
                      onTap: () => setState(() => _mode = IngestMode.file),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 20),
              // Content
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    // Title field
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(
                        labelText: 'Title',
                        hintText: 'Give this memory a name...',
                        prefixIcon: Icon(LucideIcons.tag),
                      ),
                    ).animate().fadeIn(delay: 150.ms),
                    const SizedBox(height: 16),
                    // Mode-specific content
                    if (_mode == IngestMode.text) ...[
                      TextField(
                        controller: _contentController,
                        maxLines: 8,
                        decoration: const InputDecoration(
                          labelText: 'Content',
                          hintText: 'Paste or type your content here...',
                          alignLabelWithHint: true,
                        ),
                      ).animate().fadeIn(delay: 200.ms),
                    ] else if (_mode == IngestMode.url) ...[
                      TextField(
                        controller: _urlController,
                        decoration: const InputDecoration(
                          labelText: 'URL',
                          hintText: 'https://...',
                          prefixIcon: Icon(LucideIcons.globe),
                        ),
                        keyboardType: TextInputType.url,
                      ).animate().fadeIn(delay: 200.ms),
                    ] else if (_mode == IngestMode.file) ...[
                      _FileSelector(
                        selectedFile: _selectedFile,
                        onFileSelected: (file) {
                          setState(() {
                            _selectedFile = file;
                            if (_titleController.text.isEmpty) {
                              _titleController.text = file.name;
                            }
                          });
                        },
                      ).animate().fadeIn(delay: 200.ms),
                    ],
                    const SizedBox(height: 32),
                    // Submit button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        icon: _isSubmitting
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.black,
                                ),
                              )
                            : const Icon(LucideIcons.brain),
                        label: Text(_isSubmitting ? 'Processing...' : 'Add to Memory'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ).animate().fadeIn(delay: 250.ms),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _handleSubmit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a title')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final notifier = ref.read(documentsProvider.notifier);
      
      switch (_mode) {
        case IngestMode.text:
          if (_contentController.text.trim().isEmpty) {
            throw Exception('Please enter some content');
          }
          await notifier.createFromText(
            title: _titleController.text.trim(),
            text: _contentController.text.trim(),
          );
        case IngestMode.url:
          if (_urlController.text.trim().isEmpty) {
            throw Exception('Please enter a URL');
          }
          await notifier.createFromUrl(
            title: _titleController.text.trim(),
            url: _urlController.text.trim(),
          );
        case IngestMode.file:
          if (_selectedFile == null) {
            throw Exception('Please select a file');
          }
          await notifier.uploadFile(
            title: _titleController.text.trim(),
            fileName: _selectedFile!.name,
            mimeType: _getMimeType(_selectedFile!.name),
            bytes: _selectedFile!.bytes ?? [],
          );
      }

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Memory added! Processing in background...'),
            backgroundColor: AppTheme.statusReady,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppTheme.statusFailed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'pdf':
        return 'application/pdf';
      case 'txt':
        return 'text/plain';
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }
}

class _ModeTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _ModeTab({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.accentGold.withOpacity(0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? AppTheme.accentGold.withOpacity(0.3)
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

class _FileSelector extends StatelessWidget {
  final PlatformFile? selectedFile;
  final Function(PlatformFile) onFileSelected;

  const _FileSelector({
    required this.selectedFile,
    required this.onFileSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () async {
        final result = await FilePicker.platform.pickFiles(
          type: FileType.any,
          allowMultiple: false,
          withData: true,
        );
        if (result != null && result.files.isNotEmpty) {
          onFileSelected(result.files.first);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: selectedFile != null
              ? AppTheme.statusReady.withOpacity(0.1)
              : Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selectedFile != null
                ? AppTheme.statusReady.withOpacity(0.3)
                : Theme.of(context).colorScheme.outline,
            style: selectedFile != null ? BorderStyle.solid : BorderStyle.none,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: selectedFile != null
                    ? AppTheme.statusReady.withOpacity(0.15)
                    : AppTheme.accentGold.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                selectedFile != null
                    ? LucideIcons.fileCheck
                    : LucideIcons.uploadCloud,
                size: 32,
                color: selectedFile != null
                    ? AppTheme.statusReady
                    : AppTheme.accentGold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              selectedFile != null ? selectedFile!.name : 'Tap to select a file',
              style: Theme.of(context).textTheme.titleSmall,
              textAlign: TextAlign.center,
            ),
            if (selectedFile != null) ...[
              const SizedBox(height: 4),
              Text(
                _formatFileSize(selectedFile!.size),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              const SizedBox(height: 4),
              Text(
                'PDF, images, text files supported',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
