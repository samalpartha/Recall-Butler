import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:recall_butler_flutter/screens/home_screen.dart';
import 'package:recall_butler_flutter/screens/ai_agent_screen.dart';
import 'package:recall_butler_flutter/screens/chat_screen.dart';
import 'package:recall_butler_flutter/screens/search_screen.dart';
import 'package:recall_butler_flutter/screens/activity_screen.dart';
import 'package:recall_butler_flutter/screens/analytics_dashboard_screen.dart';
import 'package:recall_butler_flutter/screens/settings_screen.dart';
import 'package:recall_butler_flutter/screens/help_screen.dart';
import 'package:recall_butler_flutter/providers/documents_provider.dart';
import 'package:recall_butler_flutter/providers/suggestions_provider.dart';
import 'package:recall_butler_flutter/providers/connectivity_provider.dart';
import 'package:recall_butler_flutter/services/api_service.dart';
import '../helpers/mocks.dart';

void main() {
  late MockApiService mockApiService;
  late MockNavigatorObserver mockNavigatorObserver;

  setUp(() {
    mockApiService = MockApiService();
    mockNavigatorObserver = MockNavigatorObserver();
    
    registerFallbackValue(MaterialPageRoute<void>(builder: (_) => Container()));

    // Stub default API calls
    when(() => mockApiService.getDocuments(limit: any(named: 'limit')))
        .thenAnswer((_) async => []);
    when(() => mockApiService.getStats())
        .thenAnswer((_) async => {'total': 0, 'processed': 0});
  });

  Widget createSubject({
    List<Override> overrides = const [],
  }) {
    return ProviderScope(
      overrides: [
        apiServiceProvider.overrideWithValue(mockApiService),
        pendingSyncCountProvider.overrideWith((ref) => MockPendingSyncCountNotifier()),
        isOnlineProvider.overrideWith((ref) => MockIsOnlineNotifier()),
        documentsProvider.overrideWith((ref) => MockDocumentsNotifier()),
        suggestionsProvider.overrideWith((ref) => MockSuggestionsNotifier()),
        ...overrides,
      ],
      child: MaterialApp(
        home: const HomeScreen(),
        navigatorObservers: [mockNavigatorObserver],
        theme: ThemeData(
          fontFamily: 'Roboto',
          useMaterial3: true,
        ),
      ),
    );
  }

  group('HomeScreen Functional Tests', () {
    testWidgets('renders main content correctly', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump(const Duration(seconds: 3)); // Wait for entrance animations
      await tester.pump();

      expect(find.text('Recall Butler'), findsOneWidget);
      expect(find.text('Weekly Activity'), findsOneWidget);
      expect(find.text('Weekly Activity'), findsOneWidget);

      // Cleanup
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('navigates to Settings', (tester) async {
      await tester.pumpWidget(createSubject());
      await tester.pump(const Duration(seconds: 3));
      await tester.pump();

      final settingsFinder = find.ancestor(
        of: find.byIcon(LucideIcons.settings),
        matching: find.byType(GestureDetector),
      ).first; 
      
      await tester.tap(settingsFinder, warnIfMissed: false);
      await tester.pump(const Duration(seconds: 1));

      verify(() => mockNavigatorObserver.didPush(any(), any())).called(greaterThan(0));

      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(seconds: 1));
    });

  });
}

