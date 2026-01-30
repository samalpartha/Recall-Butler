import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recall_butler_flutter/screens/home_screen.dart';
import 'package:recall_butler_flutter/providers/documents_provider.dart';
import 'package:recall_butler_flutter/providers/suggestions_provider.dart';
import 'package:recall_butler_flutter/providers/connectivity_provider.dart';
import '../helpers/test_wrapper.dart';
import '../helpers/mocks.dart';

void main() {
  late MockDocumentsNotifier mockDocumentsNotifier;
  late MockSuggestionsNotifier mockSuggestionsNotifier;
  late MockApiService mockApiService;
  late MockPendingSyncCountNotifier mockPendingSyncCountNotifier;
  late MockIsOnlineNotifier mockIsOnlineNotifier;

  setUp(() {
    mockDocumentsNotifier = MockDocumentsNotifier();
    mockSuggestionsNotifier = MockSuggestionsNotifier();
    mockApiService = MockApiService();
    mockPendingSyncCountNotifier = MockPendingSyncCountNotifier();
    mockIsOnlineNotifier = MockIsOnlineNotifier();

    mockDocumentsNotifier.state = const AsyncValue.data([]);
    mockSuggestionsNotifier.state = const AsyncValue.data([]);
    mockPendingSyncCountNotifier.state = 0;
    mockIsOnlineNotifier.state = true;
  });

  testWidgets('HomeScreen renders correctly', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(TestWrapper(
      overrides: [
        documentsProvider.overrideWith((ref) => mockDocumentsNotifier),
        suggestionsProvider.overrideWith((ref) => mockSuggestionsNotifier),
        apiServiceProvider.overrideWithValue(mockApiService),
        pendingSyncCountProvider.overrideWith((ref) => mockPendingSyncCountNotifier),
        isOnlineProvider.overrideWith((ref) => mockIsOnlineNotifier),
      ],
      child: const HomeScreen(),
    ));

    // Check for critical UI elements
    expect(find.text('Recall Butler'), findsOneWidget);
    // expect(find.text('Good Morning'), findsNothing); // Can be present based on time
    expect(find.text('Weekly Activity'), findsOneWidget);
    
    // Check navigation items
    expect(find.byIcon(Icons.home), findsNothing); // Uses LucideIcons
    
    // Check FAB
    // expect(find.byType(FloatingActionButton), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
  });
}
