package com.example.random_mu


import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : AudioServiceActivity() {
    private val CHANNEL = "com.babisoft.randommu/android_auto"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        FlutterMediaChannel.setChannel(channel)

        channel.setMethodCallHandler { call, result ->
            when (call.method) {
                "updatePlaybackState" -> {
                    // Handle playback state updates
                    result.success(null)
                }
                "updatePlaybackPosition" -> {
                    // Handle position updates
                    result.success(null)
                }
                "updateMediaMetadata" -> {
                    // Handle metadata updates
                    result.success(null)
                }
                else -> result.notImplemented()
            }
        }
    }
}
