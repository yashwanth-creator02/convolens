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

  static String cleanWhatsAppNumber(String number) {
    var clean = number.replaceAll(RegExp(r'[^0-9+]'), '');
    if (clean.startsWith('+')) {
      clean = clean.substring(1);
    }
    return clean;
  }

  static Future<bool> isWhatsAppInstalled() async {
    final uri = Uri.parse('whatsapp://send');
    return await canLaunchUrl(uri);
  }

  static Future<bool> openWhatsAppChat(String number, {String? text}) async {
    final clean = cleanWhatsAppNumber(number);
    if (clean.isEmpty) return false;

    final hasText = text != null && text.trim().isNotEmpty;
    final textParam = hasText ? '&text=${Uri.encodeComponent(text.trim())}' : '';
    final whatsappUri = Uri.parse('whatsapp://send?phone=$clean$textParam');

    if (await canLaunchUrl(whatsappUri)) {
      return launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    }

    final webTextParam = hasText ? '?text=${Uri.encodeComponent(text.trim())}' : '';
    final webUri = Uri.parse('https://wa.me/$clean$webTextParam');
    if (await canLaunchUrl(webUri)) {
      return launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  static Future<bool> openWhatsAppCall(String number) async {
    if (number.trim().isEmpty) return false;
    // Attempt direct native Android WhatsApp VOIP call
    final placed = await DeviceChannel.placeWhatsAppCall(number);
    if (placed) return true;

    // Fallback to opening WhatsApp chat with the contact
    return openWhatsAppChat(number);
  }

  static Future<bool> messageWithText(String number, String text) async {
    if (number.trim().isEmpty) return false;

    final uri = Uri(
      scheme: 'sms',
      path: number,
      queryParameters: text.trim().isNotEmpty ? {'body': text.trim()} : null,
    );

    if (await canLaunchUrl(uri)) {
      return launchUrl(uri);
    }
    return false;
  }
}
