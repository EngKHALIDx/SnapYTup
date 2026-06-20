import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:io';
import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  await _requestPermissions();
  runApp(const ProviderScope(child: MediaGrabApp()));
}

Future<void> _requestPermissions() async {
  if (!Platform.isAndroid) return;
  final info = await DeviceInfoPlugin().androidInfo;
  if (info.version.sdkInt >= 33) {
    await Permission.videos.request();
    await Permission.audio.request();
    await Permission.photos.request();
  } else {
    await Permission.storage.request();
  }
}
