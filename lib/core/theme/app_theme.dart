import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';

/// App-wide Material 3 theme (Snaptube-inspired, both light & dark).
class AppTheme {
  AppTheme._();

  static const ColorScheme _darkScheme = ColorScheme.dark(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFF5A1D1E),
    onPrimaryContainer: Color(0xFFFFDAD6),
    secondary: AppColors.accent,
    onSecondary: Color(0xFF1A1A2E),
    secondaryContainer: Color(0xFF4A4419),
    onSecondaryContainer: Color(0xFFFFEBA8),
    tertiary: AppColors.secondary,
    surface: AppColors.darkSurface,
    onSurface: AppColors.textPrimaryDark,
    surfaceContainerHighest: AppColors.darkSurfaceAlt,
    onSurfaceVariant: AppColors.textSecondaryDark,
    outline: AppColors.darkBorder,
    error: AppColors.error,
    onError: Colors.white,
  );

  static const ColorScheme _lightScheme = ColorScheme.light(
    primary: AppColors.primary,
    onPrimary: Colors.white,
    primaryContainer: Color(0xFFFFDAD6),
    onPrimaryContainer: Color(0xFF410003),
    secondary: AppColors.accent,
    onSecondary: Color(0xFF1A1A2E),
    secondaryContainer: Color(0xFFFFEBA8),
    onSecondaryContainer: Color(0xFF4A4419),
    tertiary: AppColors.secondary,
    surface: AppColors.lightSurface,
    onSurface: AppColors.textPrimaryLight,
    surfaceContainerHighest: AppColors.lightSurfaceAlt,
    onSurfaceVariant: AppColors.textSecondaryLight,
    outline: AppColors.lightBorder,
    error: AppColors.error,
    onError: Colors.white,
  );

  static ThemeData dark() {
    final base = ThemeData.dark(useMaterial3: true).copyWith(
      colorScheme: _darkScheme,
      scaffoldBackgroundColor: AppColors.darkBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.darkBg,
        foregroundColor: AppColors.textPrimaryDark,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),
      cardTheme: CardThemeData(
        color: AppColors.darkSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.darkBorder, width: 0.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondaryDark,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: AppColors.textSecondaryDark),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.darkBorder,
        thickness: 0.5,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimaryDark),
    );
    return _applyTextStyles(base);
  }

  static ThemeData light() {
    final base = ThemeData.light(useMaterial3: true).copyWith(
      colorScheme: _lightScheme,
      scaffoldBackgroundColor: AppColors.lightBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.lightBg,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        centerTitle: false,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
      ),
      cardTheme: CardThemeData(
        color: AppColors.lightSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppColors.lightBorder, width: 0.5),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.lightSurface,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondaryLight,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.lightSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        hintStyle: const TextStyle(color: AppColors.textSecondaryLight),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.lightBorder,
        thickness: 0.5,
        space: 1,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimaryLight),
    );
    return _applyTextStyles(base);
  }

  static ThemeData _applyTextStyles(ThemeData base) {
    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displayLarge: base.textTheme.displayLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        headlineLarge: base.textTheme.headlineLarge?.copyWith(
          fontWeight: FontWeight.bold,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        labelLarge: base.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
