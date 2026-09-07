import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

import '../native/device_channel.dart';

class CallLauncher {
  static Future<bool> call(String number) async {
    if (number.trim().isEmpty) return false;

    var status = await Permission.phone.status;
    if (!status.isGranted) {
      status = await Permission.phone.request();
    }

    if (status.isGranted) {
      final placed = await DeviceChannel.placeCall(number);
      if (placed) return true;
    }

    final uri = Uri(scheme: 'tel', path: number);
    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    }
    return false;
  }

  static Future<bool> message(String number) async {
    if (number.trim().isEmpty) return false;

    final uri = Uri(scheme: 'sms', path: number);

    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    }
    return false;
  }
}
