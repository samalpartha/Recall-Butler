import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:speech_to_text/speech_recognition_result.dart';

import '../theme/app_theme.dart';
import '../providers/documents_provider.dart';

/// Voice capture screen - hands-free memory input
class VoiceCaptureScreen extends ConsumerStatefulWidget {
  const VoiceCaptureScreen({super.key});

  @override
  ConsumerState<VoiceCaptureScreen> createState() => _VoiceCaptureScreenState();
}

class _VoiceCaptureScreenState extends ConsumerState<VoiceCaptureScreen>
    with SingleTickerProviderStateMixin {
  final SpeechToText _speechToText = SpeechToText();
  bool _speechEnabled = false;
  bool _isListening = false;
  String _transcribedText = '';
  String _title = '';
  bool _isSaving = false;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _initSpeech();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _speechToText.stop();
    super.dispose();
  }

  void _initSpeech() async {
    _speechEnabled = await _speechToText.initialize(
      onError: (error) => debugPrint('Speech error: $error'),
      onStatus: (status) => debugPrint('Speech status: $status'),
    );
    setState(() {});
  }

  void _startListening() async {
    if (!_speechEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speech recognition not available. Please grant microphone permission.'),
          backgroundColor: AppTheme.statusFailed,
        ),
      );
      return;
    }

    await _speechToText.listen(
      onResult: _onSpeechResult,
      listenFor: const Duration(seconds: 60),
      pauseFor: const Duration(seconds: 3),
      partialResults: true,
      listenMode: ListenMode.dictation,
    );
    
    setState(() => _isListening = true);
    _pulseController.repeat();
  }

  void _stopListening() async {
    await _speechToText.stop();
    setState(() => _isListening = false);
    _pulseController.stop();
    _pulseController.reset();
  }

  void _onSpeechResult(SpeechRecognitionResult result) {
    setState(() {
      _transcribedText = result.recognizedWords;
    });
  }

  void _clearText() {
    setState(() {
      _transcribedText = '';
      _title = '';
    });
  }

  Future<void> _saveMemory() async {
    if (_transcribedText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please record something first'),
          backgroundColor: AppTheme.statusFailed,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final title = _title.isNotEmpty 
          ? _title 
          : 'Voice Note - ${DateTime.now().toString().substring(0, 16)}';
      
      await ref.read(documentsProvider.notifier).createFromText(
        title: title,
        text: _transcribedText,
        isVoiceNote: true,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.check, color: Colors.white, size: 18),
                const SizedBox(width: 12),
                const Text('Voice note saved!'),
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
            content: Text('Error: $e'),
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
        title: const Text('Voice Capture'),
        actions: [
          if (_transcribedText.isNotEmpty)
            TextButton.icon(
              onPressed: _isSaving ? null : _saveMemory,
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
        child: Column(
          children: [
            // Title input
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              child: TextField(
                onChanged: (value) => setState(() => _title = value),
                decoration: InputDecoration(
                  hintText: 'Title (optional)',
                  hintStyle: TextStyle(color: AppTheme.textMutedDark),
                  prefixIcon: const Icon(LucideIcons.type, size: 18),
                  filled: true,
                  fillColor: AppTheme.cardDark,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                ),
              ),
            ).animate().fadeIn(delay: 100.ms),

            // Transcribed text area
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(20),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: _isListening 
                        ? AppTheme.accentGold.withOpacity(0.5)
                        : AppTheme.surfaceDark,
                    width: 2,
                  ),
                ),
                child: _transcribedText.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.mic,
                              size: 48,
                              color: AppTheme.textMutedDark,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              _isListening 
                                  ? 'Listening...' 
                                  : 'Tap the microphone to start',
                              style: TextStyle(
                                color: AppTheme.textMutedDark,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      LucideIcons.quote,
                                      size: 16,
                                      color: AppTheme.accentGold,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      'Transcription',
                                      style: TextStyle(
                                        color: AppTheme.accentGold,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(LucideIcons.trash2, size: 18),
                                  onPressed: _clearText,
                                  color: AppTheme.textMutedDark,
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Text(
                              _transcribedText,
                              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
              ).animate().fadeIn(delay: 200.ms),
            ),

            // Microphone button
            Padding(
              padding: const EdgeInsets.only(bottom: 40),
              child: Column(
                children: [
                  // Recording indicator
                  if (_isListening)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: AppTheme.statusFailed,
                            shape: BoxShape.circle,
                          ),
                        ).animate(onPlay: (c) => c.repeat())
                          .fadeIn(duration: 500.ms)
                          .then()
                          .fadeOut(duration: 500.ms),
                        const SizedBox(width: 8),
                        Text(
                          'Recording...',
                          style: TextStyle(
                            color: AppTheme.textSecondaryDark,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ).animate().fadeIn(),
                  
                  const SizedBox(height: 20),

                  // Main mic button
                  GestureDetector(
                    onTap: _isListening ? _stopListening : _startListening,
                    child: AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _isListening 
                                ? AppTheme.statusFailed 
                                : AppTheme.accentGold,
                            boxShadow: _isListening
                                ? [
                                    BoxShadow(
                                      color: AppTheme.statusFailed.withOpacity(
                                        0.3 + (_pulseController.value * 0.3),
                                      ),
                                      blurRadius: 20 + (_pulseController.value * 20),
                                      spreadRadius: _pulseController.value * 10,
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: AppTheme.accentGold.withOpacity(0.3),
                                      blurRadius: 20,
                                    ),
                                  ],
                          ),
                          child: Icon(
                            _isListening ? LucideIcons.square : LucideIcons.mic,
                            size: 40,
                            color: Colors.black,
                          ),
                        );
                      },
                    ),
                  ).animate().scale(delay: 300.ms),

                  const SizedBox(height: 16),

                  Text(
                    _isListening ? 'Tap to stop' : 'Tap to speak',
                    style: TextStyle(
                      color: AppTheme.textMutedDark,
                      fontSize: 14,
                    ),
                  ),

                  if (!_speechEnabled) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Microphone permission required',
                      style: TextStyle(
                        color: AppTheme.statusFailed,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
