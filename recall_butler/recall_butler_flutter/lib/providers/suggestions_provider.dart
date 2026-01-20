import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_butler_client/recall_butler_client.dart';
import 'connectivity_provider.dart';

/// Provider for all suggestions
final suggestionsProvider = StateNotifierProvider<SuggestionsNotifier, AsyncValue<List<Suggestion>>>((ref) {
  final api = ref.watch(apiServiceProvider);
  return SuggestionsNotifier(api);
});

/// Provider for pending suggestions
final pendingSuggestionsProvider = FutureProvider<List<Suggestion>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getSuggestions(state: 'PROPOSED');
});

/// Provider for executed/accepted suggestions
final executedSuggestionsProvider = FutureProvider<List<Suggestion>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getSuggestions(state: 'ACCEPTED');
});

/// Provider for recent activity (all suggestions)
final recentActivityProvider = FutureProvider<List<Suggestion>>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getSuggestions();
});

/// Provider for pending suggestions count
final pendingSuggestionsCountProvider = FutureProvider<int>((ref) async {
  final api = ref.watch(apiServiceProvider);
  return api.getPendingCount();
});

/// Notifier for suggestion operations
class SuggestionsNotifier extends StateNotifier<AsyncValue<List<Suggestion>>> {
  final dynamic _api;

  SuggestionsNotifier(this._api) : super(const AsyncValue.loading()) {
    _loadSuggestions();
  }

  Future<void> _loadSuggestions() async {
    try {
      final suggestions = await _api.getSuggestions(state: 'PROPOSED');
      state = AsyncValue.data(suggestions);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> approve(int id) async {
    await _api.acceptSuggestion(id);
    await _loadSuggestions();
  }

  Future<void> accept(int id) async {
    await _api.acceptSuggestion(id);
    await _loadSuggestions();
  }

  Future<void> dismiss(int id) async {
    await _api.dismissSuggestion(id);
    await _loadSuggestions();
  }

  Future<void> refresh() => _loadSuggestions();
}
