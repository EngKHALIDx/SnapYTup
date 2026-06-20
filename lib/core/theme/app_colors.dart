import 'package:flutter/material.dart';

/// Apple-inspired semantic color system.
///
/// These are NOT Snaptube colors — they're the iOS Material Design system
/// colors that adapt to light/dark mode and feel native on iPhone/iPad.
///
/// Reference: https://developer.apple.com/design/human-interface-guidelines/color
class AppColors {
  AppColors._();

  // Brand — Snaptube-inspired bright blue (#2196F3)
  static const Color primary = Color(0xFF2196F3);       // Snaptube blue
  static const Color primaryDark = Color(0xFF1976D2);   // dark-mode blue
  static const Color accent = Color(0xFFFF5252);        // accent red (audio badges)
  static const Color secondary = Color(0xFFFF5252);     // red for audio section
  static const Color tertiary = Color(0xFF2196F3);      // blue for video section

  // Apple semantic colors
  static const Color systemBlue = Color(0xFF2196F3);
  static const Color systemGreen = Color(0xFF34C759);
  static const Color systemIndigo = Color(0xFF5856D6);
  static const Color systemOrange = Color(0xFFFF9500);
  static const Color systemPink = Color(0xFFFF2D55);
  static const Color systemPurple = Color(0xFFAF52DE);
  static const Color systemRed = Color(0xFFFF5252);
  static const Color systemTeal = Color(0xFF30B0C7);
  static const Color systemYellow = Color(0xFFFFCC00);

  // Dark theme surfaces (Snaptube-style dark — #121212 base, not pure black)
  static const Color darkBg = Color(0xFF121212);            // Snaptube's background
  static const Color darkSurface = Color(0xFF1E1E1E);       // slightly elevated
  static const Color darkSurfaceAlt = Color(0xFF2C2C2C);    // cards
  static const Color darkSurfaceElevated = Color(0xFF333333); // toolbar / badges
  static const Color darkBorder = Color(0xFF333333);
  static const Color darkSeparator = Color(0xFF333333);

  // Light theme surfaces
  static const Color lightBg = Color(0xFFF2F2F7);           // grouped background
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceAlt = Color(0xFFE5E5EA);
  static const Color lightSurfaceElevated = Color(0xFFF9F9F9);
  static const Color lightBorder = Color(0xFFE5E5EA);
  static const Color lightSeparator = Color(0xFFC6C6C8);

  // Text (Apple-style)
  static const Color labelPrimary = Color(0xFF000000);
  static const Color labelSecondary = Color(0xFF3C3C43);    // 60% opacity on light
  static const Color labelTertiary = Color(0xFF3C3C43);     // 30% opacity on light
  static const Color labelQuaternary = Color(0xFF3C3C43);   // 18% opacity on light
  static const Color labelPrimaryDark = Color(0xFFFFFFFF);
  static const Color labelSecondaryDark = Color(0xFFEBEBF5); // 60% on dark
  static const Color labelTertiaryDark = Color(0xFFEBEBF5);  // 30% on dark

  // States
  static const Color success = Color(0xFF34C759);
  static const Color warning = Color(0xFFFFCC00);
  static const Color error = Color(0xFFFF3B30);
  static const Color info = Color(0xFF5AC8FA);

  // Fill colors (Apple's subtle backgrounds)
  static const Color fillPrimary = Color(0xFF787880);       // 20% opacity
  static const Color fillSecondary = Color(0xFF787880);     // 16% opacity
  static const Color fillTertiary = Color(0xFF767680);      // 12% opacity

  // Legacy aliases (kept so existing code keeps working)
  static const Color textPrimaryDark = labelPrimaryDark;
  static const Color textSecondaryDark = labelSecondaryDark;
  static const Color textPrimaryLight = labelPrimary;
  static const Color textSecondaryLight = labelSecondary;

  // Category tints (for the home grid) — Apple system colors
  static const List<int> categoryTints = [
    0xFFFF2D55, // systemPink - Music
    0xFF30B0C7, // systemTeal - Sports
    0xFFFF9500, // systemOrange - Movies
    0xFF34C759, // systemGreen - Gaming
    0xFF5AC8FA, // systemBlue - News
    0xFFAF52DE, // systemPurple - Comedy
    0xFF5856D6, // systemIndigo - Tech
    0xFFFF3B30, // systemRed - Fashion
  ];
}
