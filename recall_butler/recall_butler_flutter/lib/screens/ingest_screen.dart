import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';

import '../theme/app_theme.dart';
import '../providers/documents_provider.dart';
import '../widgets/document_card.dart';
import '../widgets/ingest_modal.dart';
import '../widgets/processing_indicator.dart';
import 'chat_screen.dart';
import 'voice_capture_screen.dart';
import 'camera_capture_screen.dart';

/// Ingest screen - Upload, paste, or enter data
class IngestScreen extends ConsumerStatefulWidget {
  const IngestScreen({super.key});

  @override
  ConsumerState<IngestScreen> createState() => _IngestScreenState();
}

class _IngestScreenState extends ConsumerState<IngestScreen> {
  @override
  Widget build(BuildContext context) {
    final recentDocs = ref.watch(recentDocumentsProvider);
    final processingDocs = ref.watch(processingDocumentsProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar
          SliverAppBar(
            floating: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.accentGold.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    LucideIcons.brain,
                    color: AppTheme.accentGold,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Recall Butler'),
              ],
            ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.1),
            actions: [
              IconButton(
                icon: const Icon(LucideIcons.settings),
                onPressed: () => _showSettings(context),
              ),
            ],
          ),

          // Quick Actions
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'What would you like to remember?',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.2),
                  const SizedBox(height: 8),
                  Text(
                    'Upload files, paste text, or save URLs',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ).animate().fadeIn(delay: 150.ms),
                  const SizedBox(height: 24),
                  
                  // Quick capture buttons - NEW FEATURES
                  Row(
                    children: [
                      Expanded(
                        child: _FeatureButton(
                          icon: LucideIcons.messageCircle,
                          label: 'Chat',
                          subtitle: 'Ask Butler',
                          gradient: [AppTheme.accentGold, AppTheme.accentCopper],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const ChatScreen()),
                          ),
                        ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FeatureButton(
                          icon: LucideIcons.mic,
                          label: 'Voice',
                          subtitle: 'Speak',
                          gradient: [AppTheme.statusProcessing, const Color(0xFF5C6BC0)],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const VoiceCaptureScreen()),
                          ),
                        ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _FeatureButton(
                          icon: LucideIcons.camera,
                          label: 'Scan',
                          subtitle: 'OCR',
                          gradient: [AppTheme.accentCopper, AppTheme.statusFailed],
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CameraCaptureScreen()),
                          ),
                        ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Original quick action buttons
                  Row(
                    children: [
                      Expanded(
                        child: _QuickActionButton(
                          icon: LucideIcons.upload,
                          label: 'Upload',
                          color: AppTheme.accentGold,
                          onTap: () => _handleUpload(context),
                        ).animate().fadeIn(delay: 350.ms).scale(begin: const Offset(0.9, 0.9)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionButton(
                          icon: LucideIcons.clipboard,
                          label: 'Paste',
                          color: AppTheme.statusProcessing,
                          onTap: () => _handlePaste(context),
                        ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.9, 0.9)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _QuickActionButton(
                          icon: LucideIcons.link,
                          label: 'URL',
                          color: AppTheme.accentCopper,
                          onTap: () => _handleUrl(context),
                        ).animate().fadeIn(delay: 450.ms).scale(begin: const Offset(0.9, 0.9)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Processing section
          processingDocs.when(
            data: (docs) {
              if (docs.isEmpty) return const SliverToBoxAdapter(child: SizedBox());
              return SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            LucideIcons.loader2,
                            size: 18,
                            color: AppTheme.statusProcessing,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Processing (${docs.length})',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: AppTheme.statusProcessing,
                            ),
                          ),
                        ],
                      ).animate(onPlay: (c) => c.repeat())
                        .shimmer(duration: 1500.ms),
                      const SizedBox(height: 12),
                      ...docs.map((doc) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: ProcessingIndicator(document: doc),
                      )),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(child: SizedBox()),
            error: (_, __) => const SliverToBoxAdapter(child: SizedBox()),
          ),

          // Recent documents header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Memories',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  TextButton.icon(
                    icon: const Icon(LucideIcons.arrowRight, size: 16),
                    label: const Text('View All'),
                    onPressed: () {},
                  ),
                ],
              ).animate().fadeIn(delay: 350.ms),
            ),
          ),

          // Recent documents list
          recentDocs.when(
            data: (docs) {
              if (docs.isEmpty) {
                return SliverToBoxAdapter(
                  child: _EmptyState(),
                );
              }
              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: DocumentCard(document: docs[index])
                            .animate()
                            .fadeIn(delay: (400 + index * 50).ms)
                            .slideY(begin: 0.1),
                      );
                    },
                    childCount: docs.length,
                  ),
                ),
              );
            },
            loading: () => const SliverToBoxAdapter(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, _) => SliverToBoxAdapter(
              child: Center(child: Text('Error: $error')),
            ),
          ),

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
      // FAB removed - using shell_screen FAB instead for quick actions
    );
  }

  void _handleUpload(BuildContext context) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: false,
    );
    
    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      _showIngestModal(context, initialFile: file);
    }
  }

  void _handlePaste(BuildContext context) async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null && data!.text!.isNotEmpty) {
      _showIngestModal(context, initialText: data.text);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Clipboard is empty')),
      );
    }
  }

  void _handleUrl(BuildContext context) {
    _showIngestModal(context, initialMode: IngestMode.url);
  }

  void _showIngestModal(
    BuildContext context, {
    PlatformFile? initialFile,
    String? initialText,
    IngestMode initialMode = IngestMode.text,
  }) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => IngestModal(
        initialFile: initialFile,
        initialText: initialText,
        initialMode: initialMode,
      ),
    );
  }

  void _showSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Settings',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(LucideIcons.server),
              title: const Text('Server URL'),
              subtitle: const Text('localhost:8080'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(LucideIcons.key),
              title: const Text('API Key'),
              subtitle: const Text('Configure OpenAI key'),
              onTap: () {},
            ),
            ListTile(
              leading: const Icon(LucideIcons.trash2),
              title: const Text('Clear Cache'),
              onTap: () {},
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

/// Feature button with gradient background (for main features)
class _FeatureButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final List<Color> gradient;
  final VoidCallback onTap;

  const _FeatureButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: gradient.map((c) => c.withOpacity(0.15)).toList(),
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: gradient[0].withOpacity(0.3),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: gradient),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: Colors.white, size: 22),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: gradient[0],
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            Text(
              subtitle,
              style: TextStyle(
                color: gradient[0].withOpacity(0.7),
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.inbox,
              size: 48,
              color: AppTheme.accentGold,
            ),
          ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
          const SizedBox(height: 24),
          Text(
            'Your memory vault is empty',
            style: Theme.of(context).textTheme.titleLarge,
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 8),
          Text(
            'Start by uploading a file, pasting text,\nor saving a URL',
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 150.ms),
        ],
      ),
    );
  }
}
