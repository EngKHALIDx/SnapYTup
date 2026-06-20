import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // iOS system colors
  static const blue = Color(0xFF007AFF);
  static const green = Color(0xFF34C759);
  static const red = Color(0xFFFF3B30);
  static const orange = Color(0xFFFF9500);

  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness b) {
    final isDark = b == Brightness.dark;
    final bg = isDark ? const Color(0xFF000000) : const Color(0xFFF2F2F7);
    final card = isDark ? const Color(0xFF1C1C1E) : Colors.white;
    final label = isDark ? Colors.white : Colors.black;
    final secondary = isDark ? const Color(0xFF8E8E93) : const Color(0xFF8E8E93);

    return ThemeData(
      useMaterial3: true,
      brightness: b,
      scaffoldBackgroundColor: bg,
      colorScheme: ColorScheme.fromSeed(
        seedColor: blue,
        brightness: b,
        primary: blue,
        secondary: blue,
        surface: card,
        onSurface: label,
        error: red,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: label,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: label,
          fontSize: 34,
          fontWeight: FontWeight.w700,
          letterSpacing: -0.5,
        ),
      ),
      cardTheme: CardThemeData(
        color: card,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? const Color(0xFF38383A) : const Color(0xFFC6C6C8),
        thickness: 0.5,
        space: 0.5,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          textStyle: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
      ),
      textTheme: TextTheme(
        headlineLarge: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: label),
        headlineMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, letterSpacing: -0.5, color: label),
        titleLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: -0.3, color: label),
        titleMedium: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: label),
        titleSmall: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: label),
        bodyLarge: TextStyle(fontSize: 17, color: label),
        bodyMedium: TextStyle(fontSize: 15, color: label),
        bodySmall: TextStyle(fontSize: 13, color: secondary),
        labelLarge: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: label),
      ),
      iconTheme: IconThemeData(color: label),
    );
  }
}
