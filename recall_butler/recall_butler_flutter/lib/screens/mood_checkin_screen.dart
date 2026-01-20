import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../providers/documents_provider.dart';

/// Mental health check-in and mood tracking
class MoodCheckinScreen extends ConsumerStatefulWidget {
  const MoodCheckinScreen({super.key});

  @override
  ConsumerState<MoodCheckinScreen> createState() => _MoodCheckinScreenState();
}

class _MoodCheckinScreenState extends ConsumerState<MoodCheckinScreen> {
  int? _selectedMood;
  final Set<String> _selectedFeelings = {};
  final TextEditingController _journalController = TextEditingController();
  bool _isPrivate = true;

  final List<Map<String, dynamic>> _moods = [
    {'emoji': '😊', 'label': 'Great', 'color': Colors.green},
    {'emoji': '🙂', 'label': 'Good', 'color': Colors.lightGreen},
    {'emoji': '😐', 'label': 'Okay', 'color': Colors.amber},
    {'emoji': '😔', 'label': 'Low', 'color': Colors.orange},
    {'emoji': '😢', 'label': 'Sad', 'color': Colors.deepOrange},
    {'emoji': '😰', 'label': 'Anxious', 'color': Colors.red},
  ];

  final List<String> _feelings = [
    'Grateful', 'Hopeful', 'Calm', 'Energetic', 'Productive',
    'Tired', 'Stressed', 'Overwhelmed', 'Lonely', 'Frustrated',
    'Excited', 'Content', 'Worried', 'Confused', 'Motivated',
  ];

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Header
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.purple.withOpacity(0.3),
                      Colors.blue.withOpacity(0.2),
                    ],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _getGreeting(),
                          style: Theme.of(context).textTheme.headlineMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'How are you feeling right now?',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: AppTheme.textMutedDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // Mood Selection
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Select your mood',
                    style: Theme.of(context).textTheme.titleMedium,
                  ).animate().fadeIn(delay: 100.ms),
                  const SizedBox(height: 16),
                  
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(_moods.length, (index) {
                      final mood = _moods[index];
                      final isSelected = _selectedMood == index;
                      
                      return GestureDetector(
                        onTap: () => setState(() => _selectedMood = index),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected 
                                ? (mood['color'] as Color).withOpacity(0.2)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected 
                                  ? mood['color'] as Color
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                mood['emoji'] as String,
                                style: TextStyle(
                                  fontSize: isSelected ? 36 : 28,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                mood['label'] as String,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected 
                                      ? mood['color'] as Color
                                      : AppTheme.textMutedDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(delay: (150 + index * 50).ms).scale(
                        begin: const Offset(0.8, 0.8),
                        delay: (150 + index * 50).ms,
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),

          // Feelings Tags
          if (_selectedMood != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      'What are you feeling? (optional)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ).animate().fadeIn(),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _feelings.map((feeling) {
                        final isSelected = _selectedFeelings.contains(feeling);
                        return FilterChip(
                          label: Text(feeling),
                          selected: isSelected,
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedFeelings.add(feeling);
                              } else {
                                _selectedFeelings.remove(feeling);
                              }
                            });
                          },
                          selectedColor: AppTheme.accentGold.withOpacity(0.3),
                          checkmarkColor: AppTheme.accentGold,
                        );
                      }).toList(),
                    ).animate().fadeIn(delay: 100.ms),
                  ],
                ),
              ),
            ),

          // Journal Entry
          if (_selectedMood != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 8),
                    Text(
                      'Add a note (optional)',
                      style: Theme.of(context).textTheme.titleMedium,
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _journalController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText: 'What\'s on your mind? This is your safe space...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                        fillColor: Theme.of(context).cardTheme.color,
                      ),
                    ).animate().fadeIn(delay: 250.ms),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(
                          _isPrivate ? LucideIcons.lock : LucideIcons.unlock,
                          size: 16,
                          color: AppTheme.textMutedDark,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _isPrivate ? 'Private entry' : 'Visible to caregivers',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Spacer(),
                        Switch(
                          value: _isPrivate,
                          onChanged: (v) => setState(() => _isPrivate = v),
                          activeColor: AppTheme.accentGold,
                        ),
                      ],
                    ).animate().fadeIn(delay: 300.ms),
                  ],
                ),
              ),
            ),

          // Quick Actions
          if (_selectedMood != null && _selectedMood! >= 3)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.purple.withOpacity(0.3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(LucideIcons.heart, color: Colors.purple, size: 20),
                              const SizedBox(width: 8),
                              Text(
                                'Need some support?',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  color: Colors.purple,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              _SupportChip(
                                icon: LucideIcons.wind,
                                label: 'Breathing',
                                onTap: () => _showBreathingExercise(),
                              ),
                              _SupportChip(
                                icon: LucideIcons.music,
                                label: 'Calm Sounds',
                                onTap: () {},
                              ),
                              _SupportChip(
                                icon: LucideIcons.phone,
                                label: 'Talk to Someone',
                                onTap: () => _showCrisisResources(),
                              ),
                              _SupportChip(
                                icon: LucideIcons.messageCircle,
                                label: 'Chat with Butler',
                                onTap: () => Navigator.pop(context),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.2),
                  ],
                ),
              ),
            ),

          // Gratitude Prompt
          if (_selectedMood != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.accentGold.withOpacity(0.1),
                        AppTheme.accentCopper.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(LucideIcons.sparkles, color: AppTheme.accentGold),
                          const SizedBox(width: 8),
                          Text(
                            'Gratitude moment',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              color: AppTheme.accentGold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Name one thing you\'re grateful for today, no matter how small.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 400.ms),
              ),
            ),

          // Save Button Space
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
      bottomNavigationBar: _selectedMood != null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _saveCheckin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _moods[_selectedMood!]['color'] as Color,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(LucideIcons.check),
                      const SizedBox(width: 8),
                      const Text('Save Check-in', style: TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤️';
    if (hour < 21) return 'Good evening 🌅';
    return 'Good night 🌙';
  }

  void _saveCheckin() async {
    if (_selectedMood == null) return;

    final mood = _moods[_selectedMood!];
    final title = 'Mood: ${mood['emoji']} ${mood['label']}';
    final content = StringBuffer();
    
    content.writeln('Mood: ${mood['emoji']} ${mood['label']}');
    content.writeln('Date: ${DateTime.now().toIso8601String().substring(0, 16)}');
    
    if (_selectedFeelings.isNotEmpty) {
      content.writeln('\nFeelings: ${_selectedFeelings.join(', ')}');
    }
    
    if (_journalController.text.isNotEmpty) {
      content.writeln('\nJournal Entry:');
      content.writeln(_journalController.text);
    }

    try {
      await ref.read(documentsProvider.notifier).createFromText(
        title: title,
        text: content.toString(),
      );
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Text('${mood['emoji']} '),
                const Text('Check-in saved! Take care of yourself 💚'),
              ],
            ),
            backgroundColor: mood['color'] as Color,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save: $e')),
        );
      }
    }
  }

  void _showBreathingExercise() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _BreathingExercise(),
    );
  }

  void _showCrisisResources() {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(LucideIcons.heartPulse, size: 48, color: AppTheme.statusFailed),
            const SizedBox(height: 16),
            Text('You\'re Not Alone', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            const Text(
              'If you\'re in crisis or need someone to talk to, these resources are here for you:',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            _CrisisResource(
              name: 'National Suicide Prevention',
              number: '988',
              description: '24/7 support',
            ),
            _CrisisResource(
              name: 'Crisis Text Line',
              number: 'Text HOME to 741741',
              description: 'Free 24/7 support',
            ),
            _CrisisResource(
              name: 'SAMHSA Helpline',
              number: '1-800-662-4357',
              description: 'Mental health & substance use',
            ),
            const SizedBox(height: 16),
            Text(
              '💚 Remember: Asking for help is a sign of strength',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _SupportChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _SupportChip({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: Colors.purple),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onTap,
      backgroundColor: Colors.purple.withOpacity(0.1),
      side: BorderSide(color: Colors.purple.withOpacity(0.3)),
    );
  }
}

class _CrisisResource extends StatelessWidget {
  final String name;
  final String number;
  final String description;

  const _CrisisResource({
    required this.name,
    required this.number,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.statusFailed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.phone, color: AppTheme.statusFailed),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(number, style: const TextStyle(color: AppTheme.statusFailed)),
                Text(description, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BreathingExercise extends StatefulWidget {
  const _BreathingExercise();

  @override
  State<_BreathingExercise> createState() => _BreathingExerciseState();
}

class _BreathingExerciseState extends State<_BreathingExercise> 
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _phase = 'Breathe In';
  int _count = 4;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 16),
    )..addListener(_updatePhase);
    _controller.repeat();
  }

  void _updatePhase() {
    final progress = _controller.value;
    setState(() {
      if (progress < 0.25) {
        _phase = 'Breathe In';
        _count = 4 - (progress * 16).floor();
      } else if (progress < 0.5) {
        _phase = 'Hold';
        _count = 4 - ((progress - 0.25) * 16).floor();
      } else if (progress < 0.75) {
        _phase = 'Breathe Out';
        _count = 4 - ((progress - 0.5) * 16).floor();
      } else {
        _phase = 'Hold';
        _count = 4 - ((progress - 0.75) * 16).floor();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFF1a1a2e),
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 16),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white30,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Box Breathing',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Colors.white,
            ),
          ),
          const Spacer(),
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final scale = 0.5 + (_controller.value < 0.5 
                  ? _controller.value 
                  : 1 - _controller.value);
              return Transform.scale(
                scale: scale,
                child: Container(
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        Colors.blue.withOpacity(0.3),
                        Colors.purple.withOpacity(0.2),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _phase,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        Text(
                          '$_count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '4 seconds in • 4 seconds hold • 4 seconds out • 4 seconds hold',
              style: TextStyle(color: Colors.white.withOpacity(0.5)),
              textAlign: TextAlign.center,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Done', style: TextStyle(color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
