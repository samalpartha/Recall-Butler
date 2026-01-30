import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../theme/app_theme.dart';

class UnifiedCaptureBtn extends StatefulWidget {
  final VoidCallback onText;
  final VoidCallback onVoice;
  final VoidCallback onCamera;
  final VoidCallback onLink;

  const UnifiedCaptureBtn({
    super.key,
    required this.onText,
    required this.onVoice,
    required this.onCamera,
    required this.onLink,
  });

  @override
  State<UnifiedCaptureBtn> createState() => _UnifiedCaptureBtnState();
}

class _UnifiedCaptureBtnState extends State<UnifiedCaptureBtn> with SingleTickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _toggle() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        if (_isExpanded) ...[
          _CaptureOption(
            icon: LucideIcons.link,
            label: 'Save Link',
            color: Colors.blue,
            delay: 150,
            onTap: () {
              _toggle();
              widget.onLink();
            },
          ),
          const SizedBox(height: 16),
          _CaptureOption(
            icon: LucideIcons.camera,
            label: 'Scan / Photo',
            color: AppTheme.accentCopper,
            delay: 100,
            onTap: () {
              _toggle();
              widget.onCamera();
            },
          ),
          const SizedBox(height: 16),
          _CaptureOption(
            icon: LucideIcons.mic,
            label: 'Voice Note',
            color: AppTheme.statusProcessing,
            delay: 50,
            onTap: () {
              _toggle();
              widget.onVoice();
            },
          ),
          const SizedBox(height: 16),
          _CaptureOption(
            icon: LucideIcons.stickyNote,
            label: 'Text Note',
            color: AppTheme.accentGold,
            delay: 0,
            onTap: () {
              _toggle();
              widget.onText();
            },
          ),
          const SizedBox(height: 24),
        ],

        FloatingActionButton(
          heroTag: 'unified_capture_fab',
          onPressed: _toggle,
          backgroundColor: _isExpanded ? AppTheme.cardDark : AppTheme.accentGold,
          elevation: 8,
          child: AnimatedRotation(
            turns: _isExpanded ? 0.125 : 0, // 45 degrees
            duration: const Duration(milliseconds: 200),
            child: Icon(
              _isExpanded ? LucideIcons.x : LucideIcons.plus,
              color: _isExpanded ? Colors.white : Colors.black,
              size: 28,
            ),
          ),
        ),
      ],
    );
  }
}

class _CaptureOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final int delay;
  final VoidCallback onTap;

  const _CaptureOption({
    required this.icon,
    required this.label,
    required this.color,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.cardDark,
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
              ),
            ],
          ),
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w500,
            ),
          ),
        ).animate().fadeIn(delay: delay.ms).slideX(begin: 0.2),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ).animate().fadeIn(delay: delay.ms).scale(),
      ],
    );
  }
}
