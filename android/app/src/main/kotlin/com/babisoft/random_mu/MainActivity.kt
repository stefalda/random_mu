package com.babisoft.random_mu

import com.ryanheise.audioservice.AudioServiceActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Extends audio_service's activity so the media session keeps working, and adds
 * the download foreground service bridge.
 */
class MainActivity : AudioServiceActivity() {

    companion object {
        private const val CHANNEL = "com.babisoft.randommu/downloads"
    }

    private var channel: MethodChannel? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
        OfflineDownloadService.channel = methodChannel
        channel = methodChannel

        methodChannel.setMethodCallHandler { call: MethodCall, result: MethodChannel.Result ->
            when (call.method) {
                "start" -> {
                    val title = call.argument<String>("title") ?: "Downloading"
                    val text = call.argument<String>("text") ?: ""
                    OfflineDownloadService.start(this, title, text)
                    result.success(true)
                }

                "update" -> {
                    val title = call.argument<String>("title") ?: "Downloading"
                    val text = call.argument<String>("text") ?: ""
                    OfflineDownloadService.update(this, title, text)
                    result.success(true)
                }

                "stop" -> {
                    OfflineDownloadService.stop(this)
                    result.success(true)
                }

                "isRunning" -> result.success(OfflineDownloadService.isRunning())

                else -> result.notImplemented()
            }
        }
    }

    override fun onDestroy() {
        OfflineDownloadService.channel = null
        channel = null
        super.onDestroy()
    }
}
