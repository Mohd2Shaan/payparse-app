import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payparse/core/utils/date_utils.dart';
import 'package:payparse/features/company_profile/presentation/company_setup_screen.dart';
import 'package:payparse/features/invoice/presentation/invoice_history_screen.dart';
import 'package:payparse/features/invoice/presentation/invoice_preview_screen.dart';
import 'package:payparse/features/sms/domain/sms_message_model.dart';
import 'package:payparse/features/sms/domain/transaction_parser.dart';
import 'package:payparse/features/sms/presentation/sms_providers.dart';

class SmsListScreen extends ConsumerStatefulWidget {
  const SmsListScreen({super.key});

  @override
  ConsumerState<SmsListScreen> createState() => _SmsListScreenState();
}

class _SmsListScreenState extends ConsumerState<SmsListScreen> {
  bool _showAllMessages = false;
  bool _hasRequestedPermission = false;

  @override
  Widget build(BuildContext context) {
    final smsList = ref.watch(smsListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('PayParse'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            tooltip: 'Invoice History',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const InvoiceHistoryScreen(),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.business),
            tooltip: 'Company Profile',
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const CompanySetupScreen(isEditing: true),
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // ─── Permission & Load Section ─────────────
          if (!_hasRequestedPermission)
            _buildPermissionCard(context, colorScheme),

          // ─── Filter Toggle ─────────────────────────
          if (_hasRequestedPermission)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _showAllMessages
                          ? 'Showing all messages'
                          : 'Showing transaction messages only',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  FilterChip(
                    label: Text(_showAllMessages ? 'All' : 'Transactions'),
                    selected: !_showAllMessages,
                    onSelected: (selected) {
                      setState(() => _showAllMessages = !selected);
                      ref.read(smsListProvider.notifier).loadMessages(
                            transactionsOnly: selected,
                          );
                    },
                  ),
                ],
              ),
            ),

          // ─── SMS List ──────────────────────────────
          Expanded(
            child: smsList.when(
              data: (messages) {
                if (messages.isEmpty && _hasRequestedPermission) {
                  return _buildEmptyState(context);
                }
                if (messages.isEmpty) {
                  return _buildWelcomeState(context);
                }
                return _buildSmsList(context, messages);
              },
              loading: () => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Loading messages...'),
                  ],
                ),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.error_outline,
                          size: 48, color: Colors.red),
                      const SizedBox(height: 16),
                      Text(
                        'Error loading messages',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(err.toString(),
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 16),
                      FilledButton.tonalIcon(
                        onPressed: _loadMessages,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPermissionCard(BuildContext context, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(Icons.sms_outlined, size: 48, color: colorScheme.primary),
            const SizedBox(height: 12),
            Text(
              'Read SMS Messages',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'PayParse needs to read your SMS messages to find transaction details. '
              'Your messages are processed locally on your device and never uploaded.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _requestPermissionAndLoad,
              icon: const Icon(Icons.mail_outlined),
              label: const Text('Load Messages'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.receipt_long_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text(
              'Welcome to PayParse',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap "Load Messages" above to scan your SMS for transaction details and generate invoices.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.search_off, size: 48, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              _showAllMessages
                  ? 'No SMS messages found'
                  : 'No transaction messages found',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              _showAllMessages
                  ? 'Your inbox appears to be empty.'
                  : 'Try showing all messages using the filter toggle.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmsList(BuildContext context, List<SmsMessageModel> messages) {
    return ListView.builder(
      itemCount: messages.length,
      padding: const EdgeInsets.only(bottom: 16),
      itemBuilder: (context, index) {
        final sms = messages[index];
        final isTransaction = TransactionParser.isTransactionMessage(sms.body);
        final parsed =
            isTransaction ? TransactionParser.parse(sms) : null;

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: isTransaction
                  ? Theme.of(context).colorScheme.primaryContainer
                  : Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(
                isTransaction ? Icons.payment : Icons.sms,
                color: isTransaction
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    sms.sender,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (parsed != null)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '₹${parsed.amount.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
              ],
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Text(
                  sms.body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  AppDateUtils.formatForDisplay(sms.date),
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            isThreeLine: true,
            onTap: isTransaction
                ? () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => InvoicePreviewScreen(sms: sms),
                      ),
                    );
                  }
                : null,
            trailing: isTransaction
                ? Icon(Icons.arrow_forward_ios,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary)
                : null,
          ),
        );
      },
    );
  }

  Future<void> _requestPermissionAndLoad() async {
    final granted =
        await ref.read(smsPermissionProvider.notifier).requestPermission();

    if (granted) {
      setState(() => _hasRequestedPermission = true);
      _loadMessages();
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'SMS permission is required to read messages. '
            'Please enable it in Settings.',
          ),
        ),
      );
    }
  }

  void _loadMessages() {
    ref
        .read(smsListProvider.notifier)
        .loadMessages(transactionsOnly: !_showAllMessages);
  }
}
