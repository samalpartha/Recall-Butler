import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

class BiometricUnlock extends StatefulWidget {
  final Widget child;
  final VoidCallback? onUnlock;
  final String label;

  const BiometricUnlock({
    super.key,
    required this.child,
    this.onUnlock,
    this.label = 'Authenticate to View',
  });

  @override
  State<BiometricUnlock> createState() => _BiometricUnlockState();
}

class _BiometricUnlockState extends State<BiometricUnlock> {
  bool _isAuthenticated = false;
  bool _isScanning = false;

  void _authenticate() async {
    setState(() => _isScanning = true);
    
    // Simulate biometric delay
    await Future.delayed(const Duration(milliseconds: 1500));
    
    if (mounted) {
      setState(() {
        _isScanning = false;
        _isAuthenticated = true;
      });
      widget.onUnlock?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated) {
      return widget.child.animate().fadeIn().slideY(begin: 0.1, end: 0);
    }

    return GestureDetector(
      onTap: _isScanning ? null : _authenticate,
      child: Container(
        padding: const EdgeInsets.all(24),
        width: double.infinity,
        decoration: BoxDecoration(
          color: AppTheme.cardDark,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _isScanning ? AppTheme.statusProcessing : const Color(0xFF3D4A5C),
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isScanning 
                    ? AppTheme.statusProcessing.withOpacity(0.1) 
                    : AppTheme.textMutedDark.withOpacity(0.1),
              ),
              child: Icon(
                LucideIcons.scanFace,
                size: 32,
                color: _isScanning ? AppTheme.statusProcessing : AppTheme.textMutedDark,
              ),
            )
            .animate(target: _isScanning ? 1 : 0)
            .shimmer(duration: 1000.ms, color: AppTheme.statusProcessing),
            
            const SizedBox(height: 16),
            
            Text(
              _isScanning ? 'Verifying FaceID...' : widget.label,
              style: TextStyle(
                color: _isScanning ? AppTheme.statusProcessing : AppTheme.textPrimaryDark,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            
            if (_isScanning)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  'Keep device steady',
                  style: TextStyle(
                    color: AppTheme.textMutedDark,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
