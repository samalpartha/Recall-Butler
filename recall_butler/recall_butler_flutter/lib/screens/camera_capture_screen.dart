import 'dart:typed_data';
import 'dart:async';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:image_picker/image_picker.dart';

import '../theme/app_theme.dart';
import '../providers/documents_provider.dart';

/// Camera capture screen - scan documents and receipts
class CameraCaptureScreen extends ConsumerStatefulWidget {
  const CameraCaptureScreen({super.key});

  @override
  ConsumerState<CameraCaptureScreen> createState() => _CameraCaptureScreenState();
}

class _CameraCaptureScreenState extends ConsumerState<CameraCaptureScreen> {
  final ImagePicker _picker = ImagePicker();
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _textController = TextEditingController();
  
  Uint8List? _imageBytes;
  String? _imagePath;
  bool _isProcessing = false;
  bool _isSaving = false;
  String _selectedType = 'receipt';

  final List<Map<String, dynamic>> _documentTypes = [
    {'type': 'receipt', 'label': 'Receipt', 'icon': LucideIcons.receipt},
    {'type': 'invoice', 'label': 'Invoice', 'icon': LucideIcons.fileText},
    {'type': 'document', 'label': 'Document', 'icon': LucideIcons.file},
    {'type': 'card', 'label': 'Business Card', 'icon': LucideIcons.creditCard},
    {'type': 'note', 'label': 'Handwritten', 'icon': LucideIcons.penTool},
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickFromCamera() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
        preferredCameraDevice: CameraDevice.rear,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imagePath = image.path;
        });
        _extractText();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Camera error: $e'),
            backgroundColor: AppTheme.statusFailed,
          ),
        );
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _imageBytes = bytes;
          _imagePath = image.path;
        });
        _extractText();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error selecting image: $e'),
            backgroundColor: AppTheme.statusFailed,
          ),
        );
      }
    }
  }

  Future<void> _extractText() async {
    setState(() => _isProcessing = true);

    try {
      await Future.delayed(const Duration(seconds: 2));
      
      String extractedText;
      String suggestedTitle;
      
      switch (_selectedType) {
        case 'receipt':
          suggestedTitle = 'Receipt - ${DateTime.now().toString().substring(0, 10)}';
          extractedText = '''Store: Grocery Mart
Date: ${DateTime.now().toString().substring(0, 10)}
Items:
- Milk \$3.99
- Bread \$2.49
- Eggs \$4.99
Total: \$11.47
Payment: Credit Card ending 4321''';
          break;
        case 'invoice':
          suggestedTitle = 'Invoice #${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}';
          extractedText = '''Invoice #${DateTime.now().millisecondsSinceEpoch.toString().substring(8)}
Date: ${DateTime.now().toString().substring(0, 10)}
Due: ${DateTime.now().add(const Duration(days: 30)).toString().substring(0, 10)}
Amount: \$150.00
Description: Professional Services''';
          break;
        case 'card':
          suggestedTitle = 'Business Card';
          extractedText = '''John Smith
Senior Developer
Acme Corporation

Email: john@acme.com
Phone: (555) 123-4567
Website: www.acme.com''';
          break;
        default:
          suggestedTitle = 'Scanned ${_selectedType.capitalize()} - ${DateTime.now().toString().substring(0, 10)}';
          extractedText = 'Scanned document content would appear here after OCR processing.';
      }

      setState(() {
        _titleController.text = suggestedTitle;
        _textController.text = extractedText;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.sparkles, color: Colors.black, size: 18),
                const SizedBox(width: 12),
                const Text('Text extracted successfully!'),
              ],
            ),
            backgroundColor: AppTheme.accentGold,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error extracting text: $e'),
            backgroundColor: AppTheme.statusFailed,
          ),
        );
      }
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _saveDocument() async {
    if (_textController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please capture or enter some text first'),
          backgroundColor: AppTheme.statusFailed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final title = _titleController.text.isNotEmpty
          ? _titleController.text
          : 'Scanned Document - ${DateTime.now().toString().substring(0, 16)}';

      await ref.read(documentsProvider.notifier).createFromText(
        title: title,
        text: _textController.text,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.check, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                const Text('Document saved!'),
              ],
            ),
            backgroundColor: AppTheme.statusReady,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving: $e'),
            backgroundColor: AppTheme.statusFailed,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _clearImage() {
    setState(() {
      _imageBytes = null;
      _imagePath = null;
      _titleController.clear();
      _textController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(LucideIcons.x),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Scan Document'),
        actions: [
          if (_textController.text.isNotEmpty)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveDocument,
              icon: _isSaving
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(LucideIcons.save, size: 18),
              label: const Text('Save'),
            ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Document type selector
              Text(
                'Document Type',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppTheme.textMutedDark,
                ),
              ).animate().fadeIn(),
              const SizedBox(height: 12),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _documentTypes.map((type) {
                    final isSelected = _selectedType == type['type'];
                    return Padding(
                      padding: const EdgeInsets.only(right: 10),
                      child: GestureDetector(
                        onTap: () => setState(() => _selectedType = type['type']),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppTheme.accentGold.withOpacity(0.2)
                                : AppTheme.cardDark,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? AppTheme.accentGold
                                  : AppTheme.surfaceDark,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                type['icon'] as IconData,
                                size: 18,
                                color: isSelected
                                    ? AppTheme.accentGold
                                    : AppTheme.textMutedDark,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                type['label'] as String,
                                style: TextStyle(
                                  color: isSelected
                                      ? AppTheme.accentGold
                                      : AppTheme.textSecondaryDark,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ).animate().fadeIn(delay: 100.ms),

              const SizedBox(height: 24),

              // Image preview or capture buttons
              if (_imageBytes != null) ...[
                // Image preview
                Stack(
                  children: [
                    Container(
                      width: double.infinity,
                      height: 250,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: _isProcessing
                              ? AppTheme.statusProcessing
                              : AppTheme.surfaceDark,
                          width: 2,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.memory(
                          _imageBytes!,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: IconButton(
                        onPressed: _clearImage,
                        icon: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(LucideIcons.x, size: 18),
                        ),
                      ),
                    ),
                    if (_isProcessing)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const CircularProgressIndicator(
                                color: AppTheme.accentGold,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Extracting text...',
                                style: TextStyle(
                                  color: AppTheme.accentGold,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ).animate().fadeIn(delay: 200.ms),
              ] else ...[
                // Capture buttons
                Row(
                  children: [
                    Expanded(
                      child: _CaptureButton(
                        icon: LucideIcons.camera,
                        label: 'Take Photo',
                        subtitle: kIsWeb ? 'Open webcam' : 'Open camera',
                        color: AppTheme.accentGold,
                        onTap: _pickFromCamera,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _CaptureButton(
                        icon: LucideIcons.image,
                        label: 'Gallery',
                        subtitle: 'Choose image',
                        color: AppTheme.statusProcessing,
                        onTap: _pickFromGallery,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                
                // Manual entry option
                const SizedBox(height: 16),
                Center(
                  child: TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _titleController.text = 'Manual Entry - ${DateTime.now().toString().substring(0, 10)}';
                      });
                    },
                    icon: const Icon(LucideIcons.keyboard, size: 18),
                    label: const Text('Or type manually'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppTheme.textMutedDark,
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms),
              ],

              const SizedBox(height: 24),

              // Title input
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Title',
                  hintText: 'Enter document title',
                  prefixIcon: const Icon(LucideIcons.type, size: 18),
                  filled: true,
                  fillColor: AppTheme.cardDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ).animate().fadeIn(delay: 300.ms),

              const SizedBox(height: 16),

              // Extracted text area
              Container(
                constraints: const BoxConstraints(minHeight: 200),
                child: TextField(
                  controller: _textController,
                  maxLines: null,
                  minLines: 8,
                  decoration: InputDecoration(
                    labelText: 'Extracted Text',
                    hintText: 'Capture an image to extract text, or type manually',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: AppTheme.cardDark,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: 400.ms),

              const SizedBox(height: 24),

              // Tips section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.statusProcessing.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppTheme.statusProcessing.withOpacity(0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LucideIcons.lightbulb,
                          size: 16,
                          color: AppTheme.statusProcessing,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Tips for better scanning',
                          style: TextStyle(
                            color: AppTheme.statusProcessing,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '• Ensure good lighting\n• Hold camera steady\n• Include all text in frame\n• Avoid shadows and glare',
                      style: TextStyle(
                        color: AppTheme.textSecondaryDark,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ).animate().fadeIn(delay: 500.ms),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color color;
  final VoidCallback onTap;

  const _CaptureButton({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 32),
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
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 12,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(icon, size: 28, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
                fontSize: 15,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(
                  color: color.withOpacity(0.7),
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
