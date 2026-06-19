import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Simple trimmer screen: lets the user pick start/end offsets on a slider.
///
/// NOTE: actual ffmpeg-based trimming is a heavy native dependency that we
/// chose to omit from the MVP. The screen is wired up so that you can drop in
/// `ffmpeg_kit_flutter` later and call `_trim()` from the button.
class VideoTrimmerScreen extends StatefulWidget {
  const VideoTrimmerScreen({super.key, required this.filePath});

  final String filePath;

  @override
  State<VideoTrimmerScreen> createState() => _VideoTrimmerScreenState();
}

class _VideoTrimmerScreenState extends State<VideoTrimmerScreen> {
  double _start = 0;
  double _end = 1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Trim video')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              height: 200,
              decoration: BoxDecoration(
                color: AppColors.darkSurfaceAlt,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Center(
                child: Icon(Icons.movie, color: Colors.white54, size: 64),
              ),
            ),
            const SizedBox(height: 32),
            const Text('Select range', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            RangeSlider(
              values: RangeValues(_start, _end),
              min: 0,
              max: 1,
              divisions: 100,
              activeColor: AppColors.primary,
              onChanged: (v) => setState(() {
                _start = v.start;
                _end = v.end;
              }),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('${(_start * 100).round()}%'),
                  Text('${(_end * 100).round()}%'),
                ],
              ),
            ),
            const Spacer(),
            FilledButton.icon(
              onPressed: _trim,
              icon: const Icon(Icons.content_cut),
              label: const Text('Trim & save'),
            ),
            const SizedBox(height: 8),
            const Text(
              'Note: trimming requires the optional ffmpeg_kit_flutter package '
              '(commented out in pubspec.yaml). Add it back to enable actual cutting.',
              style: TextStyle(fontSize: 11, color: AppColors.textSecondaryDark),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _trim() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Trimming is disabled in this build — see the note below.'),
      ),
    );
  }
}
