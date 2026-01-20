import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_butler_client/recall_butler_client.dart';
import 'connectivity_provider.dart';

/// Provider for search query
final searchQueryProvider = StateProvider<String>((ref) => '');

/// Provider for search results
final searchResultsProvider = FutureProvider<SearchResponse?>((ref) async {
  final query = ref.watch(searchQueryProvider);
  if (query.isEmpty) return null;
  
  final api = ref.watch(apiServiceProvider);
  return api.search(query);
});

/// Provider for search loading state
final isSearchingProvider = StateProvider<bool>((ref) => false);
