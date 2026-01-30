import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../theme/app_theme.dart';

class SafetyVisualization extends StatelessWidget {
  const SafetyVisualization({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.cardDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF3D4A5C)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildNode(
                icon: LucideIcons.smartphone,
                label: 'Your Device',
                color: AppTheme.statusProcessing, // Blue-ish
              ),
              Expanded(child: _buildConnection()),
              _buildNode(
                icon: LucideIcons.shieldCheck,
                label: 'Encryption',
                color: AppTheme.accentGold,
                isShield: true,
              ),
              Expanded(child: _buildConnection()),
              _buildNode(
                icon: LucideIcons.database,
                label: 'Cloud Vault',
                color: Colors.deepPurpleAccent, // Using standard Material color for distinction
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.statusReady.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(LucideIcons.lock, size: 12, color: AppTheme.statusReady),
                const SizedBox(width: 6),
                Text(
                  'End-to-End Encrypted • Only YOU hold the keys',
                  style: TextStyle(
                    color: AppTheme.statusReady,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNode({
    required IconData icon,
    required String label,
    required Color color,
    bool isShield = false,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            border: Border.all(color: color.withOpacity(0.3), width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Icon(icon, color: color, size: 24),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 2.seconds),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            color: AppTheme.textMutedDark,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildConnection() {
    return Container(
      height: 2,
      margin: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.textMutedDark.withOpacity(0.1),
            AppTheme.accentGold,
            AppTheme.textMutedDark.withOpacity(0.1),
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat()).shimmer(duration: 1500.ms, color: AppTheme.accentGold);
  }
}
