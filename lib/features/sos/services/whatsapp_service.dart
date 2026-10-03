import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

enum WhatsAppResult { opened, failed }

class WhatsAppService {
  static Future<WhatsAppResult> sendEmergencyMessage({
    required String phoneNumber,
    required String message,
  }) async {
    final cleanPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    final waUri = Uri.parse("https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}");

    try {
      if (await canLaunchUrl(waUri)) {
        await launchUrl(waUri, mode: LaunchMode.externalApplication);
        return WhatsAppResult.opened;
      }
    } catch (e) {
      debugPrint('WhatsApp launch exception: $e');
    }

    return WhatsAppResult.failed;
  }
}
