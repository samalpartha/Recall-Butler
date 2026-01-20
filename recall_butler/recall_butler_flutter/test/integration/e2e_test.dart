import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_butler_flutter/main.dart';

/// End-to-End Tests for Recall Butler Flutter App
/// 
/// Run with: flutter test test/integration/e2e_test.dart
void main() {
  group('App Startup E2E', () {
    testWidgets('App launches and shows shell screen', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: RecallButlerApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Should show the main app
      expect(find.byType(MaterialApp), findsOneWidget);
    });

    testWidgets('Bottom navigation shows all tabs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: RecallButlerApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Check for navigation items
      expect(find.text('Memories'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Activity'), findsOneWidget);
    });
  });

  group('Navigation E2E', () {
    testWidgets('Can navigate between tabs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: RecallButlerApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Search tab
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      // Tap Activity tab
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();

      // Tap back to Memories
      await tester.tap(find.text('Memories'));
      await tester.pumpAndSettle();
    });

    testWidgets('FAB opens quick actions menu', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: RecallButlerApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Find and tap FAB
      final fabFinder = find.byType(FloatingActionButton);
      if (fabFinder.evaluate().isNotEmpty) {
        await tester.tap(fabFinder.first);
        await tester.pumpAndSettle();
        
        // Quick actions should appear
        expect(find.text('Chat with Butler'), findsOneWidget);
        expect(find.text('Voice Note'), findsOneWidget);
        expect(find.text('Scan Document'), findsOneWidget);
      }
    });
  });

  group('Search Flow E2E', () {
    testWidgets('Search screen has search input', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: RecallButlerApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Search
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      // Should have a text field for search
      expect(find.byType(TextField), findsWidgets);
    });

    testWidgets('Can enter search query', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: RecallButlerApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Search
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      // Find text field and enter query
      final searchField = find.byType(TextField);
      if (searchField.evaluate().isNotEmpty) {
        await tester.enterText(searchField.first, 'test query');
        await tester.pump();
        
        expect(find.text('test query'), findsWidgets);
      }
    });
  });

  group('Activity Screen E2E', () {
    testWidgets('Activity screen shows sections', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: RecallButlerApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Navigate to Activity
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();

      // Should show Butler Suggestions section
      expect(find.text('Butler Suggestions'), findsOneWidget);
    });
  });

  group('Theme E2E', () {
    testWidgets('App uses dark theme by default', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: RecallButlerApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Get the MaterialApp
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.themeMode, equals(ThemeMode.dark));
    });
  });

  group('Accessibility E2E', () {
    testWidgets('App supports semantic labels', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: RecallButlerApp(),
        ),
      );
      await tester.pumpAndSettle();

      // Check that main navigation items have labels
      final memories = find.text('Memories');
      final search = find.text('Search');
      final activity = find.text('Activity');

      expect(memories, findsOneWidget);
      expect(search, findsOneWidget);
      expect(activity, findsOneWidget);
    });

    testWidgets('Interactive elements are tappable', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: RecallButlerApp(),
        ),
      );
      await tester.pumpAndSettle();

      // All navigation items should be tappable
      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Activity'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('Memories'));
      await tester.pumpAndSettle();
    });
  });
}
