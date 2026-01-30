import 'package:flutter_riverpod/flutter_riverpod.dart';

// Simple model for settings
class AppSettings {
  final bool notificationsEnabled;
  final bool darkMode;
  final bool offlineMode;
  final bool biometricLock;
  final bool requireActionConfirmation;

  const AppSettings({
    this.notificationsEnabled = true,
    this.darkMode = true,
    this.offlineMode = true,
    this.biometricLock = false,
    this.requireActionConfirmation = true,
  });

  AppSettings copyWith({
    bool? notificationsEnabled,
    bool? darkMode,
    bool? offlineMode,
    bool? biometricLock,
    bool? requireActionConfirmation,
  }) {
    return AppSettings(
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      darkMode: darkMode ?? this.darkMode,
      offlineMode: offlineMode ?? this.offlineMode,
      biometricLock: biometricLock ?? this.biometricLock,
      requireActionConfirmation: requireActionConfirmation ?? this.requireActionConfirmation,
    );
  }
}

// Provider
final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings());

  // In a real app, load/save to SharedPreferences here

  void toggleNotifications(bool value) {
    state = state.copyWith(notificationsEnabled: value);
  }

  void toggleDarkMode(bool value) {
    state = state.copyWith(darkMode: value);
  }

  void toggleOfflineMode(bool value) {
    state = state.copyWith(offlineMode: value);
  }

  void toggleBiometricLock(bool value) {
    state = state.copyWith(biometricLock: value);
  }
  
  void toggleActionConfirmation(bool value) {
    state = state.copyWith(requireActionConfirmation: value);
  }
}
