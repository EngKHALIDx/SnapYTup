import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/services/history_service.dart';
import 'core/services/playlists_service.dart';
import 'core/services/theme_controller.dart';
import 'core/services/vault_controller.dart';
import 'core/utils/storage_utils.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait orientation on phones (tablets stay flexible).
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Request storage permissions up front so downloads don't fail later.
  await StorageUtils.ensureStoragePermission();

  final prefs = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        themeControllerProvider.overrideWith((ref) => ThemeController(prefs)),
        vaultControllerProvider.overrideWith((ref) => VaultController(prefs)),
        historyServiceProvider.overrideWith((ref) => HistoryService(prefs)),
        playlistsServiceProvider.overrideWith((ref) => PlaylistsService(prefs)),
      ],
      child: const MediaGrabApp(),
    ),
  );
}
