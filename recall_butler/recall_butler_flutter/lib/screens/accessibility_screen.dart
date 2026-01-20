import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_theme.dart';

/// Accessibility settings for inclusive design
class AccessibilityScreen extends ConsumerStatefulWidget {
  const AccessibilityScreen({super.key});

  @override
  ConsumerState<AccessibilityScreen> createState() => _AccessibilityScreenState();
}

class _AccessibilityScreenState extends ConsumerState<AccessibilityScreen> {
  // Accessibility settings
  double _textScale = 1.0;
  bool _highContrast = false;
  bool _reduceMotion = false;
  bool _screenReader = false;
  bool _dyslexiaFont = false;
  bool _pictureMode = false;
  bool _voiceControl = false;
  bool _largeButtons = false;
  bool _simplifiedUI = false;
  String _selectedLanguage = 'English';
  String _colorBlindMode = 'None';

  final List<String> _languages = [
    'English', 'Español', 'हिंदी', '中文', 'العربية', 
    'Português', 'বাংলা', 'Русский', '日本語', 'Deutsch',
    'Français', 'తెలుగు', 'தமிழ்', 'ਪੰਜਾਬੀ', 'मराठी',
  ];

  final List<String> _colorBlindModes = [
    'None', 'Protanopia', 'Deuteranopia', 'Tritanopia', 'Monochromacy'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.sparkles, size: 20, color: Colors.deepPurple),
            const SizedBox(width: 8),
            const Text('Personalize'),
          ],
        ),
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: _resetToDefaults,
            icon: const Icon(LucideIcons.refreshCw, size: 18),
            label: const Text('Reset'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quick Profiles
          _SectionHeader(
            icon: LucideIcons.wand2,
            title: 'Quick Setup',
            subtitle: 'One-tap profiles tailored for you',
          ).animate().fadeIn(delay: 100.ms),
          const SizedBox(height: 12),
          
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ProfileChip(
                icon: LucideIcons.baby,
                label: 'Kids Mode',
                color: Colors.pink,
                onTap: () => _applyProfile('kids'),
              ),
              _ProfileChip(
                icon: LucideIcons.graduationCap,
                label: 'Student',
                color: Colors.blue,
                onTap: () => _applyProfile('student'),
              ),
              _ProfileChip(
                icon: LucideIcons.heart,
                label: 'Senior',
                color: Colors.green,
                onTap: () => _applyProfile('senior'),
              ),
              _ProfileChip(
                icon: LucideIcons.eye,
                label: 'Low Vision',
                color: Colors.orange,
                onTap: () => _applyProfile('lowVision'),
              ),
              _ProfileChip(
                icon: LucideIcons.mic,
                label: 'Voice Only',
                color: Colors.purple,
                onTap: () => _applyProfile('voiceOnly'),
              ),
              _ProfileChip(
                icon: LucideIcons.image,
                label: 'Picture Mode',
                color: Colors.teal,
                onTap: () => _applyProfile('pictureMode'),
              ),
            ],
          ).animate().fadeIn(delay: 150.ms),
          
          const SizedBox(height: 32),

          // Vision
          _SectionHeader(
            icon: LucideIcons.eye,
            title: 'Display & Reading',
            subtitle: 'Make text easier to read',
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 16),
          
          _SettingCard(
            title: 'Text Size',
            subtitle: 'Adjust text scaling (${(_textScale * 100).toInt()}%)',
            child: Column(
              children: [
                Row(
                  children: [
                    const Text('A', style: TextStyle(fontSize: 12)),
                    Expanded(
                      child: Slider(
                        value: _textScale,
                        min: 0.8,
                        max: 2.0,
                        divisions: 12,
                        onChanged: (v) => setState(() => _textScale = v),
                        activeColor: AppTheme.accentGold,
                      ),
                    ),
                    const Text('A', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.cardDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Preview: This is how text will appear',
                    style: TextStyle(fontSize: 16 * _textScale),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 250.ms),
          
          const SizedBox(height: 12),
          
          _ToggleSetting(
            icon: LucideIcons.contrast,
            title: 'High Contrast',
            subtitle: 'Increase color contrast for better visibility',
            value: _highContrast,
            onChanged: (v) => setState(() => _highContrast = v),
          ).animate().fadeIn(delay: 300.ms),
          
          _ToggleSetting(
            icon: LucideIcons.type,
            title: 'Dyslexia-Friendly Font',
            subtitle: 'Use OpenDyslexic font for easier reading',
            value: _dyslexiaFont,
            onChanged: (v) => setState(() => _dyslexiaFont = v),
          ).animate().fadeIn(delay: 350.ms),
          
          _SettingCard(
            title: 'Color Blind Mode',
            subtitle: 'Adjust colors for color vision deficiency',
            child: Wrap(
              spacing: 8,
              children: _colorBlindModes.map((mode) => ChoiceChip(
                label: Text(mode),
                selected: _colorBlindMode == mode,
                onSelected: (selected) {
                  if (selected) setState(() => _colorBlindMode = mode);
                },
                selectedColor: AppTheme.accentGold.withOpacity(0.3),
              )).toList(),
            ),
          ).animate().fadeIn(delay: 400.ms),

          const SizedBox(height: 32),

          // Motor & Interaction
          _SectionHeader(
            icon: LucideIcons.hand,
            title: 'Touch & Controls',
            subtitle: 'Make buttons easier to use',
          ).animate().fadeIn(delay: 450.ms),
          const SizedBox(height: 16),
          
          _ToggleSetting(
            icon: LucideIcons.maximize,
            title: 'Large Touch Targets',
            subtitle: 'Make buttons and controls easier to tap',
            value: _largeButtons,
            onChanged: (v) => setState(() => _largeButtons = v),
          ).animate().fadeIn(delay: 500.ms),
          
          _ToggleSetting(
            icon: LucideIcons.sparkles,
            title: 'Reduce Motion',
            subtitle: 'Minimize animations and transitions',
            value: _reduceMotion,
            onChanged: (v) => setState(() => _reduceMotion = v),
          ).animate().fadeIn(delay: 550.ms),
          
          _ToggleSetting(
            icon: LucideIcons.mic,
            title: 'Voice Control',
            subtitle: 'Navigate and control app using voice commands',
            value: _voiceControl,
            onChanged: (v) => setState(() => _voiceControl = v),
          ).animate().fadeIn(delay: 600.ms),

          const SizedBox(height: 32),

          // Cognitive
          _SectionHeader(
            icon: LucideIcons.brain,
            title: 'Simplify',
            subtitle: 'Reduce clutter & complexity',
          ).animate().fadeIn(delay: 650.ms),
          const SizedBox(height: 16),
          
          _ToggleSetting(
            icon: LucideIcons.layoutGrid,
            title: 'Simplified Interface',
            subtitle: 'Show only essential features',
            value: _simplifiedUI,
            onChanged: (v) => setState(() => _simplifiedUI = v),
          ).animate().fadeIn(delay: 700.ms),
          
          _ToggleSetting(
            icon: LucideIcons.image,
            title: 'Picture Mode',
            subtitle: 'Replace text with icons and images',
            value: _pictureMode,
            onChanged: (v) => setState(() => _pictureMode = v),
          ).animate().fadeIn(delay: 750.ms),
          
          _ToggleSetting(
            icon: LucideIcons.volume2,
            title: 'Screen Reader Support',
            subtitle: 'Optimize for TalkBack/VoiceOver',
            value: _screenReader,
            onChanged: (v) => setState(() => _screenReader = v),
          ).animate().fadeIn(delay: 800.ms),

          const SizedBox(height: 32),

          // Language
          _SectionHeader(
            icon: LucideIcons.globe,
            title: 'Language & Region',
            subtitle: 'Choose your preferred language',
          ).animate().fadeIn(delay: 850.ms),
          const SizedBox(height: 16),
          
          _SettingCard(
            title: 'App Language',
            subtitle: 'Select your preferred language',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _languages.map((lang) => ChoiceChip(
                label: Text(lang),
                selected: _selectedLanguage == lang,
                onSelected: (selected) {
                  if (selected) setState(() => _selectedLanguage = lang);
                },
                selectedColor: AppTheme.accentGold.withOpacity(0.3),
              )).toList(),
            ),
          ).animate().fadeIn(delay: 900.ms),

          const SizedBox(height: 32),

          // Emergency & Help
          _SectionHeader(
            icon: LucideIcons.heartPulse,
            title: 'Emergency & Help',
            subtitle: 'Quick access when you need it',
          ).animate().fadeIn(delay: 950.ms),
          const SizedBox(height: 16),
          
          _ActionCard(
            icon: LucideIcons.phone,
            title: 'Emergency Contact',
            subtitle: 'Set up emergency contacts for quick access',
            color: AppTheme.statusFailed,
            onTap: () => _showEmergencySetup(),
          ).animate().fadeIn(delay: 1000.ms),
          
          const SizedBox(height: 12),
          
          _ActionCard(
            icon: LucideIcons.helpCircle,
            title: 'Feature Guide',
            subtitle: 'Learn what each setting does',
            color: AppTheme.statusProcessing,
            onTap: () => _showHelp(),
          ).animate().fadeIn(delay: 1050.ms),

          const SizedBox(height: 100),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ElevatedButton(
            onPressed: _saveSettings,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.accentGold,
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('Save Settings', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }

  void _applyProfile(String profile) {
    setState(() {
      switch (profile) {
        case 'kids':
          _textScale = 1.2;
          _pictureMode = true;
          _simplifiedUI = true;
          _largeButtons = true;
          _reduceMotion = false; // Kids like animations!
          break;
        case 'student':
          _textScale = 1.0;
          _pictureMode = false;
          _simplifiedUI = false;
          _dyslexiaFont = false;
          break;
        case 'senior':
          _textScale = 1.5;
          _highContrast = true;
          _largeButtons = true;
          _simplifiedUI = true;
          _reduceMotion = true;
          break;
        case 'lowVision':
          _textScale = 2.0;
          _highContrast = true;
          _screenReader = true;
          _largeButtons = true;
          break;
        case 'voiceOnly':
          _voiceControl = true;
          _screenReader = true;
          _largeButtons = true;
          break;
        case 'pictureMode':
          _pictureMode = true;
          _simplifiedUI = true;
          _largeButtons = true;
          _textScale = 1.3;
          break;
      }
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Applied ${profile.replaceAll(RegExp(r'([A-Z])'), ' \$1').trim()} profile'),
        backgroundColor: AppTheme.accentGold,
      ),
    );
  }

  void _resetToDefaults() {
    setState(() {
      _textScale = 1.0;
      _highContrast = false;
      _reduceMotion = false;
      _screenReader = false;
      _dyslexiaFont = false;
      _pictureMode = false;
      _voiceControl = false;
      _largeButtons = false;
      _simplifiedUI = false;
      _colorBlindMode = 'None';
      _selectedLanguage = 'English';
    });
  }

  void _saveSettings() {
    // TODO: Save to preferences
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('✓ Accessibility settings saved!'),
        backgroundColor: AppTheme.statusReady,
      ),
    );
    Navigator.pop(context);
  }

  void _showEmergencySetup() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.heartPulse, size: 48, color: AppTheme.statusFailed),
            const SizedBox(height: 16),
            Text('Emergency Setup', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text('Add emergency contacts and medical info for quick access'),
            const SizedBox(height: 24),
            // Emergency contact fields would go here
            const TextField(
              decoration: InputDecoration(
                labelText: 'Emergency Contact Name',
                prefixIcon: Icon(LucideIcons.user),
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Emergency Phone Number',
                prefixIcon: Icon(LucideIcons.phone),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(LucideIcons.save),
              label: const Text('Save Emergency Info'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.statusFailed,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelp() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Container(
          padding: const EdgeInsets.all(24),
          child: ListView(
            controller: scrollController,
            children: [
              const Center(
                child: Icon(LucideIcons.sparkles, size: 48, color: AppTheme.accentGold),
              ),
              const SizedBox(height: 16),
              Text('Feature Guide', 
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              _HelpItem(
                icon: LucideIcons.type,
                title: 'Text Size',
                description: 'Make text larger or smaller. Use the slider to find a comfortable size.',
              ),
              _HelpItem(
                icon: LucideIcons.contrast,
                title: 'High Contrast',
                description: 'Increases the difference between colors to make content easier to see.',
              ),
              _HelpItem(
                icon: LucideIcons.mic,
                title: 'Voice Control',
                description: 'Control the app using your voice. Say "Hey Butler" followed by a command.',
              ),
              _HelpItem(
                icon: LucideIcons.image,
                title: 'Picture Mode',
                description: 'Replaces text with pictures and icons for easier understanding.',
              ),
              _HelpItem(
                icon: LucideIcons.layoutGrid,
                title: 'Simplified Mode',
                description: 'Shows only the most important features to reduce confusion.',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _SectionHeader({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.accentGold.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppTheme.accentGold, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProfileChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ProfileChip({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: color),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color.withOpacity(0.3)),
    );
  }
}

class _ToggleSetting extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleSetting({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: SwitchListTile(
        secondary: Icon(icon, color: value ? AppTheme.accentGold : AppTheme.textMutedDark),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        value: value,
        onChanged: onChanged,
        activeColor: AppTheme.accentGold,
      ),
    );
  }
}

class _SettingCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _SettingCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).colorScheme.outline),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              Icon(LucideIcons.chevronRight, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _HelpItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _HelpItem({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: AppTheme.accentGold),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.titleSmall),
                const SizedBox(height: 4),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
