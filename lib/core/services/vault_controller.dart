import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Lightweight vault service that "locks" the Library tab behind a 4-digit
/// PIN. (Inspired by Snaptube's vault feature — this is a UI gate only, the
/// files themselves are still readable from the file system.)
///
/// Note: This is intentionally simple — for real privacy, you'd want to
/// move locked files into app-private storage and encrypt them. The MVP
/// just hides them from in-app browsing until the PIN is entered.
class VaultController extends StateNotifier<VaultState> {
  VaultController(this._prefs) : super(VaultState(locked: true, hasPin: _prefs.containsKey('vault_pin')));

  final SharedPreferences _prefs;

  /// Set a new PIN (4-digit string).
  Future<void> setPin(String pin) async {
    if (pin.length != 4 || int.tryParse(pin) == null) {
      throw ArgumentError('PIN must be exactly 4 digits.');
    }
    await _prefs.setString('vault_pin', pin);
    state = VaultState(locked: false, hasPin: true);
  }

  /// Try to unlock with [pin]; returns true on success.
  Future<bool> unlock(String pin) async {
    final stored = _prefs.getString('vault_pin');
    if (stored == null) {
      // No PIN set — interpret unlock as "set up new PIN".
      await setPin(pin);
      return true;
    }
    if (stored == pin) {
      state = VaultState(locked: false, hasPin: true);
      return true;
    }
    return false;
  }

  /// Lock the vault again.
  void lock() {
    state = VaultState(locked: true, hasPin: state.hasPin);
  }

  /// Remove the PIN entirely.
  Future<void> removePin() async {
    await _prefs.remove('vault_pin');
    state = const VaultState(locked: true, hasPin: false);
  }
}

class VaultState {
  const VaultState({required this.locked, required this.hasPin});
  final bool locked;
  final bool hasPin;
}

final vaultControllerProvider =
    StateNotifierProvider<VaultController, VaultState>((ref) {
  throw UnimplementedError('vaultControllerProvider must be overridden in ProviderScope');
});
