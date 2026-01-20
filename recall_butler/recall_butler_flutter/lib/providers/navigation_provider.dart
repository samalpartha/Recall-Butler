import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Current navigation index
final navigationIndexProvider = StateProvider<int>((ref) => 0);

/// Navigation destinations
enum NavigationDestination {
  ingest,
  search,
  activity,
}

extension NavigationDestinationExtension on NavigationDestination {
  int get index {
    switch (this) {
      case NavigationDestination.ingest:
        return 0;
      case NavigationDestination.search:
        return 1;
      case NavigationDestination.activity:
        return 2;
    }
  }
}
