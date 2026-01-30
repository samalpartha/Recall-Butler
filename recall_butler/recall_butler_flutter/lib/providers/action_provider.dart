import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_butler_client/recall_butler_client.dart';
import '../services/api_service.dart';
import 'connectivity_provider.dart';

/// Provider for the currently proposed action (if any)
final currentActionProvider = StateProvider<ButlerAction?>((ref) => null);

/// Provider for managing action processing logic
final actionProcessingProvider = StateNotifierProvider<ActionNotifier, AsyncValue<ButlerAction?>>((ref) {
  final api = ref.watch(apiServiceProvider);
  return ActionNotifier(api, ref);
});

class ActionNotifier extends StateNotifier<AsyncValue<ButlerAction?>> {
  final ApiService _api;
  final Ref _ref;

  ActionNotifier(this._api, this._ref) : super(const AsyncValue.data(null));

  /// Parse natural language text into a structured action
  Future<void> analyzeText(String text) async {
    if (text.trim().isEmpty) return;

    state = const AsyncValue.loading();
    try {
      final action = await _api.objectify(text);
      
      // Only set if we got a valid action with high confidence
      if (action != null) {
        _ref.read(currentActionProvider.notifier).state = action;
        state = AsyncValue.data(action);
      } else {
        // No action detected, just clear
        state = const AsyncValue.data(null);
      }
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Execute the action currently held in currentActionProvider
  Future<bool> executeCurrentAction() async {
    final action = _ref.read(currentActionProvider);
    if (action == null) return false;

    // Ideally we'd update the status to 'executing' here
    // But since models are generated, we might assume the server handles status updates
    // or we'd need a local copy. For now, just execute.

    try {
      final success = await _api.executeAction(action);
      if (success) {
        // Clear the action upon successful execution
        clear(); 
      }
      return success;
    } catch (e) {
      // Keep the action in the provider so user can retry
      return false;
    }
  }

  /// Clear the current action (e.g. if user cancels)
  void clear() {
    _ref.read(currentActionProvider.notifier).state = null;
    state = const AsyncValue.data(null);
  }
}
