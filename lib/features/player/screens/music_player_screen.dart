import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/format_utils.dart';
import '../services/sleep_timer_controller.dart';
import '../widgets/lyrics_panel.dart';

/// Audio player screen with queue, repeat modes, sleep timer and lyrics.
class MusicPlayerScreen extends ConsumerStatefulWidget {
  const MusicPlayerScreen({
    super.key,
    required this.queue,
    this.initialIndex = 0,
  });

  /// List of file paths to play.
  final List<String> queue;
  final int initialIndex;

  @override
  ConsumerState<MusicPlayerScreen> createState() => _MusicPlayerScreenState();
}

class _MusicPlayerScreenState extends ConsumerState<MusicPlayerScreen> {
  late AudioPlayer _player;
  late int _index;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.queue.length - 1);
    _player = AudioPlayer();
    _load();
  }

  Future<void> _load() async {
    try {
      await _player.setAudioSource(
        ConcatenatingAudioSource(
          children: widget.queue
              .map((path) => AudioSource.file(path))
              .toList(growable: false),
          useLazyPreparation: true,
        ),
        initialIndex: _index,
      );
      _player.play();
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
                ? Center(child: Text('Error: $_error', style: const TextStyle(color: AppColors.error)))
                : _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    final title = File(widget.queue[_index]).uri.pathSegments.last;
    return Column(
      children: [
        // Top bar
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.keyboard_arrow_down),
              onPressed: () => Navigator.of(context).maybePop(),
            ),
            const Spacer(),
            const Text('Now Playing', style: TextStyle(fontWeight: FontWeight.bold)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.lyrics_outlined),
              tooltip: 'Lyrics',
              onPressed: () => _showLyrics(context),
            ),
            IconButton(
              icon: const Icon(Icons.nightlight_outlined),
              tooltip: 'Sleep timer',
              onPressed: () => _showSleepTimer(context),
            ),
          ],
        ),
        // Album art placeholder
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColors.primary, AppColors.secondary],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Center(
                child: Icon(Icons.music_note, color: Colors.white, size: 96),
              ),
            ),
          ),
        ),
        // Title + controls
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 24),
              _progressBar(),
              const SizedBox(height: 16),
              _controls(),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }

  Widget _progressBar() {
    return StreamBuilder<Duration?>(
      stream: _player.positionStream,
      builder: (context, posSnap) {
        final pos = posSnap.data ?? Duration.zero;
        return StreamBuilder<Duration?>(
          stream: _player.durationStream,
          builder: (context, durSnap) {
            final dur = durSnap.data ?? Duration.zero;
            return Column(
              children: [
                Slider(
                  value: pos.inMilliseconds.toDouble().clamp(0, dur.inMilliseconds.toDouble() > 0 ? dur.inMilliseconds.toDouble() : pos.inMilliseconds.toDouble()),
                  min: 0,
                  max: (dur.inMilliseconds.toDouble() > 0 ? dur.inMilliseconds : pos.inMilliseconds + 1).toDouble(),
                  onChanged: (v) => _player.seek(Duration(milliseconds: v.toInt())),
                  activeColor: AppColors.primary,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(FormatUtils.duration(pos), style: const TextStyle(fontSize: 11)),
                      Text(FormatUtils.duration(dur), style: const TextStyle(fontSize: 11)),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLyrics(BuildContext context) {
    final title = File(widget.queue[_index]).uri.pathSegments.last;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => FractionallySizedBox(
        heightFactor: 0.7,
        child: LyricsPanel(artist: '', title: title.replaceAll(RegExp(r'\.\w+$'), '')),
      ),
    );
  }

  void _showSleepTimer(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) {
        return Consumer(
          builder: (ctx, ref, _) {
            final state = ref.watch(sleepTimerProvider);
            return SafeArea(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('Sleep timer', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  ),
                  if (state.active && state.remaining != null)
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Remaining: ${FormatUtils.duration(state.remaining)}',
                        style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600),
                      ),
                    ),
                  Wrap(
                    spacing: 8,
                    children: [5, 10, 15, 30, 45, 60].map((m) {
                      return ActionChip(
                        label: Text('$m min'),
                        onPressed: () {
                          ref.read(sleepTimerProvider.notifier).start(m, onComplete: _player.pause);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Music will stop in $m minutes.')),
                          );
                        },
                      );
                    }).toList(),
                  ),
                  if (state.active)
                    TextButton.icon(
                      onPressed: () {
                        ref.read(sleepTimerProvider.notifier).cancel();
                        Navigator.pop(ctx);
                      },
                      icon: const Icon(Icons.cancel),
                      label: const Text('Cancel timer'),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _controls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        StreamBuilder<LoopMode>(
          stream: _player.loopModeStream,
          builder: (context, snap) {
            final mode = snap.data ?? LoopMode.off;
            return IconButton(
              icon: Icon(
                mode == LoopMode.one ? Icons.repeat_one : Icons.repeat,
                color: mode == LoopMode.off ? null : AppColors.primary,
              ),
              onPressed: () {
                _player.setLoopMode(
                  mode == LoopMode.off
                      ? LoopMode.all
                      : mode == LoopMode.all
                          ? LoopMode.one
                          : LoopMode.off,
                );
              },
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.skip_previous, size: 36),
          onPressed: () => _player.seekToPrevious(),
        ),
        StreamBuilder<PlayerState>(
          stream: _player.playerStateStream,
          builder: (context, snap) {
            final playing = snap.data?.playing ?? false;
            return FloatingActionButton(
              onPressed: playing ? _player.pause : _player.play,
              backgroundColor: AppColors.primary,
              child: Icon(playing ? Icons.pause : Icons.play_arrow, size: 32, color: Colors.white),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.skip_next, size: 36),
          onPressed: () => _player.seekToNext(),
        ),
        StreamBuilder<bool>(
          stream: _player.shuffleModeEnabledStream,
          builder: (context, snap) {
            final on = snap.data ?? false;
            return IconButton(
              icon: Icon(Icons.shuffle, color: on ? AppColors.primary : null),
              onPressed: () => _player.setShuffleModeEnabled(!on),
            );
          },
        ),
      ],
    );
  }
}
