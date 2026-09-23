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

                "placeWhatsAppCall" -> {
                    val number = call.argument<String>("number")
                    if (number == null) {
                        result.error("INVALID_ARGUMENT", "No phone number provided", null)
                        return@setMethodCallHandler
                    }

                    try {
                        val cleanNumber = number.replace(Regex("[^0-9]"), "")
                        val cursor = contentResolver.query(
                            android.provider.ContactsContract.Data.CONTENT_URI,
                            arrayOf(android.provider.ContactsContract.Data._ID),
                            "${android.provider.ContactsContract.Data.MIMETYPE} = ? AND (${android.provider.ContactsContract.Data.DATA1} LIKE ? OR ${android.provider.ContactsContract.Data.DATA1} LIKE ?)",
                            arrayOf("vnd.android.cursor.item/vnd.com.whatsapp.voip.call", "%$cleanNumber%", "%$number%"),
                            null
                        )
                        var launched = false
                        cursor?.use {
                            if (it.moveToFirst()) {
                                val dataId = it.getLong(it.getColumnIndexOrThrow(android.provider.ContactsContract.Data._ID))
                                val intent = Intent(Intent.ACTION_VIEW).apply {
                                    setDataAndType(
                                        Uri.parse("content://com.android.contacts/data/$dataId"),
                                        "vnd.android.cursor.item/vnd.com.whatsapp.voip.call"
                                    )
                                    `package` = "com.whatsapp"
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                launched = true
                            }
                        }
                        result.success(launched)
                    } catch (e: Exception) {
                        result.success(false)
                    }
                }

                "openWhatsAppChat" -> {
                    val number = call.argument<String>("number")
                    val text = call.argument<String>("text")
                    if (number == null) {
                        result.error("INVALID_ARGUMENT", "No phone number provided", null)
                        return@setMethodCallHandler
                    }

                    var cleanNumber = number.replace(Regex("[^0-9]"), "")
                    if (cleanNumber.length == 10) {
                        cleanNumber = "91$cleanNumber"
                    } else if (cleanNumber.length == 11 && cleanNumber.startsWith("0")) {
                        cleanNumber = "91" + cleanNumber.substring(1)
                    }

                    val textQuery = if (!text.isNullOrEmpty()) "&text=" + Uri.encode(text) else ""
                    val whatsappUri = Uri.parse("whatsapp://send?phone=$cleanNumber$textQuery")
                    val apiUri = Uri.parse("https://api.whatsapp.com/send?phone=$cleanNumber$textQuery")

                    var success = false

                    // 1. Try whatsapp:// with com.whatsapp
                    try {
                        val intent = Intent(Intent.ACTION_VIEW, whatsappUri).apply {
                            setPackage("com.whatsapp")
                            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        }
                        startActivity(intent)
                        success = true
                    } catch (e: Exception) {
                        // 2. Try whatsapp:// with com.whatsapp.w4b (WhatsApp Business)
                        try {
                            val intent = Intent(Intent.ACTION_VIEW, whatsappUri).apply {
                                setPackage("com.whatsapp.w4b")
                                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            }
                            startActivity(intent)
                            success = true
                        } catch (e2: Exception) {
                            // 3. Try whatsapp:// without package constraint
                            try {
                                val intent = Intent(Intent.ACTION_VIEW, whatsappUri).apply {
                                    addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                }
                                startActivity(intent)
                                success = true
                            } catch (e3: Exception) {
                                // 4. Fallback to api.whatsapp.com
                                try {
                                    val intent = Intent(Intent.ACTION_VIEW, apiUri).apply {
                                        addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                                    }
                                    startActivity(intent)
                                    success = true
                                } catch (e4: Exception) {
                                    success = false
                                }
                            }
                        }
                    }
                    result.success(success)
                }

                "isWhatsAppInstalled" -> {
                    val pm = packageManager
                    val installed = try {
                        pm.getPackageInfo("com.whatsapp", 0)
                        true
                    } catch (e: Exception) {
                        try {
                            pm.getPackageInfo("com.whatsapp.w4b", 0)
                            true
                        } catch (e2: Exception) {
                            false
                        }
                    }
                    result.success(installed)
                }

                "openEmailChooser" -> {
                    val to = call.argument<String>("to") ?: ""
                    val subject = call.argument<String>("subject") ?: ""
                    val body = call.argument<String>("body") ?: ""
                    val chooserTitle = call.argument<String>("chooserTitle") ?: "Send Email"

                    try {
                        val intent = Intent(Intent.ACTION_SENDTO).apply {
                            data = Uri.parse("mailto:$to")
                            if (subject.isNotEmpty()) putExtra(Intent.EXTRA_SUBJECT, subject)
                            if (body.isNotEmpty()) putExtra(Intent.EXTRA_TEXT, body)
                        }
                        val chooser = Intent.createChooser(intent, chooserTitle)
                        startActivity(chooser)
                        result.success(true)
                    } catch (e: Exception) {
                        result.error("EMAIL_CHOOSER_FAILED", e.message, null)
                    }
                }

                else -> result.notImplemented()
            }
        }
    }
}