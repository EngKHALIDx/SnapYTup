import 'package:flutter/material.dart';

/// Snaptube-inspired color palette.
/// (Not the exact Snaptube brand colors — these are typical "video downloader"
///  warm coral + cream + dark navy that match the genre.)
class AppColors {
  AppColors._();

  // Brand
  static const Color primary = Color(0xFFFF4E50);     // coral red
  static const Color primaryDark = Color(0xFFD63031);
  static const Color accent = Color(0xFFFECA57);      // warm yellow
  static const Color secondary = Color(0xFF4834D4);   // deep indigo

  // Dark theme surfaces
  static const Color darkBg = Color(0xFF0F0F1A);      // near-black navy
  static const Color darkSurface = Color(0xFF1A1A2E);
  static const Color darkSurfaceAlt = Color(0xFF16213E);
  static const Color darkBorder = Color(0xFF2D2D44);

  // Light theme surfaces
  static const Color lightBg = Color(0xFFF8F9FA);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFF1F3F5);
  static const Color lightBorder = Color(0xFFE2E5E9);

  // Text
  static const Color textPrimaryDark = Color(0xFFFFFFFF);
  static const Color textSecondaryDark = Color(0xFFB0B3C6);
  static const Color textPrimaryLight = Color(0xFF1A1A2E);
  static const Color textSecondaryLight = Color(0xFF6C7281);

  // States
  static const Color success = Color(0xFF26DE81);
  static const Color warning = Color(0xFFFFC312);
  static const Color error = Color(0xFFEB3B5A);
  static const Color info = Color(0xFF45AAF2);

  // Category tints (for the home grid)
  static const List<int> categoryTints = [
    0xFFFF6B6B, // Music
    0xFF4ECDC4, // Sports
    0xFFFFD93D, // Movies
    0xFF95D5B2, // Gaming
    0xFFA8DADC, // News
    0xFFFFB4A2, // Comedy
    0xFFBDB2FF, // Tech
    0xFFFFC8DD, // Fashion
  ];
}
