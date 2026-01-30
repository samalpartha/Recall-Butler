import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:recall_butler_flutter/theme/vibrant_theme.dart';

/// Wrapper for testing widgets with Riverpod and Material Theme
class TestWrapper extends StatelessWidget {
  final Widget child;
  final List<Override> overrides;

  const TestWrapper({
    super.key,
    required this.child,
    this.overrides = const [],
  });

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: overrides,
      child: MaterialApp(
        title: 'Test App',
        theme: VibrantTheme.darkTheme,
        home: child,
      ),
    );
  }
}
