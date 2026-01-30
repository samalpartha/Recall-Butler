import 'package:flutter/material.dart';

/// Flutter Butler Theme - Navy Blue & Cyan professional theme
class VibrantTheme {
  // Primary colors - Flutter Butler logo colors
  static const Color primaryPurple = Color(0xFF2D5A8A);   // Medium navy blue
  static const Color primaryPink = Color(0xFF4FACFE);     // Light blue
  static const Color primaryBlue = Color(0xFF1E3A5F);     // Dark navy
  static const Color primaryCyan = Color(0xFF00D4FF);     // Bright cyan
  static const Color primaryGreen = Color(0xFF10B981);    // Success green
  static const Color primaryOrange = Color(0xFFF97316);   // Warning orange
  static const Color primaryYellow = Color(0xFFFACC15);   // Accent yellow
  static const Color primaryRed = Color(0xFFFF3B30);      // Utility red
  
  // Background colors - Darker navy tones
  static const Color bgDark = Color(0xFF0D1B2A);
  static const Color bgCard = Color(0xFF1B2838);
  static const Color bgCardLight = Color(0xFF253649);
  
  // Text colors
  static const Color textPrimary = Color(0xFFFFFFFF);
  static const Color textSecondary = Color(0xFFB8C5D3);
  static const Color textMuted = Color(0xFF6B7B8C);
  
  // Accent gradients - Navy to Cyan
  static const LinearGradient gradientPrimary = LinearGradient(
    colors: [Color(0xFF2D5A8A), Color(0xFF4FACFE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient gradientSecondary = LinearGradient(
    colors: [Color(0xFF4FACFE), Color(0xFF00D4FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient gradientSuccess = LinearGradient(
    colors: [primaryGreen, primaryCyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient gradientWarning = LinearGradient(
    colors: [primaryOrange, primaryYellow],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  static const LinearGradient gradientBackground = LinearGradient(
    colors: [Color(0xFF0D1B2A), Color(0xFF1B2838), Color(0xFF162447)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Neon glow colors
  static Color glowPurple = primaryPurple.withOpacity(0.6);
  static Color glowPink = primaryPink.withOpacity(0.6);
  static Color glowBlue = primaryBlue.withOpacity(0.6);
  static Color glowCyan = primaryCyan.withOpacity(0.6);

  // Theme data
  static ThemeData get darkTheme => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: bgDark,
    splashColor: primaryPink.withOpacity(0.2),
    highlightColor: primaryCyan.withOpacity(0.1),
    hoverColor: primaryPink.withOpacity(0.1),
    focusColor: primaryPink.withOpacity(0.2),
    
    colorScheme: const ColorScheme.dark(
      primary: primaryPink,
      secondary: primaryCyan,
      tertiary: primaryPurple,
      surface: bgCard,
      error: Color(0xFFEF4444),
      onError: Colors.white,
      errorContainer: Color(0xFF5C1A1A),
    ),
    
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontSize: 24,
        fontWeight: FontWeight.bold,
        color: textPrimary,
      ),
    ),
    
    cardTheme: CardThemeData(
      color: bgCard,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: primaryPink.withOpacity(0.2)),
      ),
    ),
    
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryPink,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: textPrimary,
        side: BorderSide(color: primaryPink.withOpacity(0.4)),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    ),
    
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: bgCardLight,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: primaryPink.withOpacity(0.2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: primaryPink, width: 2),
      ),
      hintStyle: const TextStyle(color: textMuted),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    ),
    
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: bgCard,
      selectedItemColor: primaryPink,
      unselectedItemColor: textMuted,
      type: BottomNavigationBarType.fixed,
      elevation: 0,
    ),
    
    textTheme: const TextTheme(
      displayLarge: TextStyle(fontSize: 57, fontWeight: FontWeight.bold, color: textPrimary),
      displayMedium: TextStyle(fontSize: 45, fontWeight: FontWeight.bold, color: textPrimary),
      displaySmall: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: textPrimary),
      headlineLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: textPrimary),
      headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w600, color: textPrimary),
      headlineSmall: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: textPrimary),
      titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, color: textPrimary),
      titleMedium: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPrimary),
      titleSmall: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
      bodyLarge: TextStyle(fontSize: 16, color: textPrimary),
      bodyMedium: TextStyle(fontSize: 14, color: textPrimary),
      bodySmall: TextStyle(fontSize: 12, color: textSecondary),
      labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: textPrimary),
      labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: textPrimary),
      labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: textSecondary),
    ),
  );
}
