package com.ethio.scamshield.scam_shield

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "sms_channel"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        val methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)

        SmsReceiver.smsCallback = { sender, body ->
            runOnUiThread {
                methodChannel.invokeMethod("onSmsReceived", mapOf(
                    "sender" to sender,
                    "body" to body
                ))
            }
        }
    }
}
