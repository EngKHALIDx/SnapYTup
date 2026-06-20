import 'dart:convert';
import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';

/// In-app update checker. Snaptube checks for updates on every launch.
/// For MediaGrab we just compare the installed version string against a
/// remote JSON (e.g. a GitHub release); if newer, the UI shows a banner.
class AppUpdateService {
  /// Fetch the latest version string from a remote endpoint.
  /// Returns `null` on any failure (network, JSON parse, etc.).
  Future<String?> fetchLatestVersion({String url =
      'https://api.github.com/repos/EngKHALIDx/SnapYTup/releases/latest'}) async {
    try {
      final client = HttpClient();
      final req = await client.getUrl(Uri.parse(url));
      req.headers.add('Accept', 'application/vnd.github+json');
      final res = await req.close();
      if (res.statusCode != 200) {
        client.close();
        return null;
      }
      final body = await res.transform(utf8.decoder).join();
      client.close();
      // Quick regex extract of "tag_name":"vX.Y.Z" — avoids pulling dart:convert JSON.
      final match = RegExp(r'"tag_name"\s*:\s*"([^"]+)"').firstMatch(body);
      return match?.group(1)?.replaceFirst(RegExp(r'^[vV]'), '');
    } catch (_) {
      return null;
    }
  }

  /// Currently installed version string.
  Future<String> currentVersion() async {
    final info = await PackageInfo.fromPlatform();
    return info.version;
  }

  /// Compare semantic versions: returns true if [remote] is newer than [local].
  bool isNewer(String local, String remote) {
    final l = local.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    final r = remote.split('.').map((e) => int.tryParse(e) ?? 0).toList();
    for (var i = 0; i < l.length || i < r.length; i++) {
      final li = i < l.length ? l[i] : 0;
      final ri = i < r.length ? r[i] : 0;
      if (ri > li) return true;
      if (ri < li) return false;
    }
    return false;
  }
}

/// Riverpod provider.
final appUpdateProvider = Provider<AppUpdateService>((ref) {
  return AppUpdateService();
});

/// Async snapshot of update state.
final updateCheckProvider = FutureProvider<UpdateCheckResult?>((ref) async {
  final svc = ref.watch(appUpdateProvider);
  final current = await svc.currentVersion();
  final latest = await svc.fetchLatestVersion();
  if (latest == null) return null;
  return UpdateCheckResult(
    currentVersion: current,
    latestVersion: latest,
    updateAvailable: svc.isNewer(current, latest),
  );
});

class UpdateCheckResult {
  const UpdateCheckResult({
    required this.currentVersion,
    required this.latestVersion,
    required this.updateAvailable,
  });
  final String currentVersion;
  final String latestVersion;
  final bool updateAvailable;
}
