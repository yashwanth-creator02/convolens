import 'package:flutter/services.dart';

class DeviceChannel {
  static const MethodChannel _channel = MethodChannel(
    'com.example.convolens/device',
  );

  static Future<String> getTimezone() async {
    final result = await _channel.invokeMethod('getTimezone');
    return result as String;
  }

  static Future<bool> placeCall(String number) async {
    try {
      final result = await _channel.invokeMethod('placeCall', {
        'number': number,
      });
      return result == true;
    } on PlatformException {
      return false;
    }
  }
}
