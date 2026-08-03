import 'package:flutter/services.dart';

class CallLogChannel {
  static const MethodChannel _channel=
      MethodChannel('com.example.convolens/calllog');
  static Future<List<Map<String,dynamic>>> fetchCallLogs() async{
    final result=await _channel.invokeMethod('getCallLogs');

    final List<dynamic> rawList=result;
    return rawList.map((entry) => Map<String,dynamic>.from(entry)).toList();
  }
}


