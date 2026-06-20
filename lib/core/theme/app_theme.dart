import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// Apple HIG-inspired Material 3 theme.
///
/// Adapted from iOS Human Interface Guidelines:
/// - Large titles (SF Pro Display style)
/// - Grouped backgrounds (light gray / pure black)
/// - White cards on light; near-black cards on dark
/// - Subtle separators (1px hairlines)
/// - System colors with semantic meaning
class AppTheme {
  AppTheme._();

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.systemBlue,
      brightness: Brightness.light,
      primary: AppColors.systemBlue,
      onPrimary: Colors.white,
      secondary: AppColors.systemIndigo,
      surface: AppColors.lightSurface,
      onSurface: AppColors.labelPrimary,
      error: AppColors.systemRed,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.lightBg,
      // Apple-style large titles in navigation bars
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.labelPrimary,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.labelPrimary,
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      // Grouped-list style cards
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      // Cupertino-style bottom nav
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.systemBlue,
        unselectedItemColor: Color(0xFF8E8E93),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
        unselectedLabelStyle: TextStyle(fontSize: 10, fontWeight: w400),
      ),
      // Apple-style inputs
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurfaceAlt.withValues(alpha: 0.6),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: AppColors.labelTertiary.withValues(alpha: 0.6)),
      ),
      // Hairline separators
      dividerTheme: DividerThemeData(
        color: AppColors.lightSeparator.withValues(alpha: 0.5),
        thickness: 0.5,
        space: 0.5,
      ),
      // System colors
      iconTheme: const IconThemeData(color: AppColors.systemBlue),
      // Typography (SF Pro Text style on iOS)
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5),
        headlineLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.3),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.2),
        titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w400),       // body
        bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w400),       // subheadline
        bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400),        // footnote
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
      ),
      // Apple-style buttons
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.systemBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.systemBlue,
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w400),
        ),
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: AppColors.systemBlue,
        scaffoldBackgroundColor: AppColors.lightBg,
      ),
      // SnackBars in iOS style
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.darkSurface,
        contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.systemBlue,
      brightness: Brightness.dark,
      primary: AppColors.systemBlue,
      onPrimary: Colors.white,
      secondary: AppColors.systemIndigo,
      surface: AppColors.darkSurface,
      onSurface: AppColors.labelPrimaryDark,
      error: AppColors.systemRed,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.darkBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        foregroundColor: AppColors.labelPrimaryDark,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: AppColors.labelPrimaryDark,
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
          height: 1.2,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurfaceAlt,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.transparent,
        selectedItemColor: AppColors.systemBlue,
        unselectedItemColor: Color(0xFF8E8E93),
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        showUnselectedLabels: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurfaceAlt,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: TextStyle(color: AppColors.labelTertiaryDark.withValues(alpha: 0.6)),
      ),
      dividerTheme: DividerThemeData(
        color: AppColors.darkSeparator.withValues(alpha: 0.5),
        thickness: 0.5,
        space: 0.5,
      ),
      iconTheme: const IconThemeData(color: AppColors.systemBlue),
      textTheme: const TextTheme(
        displayLarge: TextStyle(fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Colors.white),
        displayMedium: TextStyle(fontSize: 32, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Colors.white),
        displaySmall: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: Colors.white),
        headlineLarge: TextStyle(fontSize: 26, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: Colors.white),
        headlineMedium: TextStyle(fontSize: 22, fontWeight: FontWeight.w600, letterSpacing: -0.3, color: Colors.white),
        headlineSmall: TextStyle(fontSize: 20, fontWeight: FontWeight.w600, letterSpacing: -0.2, color: Colors.white),
        titleLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Colors.white),
        titleMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
        titleSmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
        bodyLarge: TextStyle(fontSize: 17, fontWeight: FontWeight.w400, color: Colors.white),
        bodyMedium: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: Colors.white),
        bodySmall: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFFEBEBF5)),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
        labelMedium: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white),
        labelSmall: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFFEBEBF5)),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.systemBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.systemBlue,
        ),
      ),
      cupertinoOverrideTheme: const CupertinoThemeData(
        primaryColor: AppColors.systemBlue,
        scaffoldBackgroundColor: AppColors.darkBg,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.lightSurface,
        contentTextStyle: const TextStyle(color: AppColors.labelPrimary, fontSize: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ignore: constant_identifier_names
const w400 = FontWeight.w400;
