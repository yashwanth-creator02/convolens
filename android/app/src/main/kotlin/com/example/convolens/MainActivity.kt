package com.example.convolens

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
class MainActivity : FlutterActivity(){
    private val CHANNEL ="com.example.convolens/calllog"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            if (call.method=="getCallLogs"){
                val reader= CallLogReader(this)
                val calls=reader.readCallLogs()
                result.success(calls)
            } else{
                result.notImplemented()
            }
        }
    }
}
