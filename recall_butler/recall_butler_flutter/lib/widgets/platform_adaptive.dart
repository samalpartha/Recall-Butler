import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:flutter/material.dart';

/// Utility class for platform-specific adaptations
class PlatformAdaptive {
  /// Check if running on iOS
  static bool get isIOS => !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;
  
  /// Check if running on Android
  static bool get isAndroid => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  
  /// Check if running on mobile (iOS or Android)
  static bool get isMobile => !kIsWeb && (defaultTargetPlatform == TargetPlatform.iOS || defaultTargetPlatform == TargetPlatform.android);
  
  /// Check if running on web
  static bool get isWeb => kIsWeb;
  
  /// Check if running on desktop
  static bool get isDesktop => !kIsWeb && (defaultTargetPlatform == TargetPlatform.macOS || defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux);
  
  /// Get appropriate border radius for platform
  static double get borderRadius => isIOS ? 12.0 : 8.0;
  
  /// Get appropriate padding for platform
  static EdgeInsets get screenPadding => isMobile 
    ? const EdgeInsets.all(16) 
    : const EdgeInsets.all(24);
    
  /// Get appropriate button height
  static double get buttonHeight => isMobile ? 48.0 : 44.0;
}

/// Platform-adaptive loading indicator
class AdaptiveLoadingIndicator extends StatelessWidget {
  final Color? color;
  
  const AdaptiveLoadingIndicator({super.key, this.color});
  
  @override
  Widget build(BuildContext context) {
    if (PlatformAdaptive.isIOS) {
      return CupertinoActivityIndicator(
        color: color,
      );
    }
    return CircularProgressIndicator(
      color: color,
    );
  }
}

/// Platform-adaptive button
class AdaptiveButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final Color? backgroundColor;
  final bool isDestructive;
  
  const AdaptiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.backgroundColor,
    this.isDestructive = false,
  });
  
  @override
  Widget build(BuildContext context) {
    if (PlatformAdaptive.isIOS) {
      return CupertinoButton(
        onPressed: onPressed,
        color: isDestructive ? CupertinoColors.destructiveRed : backgroundColor,
        borderRadius: BorderRadius.circular(PlatformAdaptive.borderRadius),
        child: child,
      );
    }
    
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: isDestructive ? Colors.red : backgroundColor,
        minimumSize: Size.fromHeight(PlatformAdaptive.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PlatformAdaptive.borderRadius),
        ),
      ),
      child: child,
    );
  }
}

/// Platform-adaptive dialog
class AdaptiveDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = 'OK',
    String? cancelText,
    bool isDestructive = false,
  }) async {
    if (PlatformAdaptive.isIOS) {
      return showCupertinoDialog<bool>(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            if (cancelText != null)
              CupertinoDialogAction(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(cancelText),
              ),
            CupertinoDialogAction(
              isDestructiveAction: isDestructive,
              onPressed: () => Navigator.of(context).pop(true),
              child: Text(confirmText),
            ),
          ],
        ),
      );
    }
    
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          if (cancelText != null)
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(cancelText),
            ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: isDestructive 
              ? TextButton.styleFrom(foregroundColor: Colors.red)
              : null,
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}

/// Platform-adaptive action sheet
class AdaptiveActionSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    String? title,
    String? message,
    required List<AdaptiveAction<T>> actions,
    AdaptiveAction<T>? cancelAction,
  }) async {
    if (PlatformAdaptive.isIOS) {
      return showCupertinoModalPopup<T>(
        context: context,
        builder: (context) => CupertinoActionSheet(
          title: title != null ? Text(title) : null,
          message: message != null ? Text(message) : null,
          actions: actions.map((action) => CupertinoActionSheetAction(
            onPressed: () => Navigator.of(context).pop(action.value),
            isDestructiveAction: action.isDestructive,
            child: Text(action.label),
          )).toList(),
          cancelButton: cancelAction != null 
            ? CupertinoActionSheetAction(
                onPressed: () => Navigator.of(context).pop(cancelAction.value),
                child: Text(cancelAction.label),
              )
            : null,
        ),
      );
    }
    
    return showModalBottomSheet<T>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (title != null)
              Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ...actions.map((action) => ListTile(
              leading: action.icon != null ? Icon(action.icon) : null,
              title: Text(
                action.label,
                style: action.isDestructive 
                  ? const TextStyle(color: Colors.red)
                  : null,
              ),
              onTap: () => Navigator.of(context).pop(action.value),
            )),
            if (cancelAction != null)
              ListTile(
                title: Text(cancelAction.label),
                onTap: () => Navigator.of(context).pop(cancelAction.value),
              ),
          ],
        ),
      ),
    );
  }
}

/// Action item for adaptive action sheet
class AdaptiveAction<T> {
  final String label;
  final T value;
  final IconData? icon;
  final bool isDestructive;
  
  const AdaptiveAction({
    required this.label,
    required this.value,
    this.icon,
    this.isDestructive = false,
  });
}

/// Platform-adaptive refresh indicator
class AdaptiveRefreshIndicator extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  
  const AdaptiveRefreshIndicator({
    super.key,
    required this.child,
    required this.onRefresh,
  });
  
  @override
  Widget build(BuildContext context) {
    if (PlatformAdaptive.isIOS) {
      return CustomScrollView(
        physics: const BouncingScrollPhysics(
          parent: AlwaysScrollableScrollPhysics(),
        ),
        slivers: [
          CupertinoSliverRefreshControl(
            onRefresh: onRefresh,
          ),
          SliverToBoxAdapter(child: child),
        ],
      );
    }
    
    return RefreshIndicator(
      onRefresh: onRefresh,
      child: child,
    );
  }
}

/// Safe area wrapper that respects notches and home indicators
class AdaptiveSafeArea extends StatelessWidget {
  final Widget child;
  final bool top;
  final bool bottom;
  final bool left;
  final bool right;
  
  const AdaptiveSafeArea({
    super.key,
    required this.child,
    this.top = true,
    this.bottom = true,
    this.left = true,
    this.right = true,
  });
  
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: child,
    );
  }
}

/// Responsive layout builder for different screen sizes
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;
  
  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });
  
  static bool isMobileScreen(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;
      
  static bool isTabletScreen(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;
      
  static bool isDesktopScreen(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;
  
  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    
    if (width >= 1200 && desktop != null) {
      return desktop!;
    }
    
    if (width >= 600 && tablet != null) {
      return tablet!;
    }
    
    return mobile;
  }
}
