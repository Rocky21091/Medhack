import 'package:flutter/material.dart';

class AppTheme {
  // Medical & Natural Color Palette
  static const Color primaryGreen = Color(0xFF0EA293); // Trustworthy Medical Teal/Green
  static const Color lightGreen = Color(0xFFE0F2F1);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color backgroundLight = Color(0xFFF8FAF9);
  static const Color textDark = Color(0xFF1E293B);
  static const Color textGrey = Color(0xFF64748B);

  static ThemeData get lightTheme {
    return ThemeData(
      scaffoldBackgroundColor: backgroundLight,
      brightness: Brightness.light,
      primaryColor: primaryGreen,
      colorScheme: const ColorScheme.light(
        primary: primaryGreen,
        secondary: primaryGreen,
        surface: pureWhite,
        background: backgroundLight,
      ),
      fontFamily: 'DM Sans', // Ensure this is in pubspec.yaml
      appBarTheme: const AppBarTheme(
        backgroundColor: pureWhite,
        elevation: 0, // Flat look, we add shadow to the app bar below
        centerTitle: true,
        iconTheme: IconThemeData(color: primaryGreen),
        titleTextStyle: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: textDark),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: pureWhite,
        selectedItemColor: primaryGreen,
        unselectedItemColor: textGrey,
        elevation: 20,
      ),
    );
  }

  // Helper for Glossy Cards
  static BoxDecoration get glossyCardDecoration {
    return BoxDecoration(
      color: pureWhite,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: primaryGreen.withOpacity(0.08),
          blurRadius: 24,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}