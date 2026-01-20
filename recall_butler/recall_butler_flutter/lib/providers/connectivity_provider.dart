import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

/// Provider for API service
final apiServiceProvider = Provider<ApiService>((ref) {
  return ApiService();
});

/// Provider for online status
final isOnlineProvider = StateNotifierProvider<IsOnlineNotifier, bool>((ref) {
  final api = ref.watch(apiServiceProvider);
  return IsOnlineNotifier(api);
});

class IsOnlineNotifier extends StateNotifier<bool> {
  final ApiService _api;
  StreamSubscription? _subscription;

  IsOnlineNotifier(this._api) : super(_api.isOnline) {
    _subscription = _api.connectivityStream.listen((isOnline) {
      state = isOnline;
    });
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}

/// Provider for pending sync count
final pendingSyncCountProvider = StateNotifierProvider<PendingSyncCountNotifier, int>((ref) {
  final api = ref.watch(apiServiceProvider);
  return PendingSyncCountNotifier(api);
});

class PendingSyncCountNotifier extends StateNotifier<int> {
  final ApiService _api;
  Timer? _refreshTimer;

  PendingSyncCountNotifier(this._api) : super(_api.pendingSyncCount) {
    // Refresh count periodically
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      state = _api.pendingSyncCount;
    });
  }

  void refresh() {
    state = _api.pendingSyncCount;
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}

/// Provider to trigger manual sync
final syncTriggerProvider = Provider<Future<void> Function()>((ref) {
  final api = ref.watch(apiServiceProvider);
  return () async {
    await api.syncPending();
    ref.read(pendingSyncCountProvider.notifier).refresh();
  };
});

/// Provider for last sync time
final lastSyncTimeProvider = FutureProvider<DateTime?>((ref) async {
  // This would read from offline service
  return DateTime.now(); // Placeholder
});
