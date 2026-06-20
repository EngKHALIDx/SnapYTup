# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# youtube_explode_dart — pure Dart, no Java/Kotlin to keep
# (no rules needed)

# Chewie / video_player / just_audio — keep their native classes
-keep class com.google.android.exoplayer2.** { *; }
-keep class media.** { *; }

# webview_flutter
-keep class io.flutter.plugins.webviewflutter.** { *; }
