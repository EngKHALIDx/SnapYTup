import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Counts down from a user-selected duration and stops the player when
/// the timer reaches zero. Snaptube ships this as a comfort feature.
class SleepTimerController extends StateNotifier<SleepTimerState> {
  SleepTimerController() : super(const SleepTimerState());

  Timer? _timer;

  /// Start a countdown for [minutes].
  void start(int minutes, {void Function()? onComplete}) {
    _timer?.cancel();
    final ends = DateTime.now().add(Duration(minutes: minutes));
    state = SleepTimerState(active: true, endsAt: ends);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final remaining = ends.difference(DateTime.now());
      if (remaining.isNegative) {
        cancel();
        onComplete?.call();
        return;
      }
      state = SleepTimerState(active: true, endsAt: ends);
    });
  }

  /// Cancel the active timer.
  void cancel() {
    _timer?.cancel();
    _timer = null;
    state = const SleepTimerState();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

class SleepTimerState {
  const SleepTimerState({this.active = false, this.endsAt});
  final bool active;
  final DateTime? endsAt;

  Duration? get remaining {
    if (endsAt == null) return null;
    final r = endsAt!.difference(DateTime.now());
    return r.isNegative ? Duration.zero : r;
  }
}

final sleepTimerProvider =
    StateNotifierProvider<SleepTimerController, SleepTimerState>((ref) {
  return SleepTimerController();
});
