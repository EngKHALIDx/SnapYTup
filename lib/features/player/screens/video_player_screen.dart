import 'dart:io';

import 'package:chewie/chewie.dart';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

import '../../../core/theme/app_colors.dart';

/// Full-screen video player based on [video_player] + [Chewie].
class VideoPlayerScreen extends StatefulWidget {
  const VideoPlayerScreen({
    super.key,
    this.filePath,
    this.url,
    this.title,
  });

  final String? filePath;
  final String? url;
  final String? title;

  @override
  State<VideoPlayerScreen> createState() => _VideoPlayerScreenState();
}

class _VideoPlayerScreenState extends State<VideoPlayerScreen> {
  VideoPlayerController? _controller;
  ChewieController? _chewie;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      if (widget.filePath != null) {
        _controller = VideoPlayerController.file(File(widget.filePath!));
      } else if (widget.url != null) {
        _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url!));
      } else {
        setState(() {
          _error = 'No source provided';
          _loading = false;
        });
        return;
      }
      await _controller!.initialize();
      _chewie = ChewieController(
        videoPlayerController: _controller!,
        autoPlay: true,
        looping: false,
        aspectRatio: _controller!.value.aspectRatio,
        allowFullScreen: true,
        allowMuting: true,
        allowPlaybackSpeedChanging: true,
        // Snaptube-style PiP / floating player entry point.
        additionalOptions: (context) => [
          OptionItem(
            onTap: (_) => _togglePip(context),
            iconData: Icons.picture_in_picture_alt,
            title: 'Picture-in-Picture',
          ),
        ],
        materialProgressColors: ChewieProgressColors(
          playedColor: AppColors.primary,
          handleColor: AppColors.primary,
          bufferedColor: AppColors.primary.withValues(alpha: 0.3),
          backgroundColor: AppColors.darkBorder,
        ),
      );
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
    _controller?.dispose();
    super.dispose();
  }

  /// Enter Android Picture-in-Picture mode (Android 8.0+).
  /// On other platforms, this is a no-op.
  void _togglePip(BuildContext context) {
    // The video_player plugin exposes a `setMixWithOthers` API but doesn't
    // directly drive PiP. Android PiP is implemented by the host Activity
    // (see MainActivity.kt). Here we just minimize the app to background,
    // which triggers the system PiP if the activity opted in.
    // For the MVP we show a SnackBar so users on iOS/desktop know it's
    // Android-only.
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Picture-in-Picture is supported on Android 8.0+. '
            'Press the Home button while playing to enter PiP mode.'),
        duration: Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: widget.title == null
          ? null
          : AppBar(
              backgroundColor: Colors.transparent,
              foregroundColor: Colors.white,
              title: Text(widget.title!),
            ),
      body: Center(
        child: _loading
            ? const CircularProgressIndicator()
            : _error != null
                ? _ErrorBox(error: _error!)
                : _chewie == null
                    ? const Text('No video.')
                    : Chewie(controller: _chewie!),
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  const _ErrorBox({required this.error});
  final String error;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Text(
        'Failed to play: $error',
        textAlign: TextAlign.center,
        style: const TextStyle(color: AppColors.error),
      ),
    );
  }
}
