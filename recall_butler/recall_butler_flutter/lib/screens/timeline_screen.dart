import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../theme/vibrant_theme.dart';

class TimelineScreen extends ConsumerStatefulWidget {
  const TimelineScreen({super.key});

  @override
  ConsumerState<TimelineScreen> createState() => _TimelineScreenState();
}

class _TimelineScreenState extends ConsumerState<TimelineScreen> {
  final ScrollController _scrollController = ScrollController();
  String _selectedFilter = 'All'; // All, Voice, Web, Photo, Chat

  final List<String> _filters = ['All', 'Voice', 'Web', 'Photo', 'Chat'];

  // Mock Data
  final List<TimelineItem> _allItems = [
    TimelineItem(
      id: '1',
      type: TimelineType.voice,
      title: 'Morning Standup Notes',
      subtitle: 'Discussed project Alpha timeline and blockers.',
      timestamp: DateTime.now().subtract(const Duration(minutes: 45)),
      duration: '4:20',
    ),
    TimelineItem(
      id: '2',
      type: TimelineType.web,
      title: 'Flutter Animate Documentation',
      subtitle: 'pub.dev/packages/flutter_animate',
      timestamp: DateTime.now().subtract(const Duration(hours: 2)),
      imageUrl: 'https://pub.dev/static/img/pub-dev-logo-2x.png',
    ),
    TimelineItem(
      id: '3',
      type: TimelineType.photo,
      title: 'Whiteboard Session',
      subtitle: 'Architecture diagram for the backend.',
      timestamp: DateTime.now().subtract(const Duration(hours: 4)),
      imageUrl: 'assets/whiteboard_mock.jpg', // Placeholder
    ),
    TimelineItem(
      id: '4',
      type: TimelineType.chat,
      title: 'Chat with Butler',
      subtitle: 'Asked about "How to implement RAG pattern?"',
      timestamp: DateTime.now().subtract(const Duration(hours: 5, minutes: 30)),
    ),
    TimelineItem(
      id: '5',
      type: TimelineType.web,
      title: 'Medium Article: Riverpod 2.0',
      subtitle: 'medium.com/flutter/riverpod-2...',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 2)),
    ),
    TimelineItem(
      id: '6',
      type: TimelineType.voice,
      title: 'Idea for Hackathon',
      subtitle: 'Recall Butler: An AI that remembers everything for you.',
      timestamp: DateTime.now().subtract(const Duration(days: 1, hours: 5)),
      duration: '1:15',
    ),
  ];

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  List<TimelineItem> get _filteredItems {
    if (_selectedFilter == 'All') return _allItems;
    return _allItems.where((item) => item.type.name.toLowerCase() == _selectedFilter.toLowerCase()).toList();
  }

  Map<String, List<TimelineItem>> get _groupedItems {
    final grouped = <String, List<TimelineItem>>{};
    for (var item in _filteredItems) {
      final dateStr = _formatDate(item.timestamp);
      if (!grouped.containsKey(dateStr)) {
        grouped[dateStr] = [];
      }
      grouped[dateStr]!.add(item);
    }
    return grouped;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateCheck = DateTime(date.year, date.month, date.day);

    if (dateCheck == today) return 'Today';
    if (dateCheck == yesterday) return 'Yesterday';
    return DateFormat('MMMM d, yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedItems;

    return Scaffold(
      backgroundColor: AppTheme.primaryDark,
      body: Stack(
        children: [
          // Background Gradient
          Positioned.fill(
            child: Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [AppTheme.primaryDark, Color(0xFF10101E)],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildHeader(context),
                _buildFilters(),
                Expanded(
                  child: ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                    itemCount: grouped.keys.length,
                    itemBuilder: (context, index) {
                      final dateKey = grouped.keys.elementAt(index);
                      final items = grouped[dateKey]!;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDateHeader(dateKey),
                          ...items.map((item) => _buildTimelineTile(item, items.indexOf(item) == items.length - 1)),
                          const SizedBox(height: 24),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: Colors.white),
            onPressed: () => Navigator.pop(context),
            style: IconButton.styleFrom(
              backgroundColor: AppTheme.cardDark,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          const SizedBox(width: 16),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
               Text(
                'Memory Timeline',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                'Your digital footprint',
                style: TextStyle(
                  color: Colors.white54,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.cardDark,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.white10),
            ),
            child: const Icon(LucideIcons.search, color: Colors.white70, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _filters.length,
        itemBuilder: (context, index) {
          final filter = _filters[index];
          final isSelected = _selectedFilter == filter;
          
          return GestureDetector(
            onTap: () => setState(() => _selectedFilter = filter),
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.accentGold : AppTheme.cardDark,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSelected ? AppTheme.accentGold : Colors.white10,
                ),
              ),
              child: Text(
                filter,
                style: TextStyle(
                  color: isSelected ? AppTheme.primaryDark : Colors.white70,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDateHeader(String date) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16, left: 48), // Indent to align with content
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          date.toUpperCase(),
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 12,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineTile(TimelineItem item, bool isLast) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Line
          SizedBox(
            width: 48,
            child: Column(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryDark,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: item.color,
                      width: 3,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: Colors.white10,
                    ),
                  ),
              ],
            ),
          ),

          // Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Container(
                 decoration: BoxDecoration(
                  color: AppTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                   boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {},
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: item.color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(item.icon, size: 16, color: item.color),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      DateFormat('h:mm a').format(item.timestamp),
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.4),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item.subtitle,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 14,
                              height: 1.4,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (item.type == TimelineType.voice && item.duration != null) 
                            _buildAudioPlayer(item),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ).animate().fadeIn(duration: 400.ms).slideX(begin: 0.1),
        ],
      ),
    );
  }

  Widget _buildAudioPlayer(TimelineItem item) {
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(LucideIcons.play, size: 14, color: AppTheme.accentGold),
          const SizedBox(width: 8),
          // Fake waveform
          SizedBox(
            width: 60,
            height: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(8, (index) {
                return Container(
                  width: 3,
                  height: 4 + (index % 3) * 4.0,
                  decoration: BoxDecoration(
                    color: Colors.white38,
                    borderRadius: BorderRadius.circular(2),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            item.duration!,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 12,
              fontFamily: 'Monospace',
            ),
          ),
        ],
      ),
    );
  }
}

enum TimelineType { voice, web, photo, chat }

class TimelineItem {
  final String id;
  final TimelineType type;
  final String title;
  final String subtitle;
  final DateTime timestamp;
  final String? imageUrl;
  final String? duration;

  TimelineItem({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.timestamp,
    this.imageUrl,
    this.duration,
  });

  Color get color {
    switch (type) {
      case TimelineType.voice: return AppTheme.accentGold;
      case TimelineType.web: return AppTheme.accentTeal;
      case TimelineType.photo: return Colors.pinkAccent;
      case TimelineType.chat: return AppTheme.accentPurple;
    }
  }

  IconData get icon {
    switch (type) {
      case TimelineType.voice: return LucideIcons.mic;
      case TimelineType.web: return LucideIcons.globe;
      case TimelineType.photo: return LucideIcons.image;
      case TimelineType.chat: return LucideIcons.messageCircle;
    }
  }
}
