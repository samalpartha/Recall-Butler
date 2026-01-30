import 'package:flutter/material.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_butler_flutter/services/api_service.dart';
import 'package:recall_butler_flutter/providers/documents_provider.dart';
import 'package:recall_butler_flutter/providers/suggestions_provider.dart';
import 'package:recall_butler_flutter/providers/connectivity_provider.dart';
import 'package:recall_butler_client/recall_butler_client.dart';

class MockApiService extends Mock implements ApiService {}

class MockDocumentsNotifier extends StateNotifier<AsyncValue<List<Document>>> 
    with Mock 
    implements DocumentsNotifier {
  MockDocumentsNotifier() : super(const AsyncValue.loading());
}

class MockSuggestionsNotifier extends StateNotifier<AsyncValue<List<Suggestion>>> 
    with Mock 
    implements SuggestionsNotifier {
  MockSuggestionsNotifier() : super(const AsyncValue.loading());
}

class MockIsOnlineNotifier extends StateNotifier<bool> 
    with Mock 
    implements IsOnlineNotifier {
  MockIsOnlineNotifier() : super(true);
}

class MockPendingSyncCountNotifier extends StateNotifier<int> 
    with Mock 
    implements PendingSyncCountNotifier {
  MockPendingSyncCountNotifier() : super(0);
}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class FakeRoute extends Fake implements Route<dynamic> {}
