import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:payparse/features/sms/data/sms_repository.dart';
import 'package:payparse/features/sms/domain/sms_message_model.dart';

final smsRepositoryProvider = Provider((ref) => SmsRepository());

/// Holds the current SMS permission status.
final smsPermissionProvider =
    StateNotifierProvider<SmsPermissionNotifier, PermissionStatus>(
  (ref) => SmsPermissionNotifier(),
);

class SmsPermissionNotifier extends StateNotifier<PermissionStatus> {
  SmsPermissionNotifier() : super(PermissionStatus.denied);

  Future<bool> requestPermission() async {
    state = await Permission.sms.request();
    return state.isGranted;
  }

  Future<void> checkPermission() async {
    state = await Permission.sms.status;
  }
}

/// Holds the loaded SMS messages. Empty until user triggers loading.
final smsListProvider =
    StateNotifierProvider<SmsListNotifier, AsyncValue<List<SmsMessageModel>>>(
  (ref) => SmsListNotifier(ref),
);

class SmsListNotifier extends StateNotifier<AsyncValue<List<SmsMessageModel>>> {
  final Ref _ref;

  SmsListNotifier(this._ref) : super(const AsyncValue.data([]));

  /// Loads transaction SMS messages from the device inbox.
  Future<void> loadMessages({bool transactionsOnly = true}) async {
    state = const AsyncValue.loading();
    try {
      final repo = _ref.read(smsRepositoryProvider);
      final messages = transactionsOnly
          ? await repo.fetchTransactionMessages()
          : await repo.fetchAllMessages();
      state = AsyncValue.data(messages);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
