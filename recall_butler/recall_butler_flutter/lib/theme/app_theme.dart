import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Recall Butler Theme - Accessible, warm, and professional
/// Designed for the common good - high contrast, readable, inclusive
class AppTheme {
  // Primary colors - Warm, inviting, accessible
  static const Color primaryDark = Color(0xFF1A1A2E);  // Deep navy
  static const Color surfaceDark = Color(0xFF16213E);  // Rich surface
  static const Color cardDark = Color(0xFF1F2B4A);     // Card background
  
  // Accent colors - Distinguishable for accessibility
  static const Color accentGold = Color(0xFFFFB703);   // Warm gold - primary action
  static const Color accentCopper = Color(0xFFE85D04); // Warm copper - secondary
  static const Color accentTeal = Color(0xFF06D6A0);   // Fresh teal - success
  
  // Status colors - High contrast for visibility
  static const Color statusReady = Color(0xFF06D6A0);      // Green - completed
  static const Color statusProcessing = Color(0xFF4CC9F0); // Blue - in progress
  static const Color statusFailed = Color(0xFFEF476F);     // Red - error
  static const Color statusWarning = Color(0xFFFFD166);    // Yellow - warning
  
  // Text colors - WCAG AA compliant contrast
  static const Color textPrimaryDark = Color(0xFFF8F9FA);
  static const Color textSecondaryDark = Color(0xFFCED4DA);
  static const Color textMutedDark = Color(0xFF6C757D);
  
  // Light theme colors
  static const Color primaryLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFF1F3F5);
  static const Color textPrimaryLight = Color(0xFF212529);
  static const Color textSecondaryLight = Color(0xFF495057);

  /// Dark Theme - Primary for Recall Butler
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color scheme
      colorScheme: const ColorScheme.dark(
        primary: accentGold,
        secondary: accentCopper,
        tertiary: accentTeal,
        surface: surfaceDark,
        onPrimary: primaryDark,
        onSecondary: Colors.white,
        onSurface: textPrimaryDark,
        outline: Color(0xFF3D4A5C),
        error: statusFailed,
      ),
      
      scaffoldBackgroundColor: primaryDark,
      
      // Typography - Accessible, readable font
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(
            color: textPrimaryDark,
            fontSize: 32,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
          displayMedium: TextStyle(
            color: textPrimaryDark,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          headlineLarge: TextStyle(
            color: textPrimaryDark,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
          headlineMedium: TextStyle(
            color: textPrimaryDark,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
          headlineSmall: TextStyle(
            color: textPrimaryDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          titleLarge: TextStyle(
            color: textPrimaryDark,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
          titleMedium: TextStyle(
            color: textPrimaryDark,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          titleSmall: TextStyle(
            color: textPrimaryDark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
          bodyLarge: TextStyle(
            color: textSecondaryDark,
            fontSize: 16,
            height: 1.6,
          ),
          bodyMedium: TextStyle(
            color: textSecondaryDark,
            fontSize: 14,
            height: 1.5,
          ),
          bodySmall: TextStyle(
            color: textMutedDark,
            fontSize: 12,
            height: 1.4,
          ),
          labelLarge: TextStyle(
            color: textPrimaryDark,
            fontSize: 14,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // AppBar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimaryDark,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
        iconTheme: IconThemeData(color: textPrimaryDark),
      ),
      
      // Cards - Subtle, elegant
      cardTheme: CardThemeData(
        color: cardDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF2D3A4F), width: 1),
        ),
      ),
      
      // Input fields - High contrast for accessibility
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardDark,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3D4A5C)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF3D4A5C)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: accentGold, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: statusFailed, width: 1),
        ),
        labelStyle: const TextStyle(color: textMutedDark),
        hintStyle: const TextStyle(color: textMutedDark),
        prefixIconColor: textMutedDark,
      ),
      
      // Elevated buttons - Primary actions
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentGold,
          foregroundColor: primaryDark,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
      
      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accentGold,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      
      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accentGold,
          side: const BorderSide(color: accentGold),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      
      // Icon buttons
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: textSecondaryDark,
        ),
      ),
      
      // FAB - Primary action highlight
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: accentGold,
        foregroundColor: primaryDark,
        elevation: 4,
        shape: StadiumBorder(),
      ),
      
      // Bottom navigation
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: accentGold,
        unselectedItemColor: textMutedDark,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
      ),
      
      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: cardDark,
        contentTextStyle: const TextStyle(color: textPrimaryDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
      
      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      
      // Bottom sheet
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: surfaceDark,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
      
      // Chips
      chipTheme: ChipThemeData(
        backgroundColor: cardDark,
        labelStyle: const TextStyle(color: textSecondaryDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        side: const BorderSide(color: Color(0xFF3D4A5C)),
      ),
      
      // Divider
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2D3A4F),
        space: 1,
      ),
      
      // Progress indicators
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: accentGold,
        linearTrackColor: cardDark,
      ),
    );
  }
  
  /// Light Theme - Alternative for accessibility
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      colorScheme: const ColorScheme.light(
        primary: Color(0xFFE85D04),  // Warm orange
        secondary: accentTeal,
        tertiary: accentGold,
        surface: surfaceLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textPrimaryLight,
        outline: Color(0xFFDEE2E6),
        error: statusFailed,
      ),
      
      scaffoldBackgroundColor: primaryLight,
      
      textTheme: GoogleFonts.interTextTheme(
        const TextTheme(
          displayLarge: TextStyle(color: textPrimaryLight, fontSize: 32, fontWeight: FontWeight.bold),
          headlineMedium: TextStyle(color: textPrimaryLight, fontSize: 22, fontWeight: FontWeight.w700),
          titleLarge: TextStyle(color: textPrimaryLight, fontSize: 18, fontWeight: FontWeight.w600),
          titleMedium: TextStyle(color: textPrimaryLight, fontSize: 16, fontWeight: FontWeight.w600),
          bodyLarge: TextStyle(color: textSecondaryLight, fontSize: 16, height: 1.6),
          bodyMedium: TextStyle(color: textSecondaryLight, fontSize: 14, height: 1.5),
        ),
      ),
      
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleTextStyle: TextStyle(color: textPrimaryLight, fontSize: 20, fontWeight: FontWeight.bold),
        iconTheme: IconThemeData(color: textPrimaryLight),
      ),
      
      cardTheme: CardThemeData(
        color: cardLight,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFDEE2E6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFE85D04), width: 2),
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE85D04),
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}
