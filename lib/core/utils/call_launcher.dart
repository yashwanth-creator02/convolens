import 'package:url_launcher/url_launcher.dart';

class CallLauncher {
  static Future<bool> call(String number) async {
    if (number.trim().isEmpty) return false;

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
