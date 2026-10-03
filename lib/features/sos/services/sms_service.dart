import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';

enum SmsResult { sent, permissionDenied, failed, composerFallback }

class SmsService {
  static const MethodChannel _channel = MethodChannel('com.example.saaya/sms');

  static Future<SmsResult> sendEmergencySms({
    required String phoneNumber,
    required String message,
  }) async {
    // 1. Check SEND_SMS runtime permission
    PermissionStatus status = await Permission.sms.status;
    if (!status.isGranted) {
      status = await Permission.sms.request();
    }

    if (status.isGranted) {
      try {
        final result = await _channel.invokeMethod<String>('sendDirectSms', {
          'phoneNumber': phoneNumber,
          'message': message,
        });
        if (result == 'SENT') {
          return SmsResult.sent;
        }
      } catch (e) {
        debugPrint('Direct SMS MethodChannel exception: $e');
      }
    }

    // Fallback: Launch system SMS composer if direct SMS fails or permission is denied
    try {
      final smsUri = Uri.parse('sms:$phoneNumber?body=${Uri.encodeComponent(message)}');
      if (await canLaunchUrl(smsUri)) {
        await launchUrl(smsUri);
        return SmsResult.composerFallback;
      }
    } catch (e) {
      debugPrint('SMS Composer fallback exception: $e');
    }

    return SmsResult.failed;
  }
}
