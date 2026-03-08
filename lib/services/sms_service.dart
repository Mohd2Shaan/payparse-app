import 'package:flutter/services.dart';
import 'package:payparse/core/constants/app_constants.dart';
import 'package:payparse/features/sms/domain/sms_message_model.dart';

/// Reads SMS from the device inbox using a platform MethodChannel.
/// This is more reliable than third-party SMS packages.
class SmsService {
  static const _channel = MethodChannel(AppConstants.smsChannel);

  /// Fetches the last [limit] SMS messages from the inbox.
  /// Requires READ_SMS permission to be granted first.
  static Future<List<SmsMessageModel>> getInboxMessages({
    int limit = AppConstants.maxSmsToLoad,
  }) async {
    try {
      final List<dynamic> result = await _channel.invokeMethod(
        'getSms',
        {'limit': limit},
      );

      return result
          .map((e) => SmsMessageModel.fromMap(Map<String, dynamic>.from(e)))
          .toList();
    } on PlatformException catch (e) {
      throw Exception('Failed to read SMS: ${e.message}');
    }
  }
}
