import 'package:flutter/services.dart';

class CallLogChannel {
  static const MethodChannel _channel = MethodChannel(
    'com.example.convolens/calllog',
  );

  static Future<List<Map<String, dynamic>>> fetchCallLogs({
    int? sinceTimestamp,
  }) async {
    final result = await _channel.invokeMethod('getCallLogs', {
      'sinceTimestamp': sinceTimestamp,
    });

    final List<dynamic> rawList = result;
    return rawList.map((entry) => Map<String, dynamic>.from(entry)).toList();
  }
}
