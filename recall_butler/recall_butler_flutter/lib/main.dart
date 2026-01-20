import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'theme/vibrant_theme.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Set system UI overlay style for immersive experience
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: VibrantTheme.bgDark,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  // Initialize notification service
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();
  
  // Initialize offline support
  final apiService = ApiService();
  await apiService.initializeOffline();
  
  runApp(
    const ProviderScope(
      child: RecallButlerApp(),
    ),
  );
}

class RecallButlerApp extends ConsumerWidget {
  const RecallButlerApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'Recall Butler',
      debugShowCheckedModeBanner: false,
      theme: VibrantTheme.darkTheme,
      darkTheme: VibrantTheme.darkTheme,
      themeMode: ThemeMode.dark,
      home: const SplashScreen(),
    );
  }
}
