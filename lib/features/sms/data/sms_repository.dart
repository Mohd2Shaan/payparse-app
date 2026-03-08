import 'package:payparse/features/sms/domain/sms_message_model.dart';
import 'package:payparse/features/sms/domain/transaction_parser.dart';
import 'package:payparse/services/sms_service.dart';

/// Repository that provides SMS data and filters transaction messages.
class SmsRepository {
  /// Fetches all SMS messages from the device inbox.
  Future<List<SmsMessageModel>> fetchAllMessages({int limit = 200}) async {
    return SmsService.getInboxMessages(limit: limit);
  }

  /// Fetches only SMS messages that are detected as transaction messages.
  Future<List<SmsMessageModel>> fetchTransactionMessages({
    int limit = 200,
  }) async {
    final allMessages = await fetchAllMessages(limit: limit);
    return allMessages
        .where((sms) => TransactionParser.isTransactionMessage(sms.body))
        .toList();
  }
}
