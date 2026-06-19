import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_config.dart';

/// Persists the user's theme choice across launches.
class ThemeController extends StateNotifier<ThemeMode> {
  ThemeController(this._prefs) : super(_loadInitial(_prefs));

  final SharedPreferences _prefs;

  static ThemeMode _loadInitial(SharedPreferences prefs) {
    final name = prefs.getString(AppConfig.themeModeKey);
    if (name == 'dark') return ThemeMode.dark;
    if (name == 'light') return ThemeMode.light;
    return ThemeMode.system;
  }

  Future<void> set(ThemeMode mode) async {
    state = mode;
    await _prefs.setString(
      AppConfig.themeModeKey,
      mode == ThemeMode.dark ? 'dark' : mode == ThemeMode.light ? 'light' : 'system',
    );
  }

  Future<void> toggle() async {
    if (state == ThemeMode.dark) {
      await set(ThemeMode.light);
    } else {
      await set(ThemeMode.dark);
    }
  }
}

final themeControllerProvider = StateNotifierProvider<ThemeController, ThemeMode>(
  (ref) => throw UnimplementedError(
    'themeControllerProvider must be overridden in ProviderScope',
  ),
);

/// FutureProvider that boots SharedPreferences and returns an instance.
final sharedPrefsProvider = FutureProvider<SharedPreferences>((ref) async {
  return SharedPreferences.getInstance();
});
