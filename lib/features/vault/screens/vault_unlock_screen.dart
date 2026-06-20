import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/vault_controller.dart';
import '../../../core/theme/app_colors.dart';

/// 4-digit PIN entry screen for unlocking the Vault.
class VaultUnlockScreen extends ConsumerStatefulWidget {
  const VaultUnlockScreen({super.key});

  @override
  ConsumerState<VaultUnlockScreen> createState() => _VaultUnlockScreenState();
}

class _VaultUnlockScreenState extends ConsumerState<VaultUnlockScreen> {
  final _controller = TextEditingController();
  String? _error;
  bool _loading = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final pin = _controller.text.trim();
    if (pin.length != 4) {
      setState(() => _error = 'PIN must be 4 digits.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final ok = await ref.read(vaultControllerProvider.notifier).unlock(pin);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      setState(() => _error = 'Wrong PIN. Try again.');
      _controller.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final vault = ref.watch(vaultControllerProvider);
    final isSetup = !vault.hasPin;
    return Scaffold(
      appBar: AppBar(
        title: Text(isSetup ? 'Set up Vault PIN' : 'Unlock Vault'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Icon(
              isSetup ? Icons.lock_outline : Icons.lock_open_outlined,
              size: 64,
              color: AppColors.primary,
            ),
            const SizedBox(height: 16),
            Text(
              isSetup
                  ? 'Choose a 4-digit PIN to lock your private downloads. You\'ll need it every time you open the Vault tab.'
                  : 'Enter your 4-digit PIN to access your locked downloads.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 32),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              maxLength: 4,
              obscureText: true,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 16),
              decoration: const InputDecoration(
                hintText: '• • • •',
                counterText: '',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _loading ? null : _submit,
              icon: _loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check),
              label: Text(isSetup ? 'Set PIN' : 'Unlock'),
            ),
          ],
        ),
      ),
    );
  }
}
