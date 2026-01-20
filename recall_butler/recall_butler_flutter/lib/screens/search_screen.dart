import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../theme/app_theme.dart';
import '../providers/search_provider.dart';
import '../widgets/search_result_card.dart';

/// Search screen - Semantic recall across documents
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();
  bool _hasSearched = false;

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _performSearch() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      ref.read(searchQueryProvider.notifier).state = query;
      setState(() => _hasSearched = true);
      _focusNode.unfocus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final searchResults = ref.watch(searchResultsProvider);
    final currentQuery = ref.watch(searchQueryProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with Search
          SliverAppBar(
            floating: true,
            pinned: true,
            expandedHeight: 140,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                padding: const EdgeInsets.fromLTRB(20, 60, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Search Memories',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ).animate().fadeIn(duration: 300.ms),
                    const SizedBox(height: 4),
                    Text(
                      'Ask anything about your saved content',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ).animate().fadeIn(delay: 100.ms),
                  ],
                ),
              ),
            ),
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(80),
              child: Container(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: _SearchBar(
                  controller: _searchController,
                  focusNode: _focusNode,
                  onSearch: _performSearch,
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2),
              ),
            ),
          ),

          // Search Results or Suggestions
          if (!_hasSearched) ...[
            // Show suggestions when not searched yet
            SliverToBoxAdapter(
              child: _SearchSuggestions(
                onSuggestionTap: (query) {
                  _searchController.text = query;
                  _performSearch();
                },
              ),
            ),
          ] else ...[
            // Show results
            searchResults.when(
              data: (response) {
                if (response == null) {
                  return const SliverToBoxAdapter(child: SizedBox());
                }

                return SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // AI Answer
                        _AnswerCard(
                          query: currentQuery,
                          answer: response.answer,
                        ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1),

                        const SizedBox(height: 24),

                        // Sources header
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.fileText,
                              size: 18,
                              color: AppTheme.textSecondaryDark,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Sources (${response.results.length})',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ).animate().fadeIn(delay: 200.ms),

                        const SizedBox(height: 16),

                        // Source cards
                        ...response.results.asMap().entries.map((entry) {
                          final index = entry.key;
                          final result = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: SearchResultCard(result: result)
                                .animate()
                                .fadeIn(delay: (300 + index * 100).ms)
                                .slideX(begin: 0.1),
                          );
                        }),

                        if (response.results.isEmpty)
                          _NoResults()
                              .animate()
                              .fadeIn(delay: 300.ms),
                      ],
                    ),
                  ),
                );
              },
              loading: () => SliverToBoxAdapter(
                child: _SearchingIndicator()
                    .animate()
                    .fadeIn(),
              ),
              error: (error, _) => SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: _ErrorState(error: error.toString()),
                ),
              ),
            ),
          ],

          // Bottom padding
          const SliverToBoxAdapter(
            child: SizedBox(height: 100),
          ),
        ],
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onSearch;

  const _SearchBar({
    required this.controller,
    required this.focusNode,
    required this.onSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        onSubmitted: (_) => onSearch(),
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: 'What are you looking for?',
          hintStyle: TextStyle(color: AppTheme.textMutedDark),
          prefixIcon: const Padding(
            padding: EdgeInsets.only(left: 16, right: 12),
            child: Icon(LucideIcons.search, size: 20),
          ),
          suffixIcon: Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.arrowRight,
                  size: 18,
                  color: Colors.black,
                ),
              ),
              onPressed: onSearch,
            ),
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 18,
          ),
        ),
      ),
    );
  }
}

class _SearchSuggestions extends StatelessWidget {
  final Function(String) onSuggestionTap;

  const _SearchSuggestions({required this.onSuggestionTap});

  @override
  Widget build(BuildContext context) {
    final suggestions = [
      'What invoices are due this month?',
      'When is my next flight?',
      'What did we discuss in the last meeting?',
      'Show me all receipts from last week',
    ];

    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                LucideIcons.lightbulb,
                size: 18,
                color: AppTheme.accentGold,
              ),
              const SizedBox(width: 8),
              Text(
                'Try asking...',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ],
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: suggestions.asMap().entries.map((entry) {
              final index = entry.key;
              final suggestion = entry.value;
              return ActionChip(
                avatar: const Icon(LucideIcons.sparkles, size: 16),
                label: Text(suggestion),
                onPressed: () => onSuggestionTap(suggestion),
              ).animate().fadeIn(delay: (400 + index * 100).ms).scale(begin: const Offset(0.9, 0.9));
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _AnswerCard extends StatelessWidget {
  final String query;
  final String answer;

  const _AnswerCard({required this.query, required this.answer});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.accentGold.withOpacity(0.15),
            AppTheme.accentCopper.withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.accentGold.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.accentGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  LucideIcons.brain,
                  size: 20,
                  color: AppTheme.accentGold,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Butler\'s Answer',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.accentGold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            answer,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              height: 1.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchingIndicator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppTheme.accentGold.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.search,
              size: 32,
              color: AppTheme.accentGold,
            ),
          ).animate(onPlay: (c) => c.repeat())
            .shimmer(duration: 1500.ms),
          const SizedBox(height: 24),
          Text(
            'Searching your memories...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Finding the most relevant information',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _NoResults extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const Icon(
            LucideIcons.searchX,
            size: 48,
            color: AppTheme.textMutedDark,
          ),
          const SizedBox(height: 16),
          Text(
            'No matching memories found',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Try a different search query',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;

  const _ErrorState({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.statusFailed.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.statusFailed.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(LucideIcons.alertCircle, color: AppTheme.statusFailed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Search failed: $error',
              style: const TextStyle(color: AppTheme.statusFailed),
            ),
          ),
        ],
      ),
    );
  }
}
