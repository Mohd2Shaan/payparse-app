import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:payparse/core/constants/app_constants.dart';
import 'package:payparse/core/utils/date_utils.dart';
import 'package:payparse/features/invoice/domain/invoice_model.dart';
import 'package:payparse/features/invoice/presentation/invoice_providers.dart';

class InvoiceHistoryScreen extends ConsumerWidget {
  const InvoiceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(invoiceListProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice History'),
      ),
      body: invoices.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.receipt_long_outlined,
                        size: 64,
                        color: colorScheme.primary.withValues(alpha: 0.4)),
                    const SizedBox(height: 16),
                    Text(
                      'No invoices yet',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Generated invoices will appear here.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
              itemCount: invoices.length,
              padding: const EdgeInsets.only(top: 8, bottom: 16),
              itemBuilder: (context, index) {
                final invoice = invoices[index];
                return _InvoiceCard(invoice: invoice);
              },
            ),
    );
  }
}

class _InvoiceCard extends ConsumerWidget {
  final InvoiceModel invoice;

  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final pdfExists =
        invoice.pdfPath.isNotEmpty && File(invoice.pdfPath).existsSync();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    invoice.invoiceNumber,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onPrimaryContainer,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  AppDateUtils.timeAgo(invoice.createdAt),
                  style: TextStyle(
                    fontSize: 11,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Customer & Amount
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        invoice.customerName.isNotEmpty
                            ? invoice.customerName
                            : 'Customer',
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        invoice.description,
                        style: TextStyle(
                          fontSize: 12,
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  '${AppConstants.currencySymbol}${invoice.totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Details row
            Row(
              children: [
                _chip(context, Icons.payment, invoice.paymentMode),
                const SizedBox(width: 8),
                _chip(
                  context,
                  Icons.calendar_today,
                  AppDateUtils.formatForInvoice(invoice.date),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Action buttons
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Share
                if (pdfExists)
                  TextButton.icon(
                    onPressed: () async {
                      final bytes = await File(invoice.pdfPath).readAsBytes();
                      await Printing.sharePdf(
                        bytes: bytes,
                        filename: '${invoice.invoiceNumber}.pdf',
                      );
                    },
                    icon: const Icon(Icons.share, size: 18),
                    label: const Text('Share'),
                  ),

                // View PDF
                if (pdfExists)
                  TextButton.icon(
                    onPressed: () async {
                      final bytes = await File(invoice.pdfPath).readAsBytes();
                      await Printing.layoutPdf(
                        onLayout: (_) => bytes,
                      );
                    },
                    icon: const Icon(Icons.visibility, size: 18),
                    label: const Text('View'),
                  ),

                // Delete
                TextButton.icon(
                  onPressed: () {
                    _confirmDelete(context, ref, invoice);
                  },
                  icon: Icon(Icons.delete_outline,
                      size: 18, color: colorScheme.error),
                  label: Text('Delete',
                      style: TextStyle(color: colorScheme.error)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(BuildContext context, IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    InvoiceModel invoice,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Invoice?'),
        content: Text('Delete ${invoice.invoiceNumber}? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(invoiceListProvider.notifier)
                  .deleteInvoice(invoice.invoiceNumber);

              // Delete PDF file too
              if (invoice.pdfPath.isNotEmpty) {
                final file = File(invoice.pdfPath);
                if (file.existsSync()) file.deleteSync();
              }

              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invoice deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
