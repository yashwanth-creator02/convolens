import 'package:flutter/services.dart';

class DeviceChannel {
  static const MethodChannel _channel = MethodChannel(
    'com.example.convolens/device',
  );

  static Future<String> getTimezone() async {
    final result = await _channel.invokeMethod('getTimezone');
    return result as String;
  }
}
