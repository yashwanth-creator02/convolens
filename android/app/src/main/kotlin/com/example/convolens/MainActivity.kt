package com.example.convolens

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import android.Manifest
import android.content.pm.PackageManager
import android.content.Intent
import android.net.Uri
import androidx.core.content.ContextCompat

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.convolens/calllog"
    private val DEVICE_CHANNEL = "com.example.convolens/device"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "getCallLogs") {
                val sinceTimestamp = call.argument<Long>("sinceTimestamp")
                val reader = CallLogReader(this)
                val calls = reader.readCallLogs(sinceTimestamp)
                result.success(calls)
            } else {
                result.notImplemented()
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            DEVICE_CHANNEL
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "getTimezone" -> {
                    result.success(java.util.TimeZone.getDefault().id)
                }

                "placeCall" -> {
                    val number = call.argument<String>("number")
                    if (number == null) {
                        result.error("INVALID_ARGUMENT", "No phone number provided", null)
                        return@setMethodCallHandler
                    }

                    val hasPermission = ContextCompat.checkSelfPermission(
                        this, Manifest.permission.CALL_PHONE
                    ) == PackageManager.PERMISSION_GRANTED

                    if (!hasPermission) {
                        result.error("PERMISSION_DENIED", "CALL_PHONE not granted", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val intent = Intent(Intent.ACTION_CALL, Uri.parse("tel:$number"))
                        startActivity(intent)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("CALL_FAILED", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}