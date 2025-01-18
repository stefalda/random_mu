package com.example.random_mu
import io.flutter.plugin.common.MethodChannel

object FlutterMediaChannel {
    private lateinit var channel: MethodChannel

    fun setChannel(channel: MethodChannel) {
        this.channel = channel
    }

    fun invokeMethod(method: String, arguments: Any?) {
        channel.invokeMethod(method, arguments)
    }
}