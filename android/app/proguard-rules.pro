# === CRITICAL: ignore ALL missing classes (R8 mode 1) ===
# Flutter's engine references Play Core classes for deferred component
# loading (Play Store feature), but we don't use the Play Store.
# Without this, R8 fails with "Missing class com.google.android.play.core.*"
-dontwarn com.google.android.play.core.**

# === Flutter engine ===
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# === Media plugins (Chewie/video_player/just_audio use ExoPlayer) ===
-keep class com.google.android.exoplayer2.** { *; }
-keep class media.** { *; }

# === webview_flutter ===
-keep class io.flutter.plugins.webviewflutter.** { *; }

# === AndroidX ===
-keep class androidx.** { *; }
-dontwarn javax.annotation.**
-dontwarn org.jetbrains.annotations.**
