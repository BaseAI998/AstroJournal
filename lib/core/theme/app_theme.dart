import 'package:flutter/material.dart';

class AppTheme {
  // Design Tokens (Medieval Parchment Theme - Minimalist)
  static const Color background = Color(0xFFF4EBD0); // Parchment beige
  static const Color panel = Color(0xFFE6D5B8);      // Darker parchment
  static const Color border = Color(0x26000000);     // Subtle ink border
  static const Color textPrimary = Color(0xDB000000);   // Deep ink black
  static const Color textSecondary = Color(0x8A000000); // Faded ink
  static const Color accentGold = Color(0xFFB8860B);    // Dark Goldenrod/Brass
  static const Color accentSepia = Color(0xFF704214);   // Sepia/Brown
  static const Color danger = Color(0xFF8B0000);        // Dark Red

  static ThemeData get retroTheme {
    return ThemeData(
      brightness: Brightness.light,
      scaffoldBackgroundColor: background,
      primaryColor: accentGold,
      colorScheme: const ColorScheme.light(
        primary: accentGold,
        secondary: accentSepia,
        surface: panel,
        error: danger,
        background: background,
      ),
      dividerColor: border,
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          color: textPrimary,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          fontFamily: 'serif',
        ),
        displayMedium: TextStyle(
          color: textPrimary,
          fontSize: 18,
          fontWeight: FontWeight.w500,
          fontFamily: 'serif',
        ),
        bodyLarge: TextStyle(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w400,
          fontFamily: 'serif',
        ),
        bodyMedium: TextStyle(
          color: textSecondary,
          fontSize: 14,
          fontWeight: FontWeight.w400,
          fontFamily: 'serif',
        ),
        bodySmall: TextStyle(
          color: textSecondary,
          fontSize: 12,
          fontWeight: FontWeight.w400,
          fontFamily: 'serif',
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: panel,
          foregroundColor: textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: const BorderSide(color: border, width: 0.5),
          ),
          elevation: 0, // 极简，去除阴影
        ),
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: accentGold,
        selectionColor: Color(0x40B8860B),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        hintStyle: TextStyle(color: textSecondary, fontFamily: 'serif'),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: background, // 融入背景
        selectedItemColor: accentGold,
        unselectedItemColor: textSecondary,
        elevation: 0, // 极简，无分割
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent, // 透明极简顶部
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 16,
          fontWeight: FontWeight.w500,
          fontFamily: 'serif',
        ),
      ),
    );
  }
}
