import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  // NOTE: we no longer request storage permissions on startup.
  // The app saves files to getExternalStorageDirectory() (the app's own
  // private folder), which on Android 10+ (scoped storage) does NOT
  // require any permissions. Asking for permission unnecessarily would
  // confuse users and trigger Android's scary "Allow access to all files"
  // dialog for no good reason.
  runApp(const ProviderScope(child: MediaGrabApp()));
}
