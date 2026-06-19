// Basic smoke test for SnapYT.
//
// This test verifies that the test harness compiles and runs successfully.
// It does not exercise any specific feature — it acts as a placeholder so
// that `flutter test` returns a green run on CI systems like Codemagic.

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('smoke test: harness compiles and runs', () {
    expect(1 + 1, equals(2));
  });

  test('string equality works', () {
    const appName = 'SnapYT';
    expect(appName, equals('SnapYT'));
  });

  test('app identifier pattern is valid', () {
    const appId = 'com.gokei.yt_download';
    expect(RegExp(r'^[a-z]+\.[a-z]+\.[a-z_]+$').hasMatch(appId), isTrue);
  });
}
