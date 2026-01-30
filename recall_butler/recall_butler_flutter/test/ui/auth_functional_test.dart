import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recall_butler_flutter/screens/auth_screen.dart';
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

    // Setup default states
    mockDocumentsNotifier.state = const AsyncValue.data([]);
    mockSuggestionsNotifier.state = const AsyncValue.data([]);
    mockPendingSyncCountNotifier.state = 0;
  });

  testWidgets('AuthScreen renders correctly', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(TestWrapper(
      child: const AuthScreen(),
    ));

    expect(find.text('Recall Butler'), findsOneWidget);
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
  });

  testWidgets('Can switch between Sign In and Sign Up', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(TestWrapper(
      child: const AuthScreen(),
    ));

    // Initially Sign In
    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text("Don't have an account?"), findsOneWidget);

    // Switch to Sign Up
    await tester.tap(find.text('Sign Up'));
    // Wait for fade animation; cannot use pumpAndSettle due to infinite background animation
    await tester.pump(const Duration(seconds: 1)); 

    expect(find.text('Create Account'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Confirm Password'), findsOneWidget);
    expect(find.text('Already have an account?'), findsOneWidget);

    // Switch back to Sign In
    await tester.tap(find.text('Sign In'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('Sign In'), findsOneWidget);
    expect(find.text('Username'), findsNothing);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
  });

  testWidgets('Validates empty fields', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(TestWrapper(
      child: const AuthScreen(),
    ));

    // Tap submit without entering data
    final signInButton = find.text('Sign In');
    await tester.ensureVisible(signInButton);
    await tester.tap(signInButton);
    await tester.pump(); // validation happens immediately

    expect(find.text('Please enter your email'), findsOneWidget);
    expect(find.text('Please enter your password'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
  });

  testWidgets('Navigates to HomeScreen on successful login', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);

    await tester.pumpWidget(TestWrapper(
      overrides: [
        documentsProvider.overrideWith((ref) => mockDocumentsNotifier),
        suggestionsProvider.overrideWith((ref) => mockSuggestionsNotifier),
        apiServiceProvider.overrideWithValue(mockApiService),
        isOnlineProvider.overrideWith((ref) => mockIsOnlineNotifier),
        pendingSyncCountProvider.overrideWith((ref) => mockPendingSyncCountNotifier),
      ],
      child: const AuthScreen(),
    ));

    // Fill form
    await tester.enterText(find.byType(TextFormField).at(0), 'test@example.com'); // Email
    await tester.enterText(find.byType(TextFormField).at(1), 'password123'); // Password

    // Submit
    final signInButton = find.text('Sign In').first;
    await tester.ensureVisible(signInButton);
    await tester.tap(signInButton);
    await tester.pump(); // Start loading
    
    // AuthScreen has a 2 second delay
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    await tester.pump(); // Login and Navigate
    await tester.pump(const Duration(milliseconds: 500)); // Transition
    await tester.pump(); // Settle

    // Verify HomeScreen is present
    expect(find.byType(HomeScreen), findsOneWidget);

    // Cleanup to stop infinite animations
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 5));
    await tester.pump();
  });
}
