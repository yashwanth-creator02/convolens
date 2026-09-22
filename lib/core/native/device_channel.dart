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

  static Future<bool> placeWhatsAppCall(String number) async {
    try {
      final result = await _channel.invokeMethod('placeWhatsAppCall', {
        'number': number,
      });
      return result == true;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> openWhatsAppChat(String number, {String? text}) async {
    try {
      final result = await _channel.invokeMethod('openWhatsAppChat', {
        'number': number,
        'text': ?text,
      });
      return result == true;
    } on PlatformException {
      return false;
    }
  }

  static Future<bool> isWhatsAppInstalled() async {
    try {
      final result = await _channel.invokeMethod('isWhatsAppInstalled');
      return result == true;
    } on PlatformException {
      return false;
    }
  }
}
