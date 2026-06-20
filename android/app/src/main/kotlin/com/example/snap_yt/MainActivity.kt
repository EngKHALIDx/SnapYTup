package com.gokei.yt_download

import android.app.PictureInPictureParams
import android.content.res.Configuration
import android.os.Build
import android.util.Rational
import io.flutter.embedding.android.FlutterActivity

/**
 * Host activity that opts into Android's Picture-in-Picture mode so users
 * can keep watching a video in a small floating window while using other
 * apps — a Snaptube-style "Floating Player" feature.
 *
 * PiP requires Android 8.0 (API 26) or newer.
 */
class MainActivity : FlutterActivity() {

    override fun onUserLeaveHint() {
        super.onUserLeaveHint()
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val params = PictureInPictureParams.Builder()
                    .setAspectRatio(Rational(16, 9))
                    .build()
                enterPictureInPictureMode(params)
            } catch (_: IllegalStateException) {
                // Another PiP task is already running — ignore.
            }
        }
    }

    override fun onPictureInPictureModeChanged(
        isInPictureInPictureMode: Boolean,
        newConfig: Configuration
    ) {
        super.onPictureInPictureModeChanged(isInPictureInPictureMode, newConfig)
        // Flutter renders its own UI; nothing to do here for the MVP.
    }
}
