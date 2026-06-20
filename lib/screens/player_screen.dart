import 'dart:io';
import 'package:chewie/chewie.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:just_audio/just_audio.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({
    super.key,
    this.filePath,
    this.url,
    this.title,
    this.isAudio = false,
  });

  final String? filePath;
  final String? url;
  final String? title;
  final bool isAudio;

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  VideoPlayerController? _video;
  ChewieController? _chewie;
  AudioPlayer? _audio;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      if (widget.isAudio) {
        _audio = AudioPlayer();
        if (widget.filePath != null) {
          await _audio!.setFilePath(widget.filePath!);
        } else if (widget.url != null) {
          await _audio!.setUrl(widget.url!);
        }
        _audio!.play();
      } else {
        if (widget.filePath != null) {
          _video = VideoPlayerController.file(File(widget.filePath!));
        } else if (widget.url != null) {
          _video = VideoPlayerController.networkUrl(Uri.parse(widget.url!));
        }
        await _video!.initialize();
        _chewie = ChewieController(
          videoPlayerController: _video!,
          autoPlay: true,
          aspectRatio: _video!.value.aspectRatio,
          allowFullScreen: true,
          allowPlaybackSpeedChanging: true,
        );
      }
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
    _chewie?.dispose();
    _video?.dispose();
    _audio?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        title: Text(widget.title ?? '', maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: Center(
        child: _loading
            ? const CupertinoActivityIndicator(radius: 14, color: Colors.white)
            : _error != null
                ? Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      'تعذر التشغيل:\n$_error',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFFF3B30)),
                    ),
                  )
                : widget.isAudio
                    ? _audioView()
                    : Chewie(controller: _chewie!),
      ),
    );
  }

  Widget _audioView() {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF007AFF), Color(0xFF5856D6)],
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(CupertinoIcons.music_note, size: 96, color: Colors.white),
          ),
          const SizedBox(height: 32),
          Text(
            widget.title ?? '',
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 32),
          StreamBuilder<Duration?>(
            stream: _audio!.durationStream,
            builder: (_, durSnap) {
              final dur = durSnap.data ?? Duration.zero;
              return StreamBuilder<Duration>(
                stream: _audio!.positionStream,
                builder: (_, posSnap) {
                  final pos = posSnap.data ?? Duration.zero;
                  return Column(
                    children: [
                      Slider(
                        value: pos.inMilliseconds.toDouble().clamp(0, dur.inMilliseconds.toDouble().clamp(1, double.infinity)),
                        min: 0,
                        max: dur.inMilliseconds.toDouble().clamp(1, double.infinity),
                        onChanged: (v) => _audio!.seek(Duration(milliseconds: v.toInt())),
                        activeColor: const Color(0xFF007AFF),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(_fmt(pos), style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11)),
                            Text(_fmt(dur), style: const TextStyle(color: Color(0xFF8E8E93), fontSize: 11)),
                          ],
                        ),
                      ),
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(CupertinoIcons.backward_fill, color: Colors.white, size: 36),
                onPressed: () => _audio!.seekToPrevious(),
              ),
              StreamBuilder<PlayerState>(
                stream: _audio!.playerStateStream,
                builder: (_, snap) {
                  final playing = snap.data?.playing ?? false;
                  return GestureDetector(
                    onTap: () => playing ? _audio!.pause() : _audio!.play(),
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: const BoxDecoration(
                        color: Color(0xFF007AFF),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        playing ? CupertinoIcons.pause_fill : CupertinoIcons.play_fill,
                        color: Colors.white,
                        size: 36,
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(CupertinoIcons.forward_fill, color: Colors.white, size: 36),
                onPressed: () => _audio!.seekToNext(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}
