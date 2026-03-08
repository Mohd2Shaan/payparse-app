import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import 'package:payparse/core/constants/app_constants.dart';
import 'package:payparse/core/utils/date_utils.dart';
import 'package:payparse/features/company_profile/presentation/company_providers.dart';
import 'package:payparse/features/invoice/domain/invoice_model.dart';
import 'package:payparse/features/invoice/presentation/invoice_providers.dart';
import 'package:payparse/features/sms/domain/sms_message_model.dart';
import 'package:payparse/features/sms/domain/transaction_parser.dart';
import 'package:payparse/services/pdf_service.dart';

class InvoicePreviewScreen extends ConsumerStatefulWidget {
  final SmsMessageModel sms;

  const InvoicePreviewScreen({super.key, required this.sms});

  @override
  ConsumerState<InvoicePreviewScreen> createState() =>
      _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends ConsumerState<InvoicePreviewScreen> {
  late TextEditingController _customerNameController;
  late TextEditingController _descriptionController;
  late TextEditingController _amountController;
  bool _enableGst = false;
  bool _isGenerating = false;

  late final parsed = TransactionParser.parse(widget.sms);

  @override
  void initState() {
    super.initState();
    _customerNameController = TextEditingController();
    _descriptionController = TextEditingController(
      text: parsed?.paymentMode != null
          ? '${parsed!.paymentMode} Payment'
          : 'Payment Received',
    );
    _amountController = TextEditingController(
      text: parsed?.amount.toStringAsFixed(2) ?? '0.00',
    );
  }

  @override
  void dispose() {
    _customerNameController.dispose();
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  double get _amount => double.tryParse(_amountController.text) ?? 0;
  double get _gstAmount =>
      _enableGst ? _amount * AppConstants.defaultGstRate / 100 : 0;
  double get _totalAmount => _amount + _gstAmount;

  Future<void> _generateInvoice() async {
    final company = ref.read(companyProfileProvider);
    if (company == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please set up company profile first')),
      );
      return;
    }

    setState(() => _isGenerating = true);

    try {
      final invoiceNumber =
          ref.read(invoiceListProvider.notifier).generateInvoiceNumber();

      final invoice = InvoiceModel(
        invoiceNumber: invoiceNumber,
        customerName: _customerNameController.text.trim(),
        amount: _amount,
        gstAmount: _enableGst ? _gstAmount : null,
        totalAmount: _totalAmount,
        paymentMode: parsed?.paymentMode ?? 'N/A',
        transactionId: parsed?.transactionId ?? 'N/A',
        date: parsed?.date ?? DateTime.now(),
        pdfPath: '', // will be updated after generation
        description: _descriptionController.text.trim(),
        createdAt: DateTime.now(),
      );

      // Generate PDF
      final pdfFile = await PdfService.generateInvoice(
        invoice: invoice,
        company: company,
      );

      // Save invoice with PDF path
      final savedInvoice = InvoiceModel(
        invoiceNumber: invoice.invoiceNumber,
        customerName: invoice.customerName,
        amount: invoice.amount,
        gstAmount: invoice.gstAmount,
        totalAmount: invoice.totalAmount,
        paymentMode: invoice.paymentMode,
        transactionId: invoice.transactionId,
        date: invoice.date,
        pdfPath: pdfFile.path,
        description: invoice.description,
        createdAt: invoice.createdAt,
      );

      await ref.read(invoiceListProvider.notifier).addInvoice(savedInvoice);

      if (!mounted) return;

      // Show success and offer share
      _showSuccessDialog(pdfFile.path);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error generating invoice: $e')),
      );
    } finally {
      if (mounted) setState(() => _isGenerating = false);
    }
  }

  void _showSuccessDialog(String pdfPath) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle, color: Colors.green, size: 48),
        title: const Text('Invoice Generated!'),
        content: const Text(
            'Your invoice has been generated and saved successfully.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pop();
            },
            child: const Text('Done'),
          ),
          FilledButton.icon(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final bytes = await File(pdfPath).readAsBytes();
              await Printing.sharePdf(
                bytes: bytes,
                filename: 'invoice.pdf',
              );
            },
            icon: const Icon(Icons.share),
            label: const Text('Share'),
          ),
        ],
      ),
    );
  }
// Add this inside _InvoicePreviewScreenState

Widget _infoRow(IconData icon, String label, String value) {
  final colorScheme = Theme.of(context).colorScheme;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 18, color: colorScheme.primary),
        const SizedBox(width: 12),
        SizedBox(
          width: 100,
          child: Text(label,
              style: const TextStyle(
                  fontWeight: FontWeight.w500, fontSize: 13)),
        ),
        Expanded(
          child: Text(value, style: const TextStyle(fontSize: 13)),
        ),
      ],
    ),
  );
}
 @override
Widget build(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;

  return Scaffold(
    appBar: AppBar(
      title: const Text('Invoice Preview'),
    ),
    body: SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ─── Original SMS ────────────────────────
          Card(
            color: colorScheme.surfaceContainerHighest,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.sms, size: 16, color: colorScheme.primary),
                      const SizedBox(width: 8),
                      Text('Original SMS',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: colorScheme.primary,
                          )),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    widget.sms.body,
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${widget.sms.sender} • ${AppDateUtils.formatForDisplay(widget.sms.date)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ─── Parsed Details ──────────────────────
          if (parsed != null) ...[
            Text('Extracted Details',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 8),
            _infoRow(Icons.attach_money, 'Amount',
                '${AppConstants.currencySymbol}${parsed!.amount.toStringAsFixed(2)}'),
            if (parsed!.paymentMode != null)
              _infoRow(
                  Icons.payment, 'Payment Mode', parsed!.paymentMode!),
            if (parsed!.transactionId != null)
              _infoRow(Icons.tag, 'Transaction ID',
                  parsed!.transactionId!),
            if (parsed!.bankName != null)
              _infoRow(Icons.account_balance, 'Bank', parsed!.bankName!),
            const SizedBox(height: 24),
          ],

          // ─── Editable Fields ─────────────────────
          Text('Invoice Details',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
          const SizedBox(height: 12),

          TextFormField(
            controller: _customerNameController,
            decoration: const InputDecoration(
              labelText: 'Customer Name',
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _descriptionController,
            decoration: const InputDecoration(
              labelText: 'Description',
              prefixIcon: Icon(Icons.description),
            ),
          ),
          const SizedBox(height: 12),

          TextFormField(
            controller: _amountController,
            decoration: const InputDecoration(
              labelText: 'Amount (₹)',
              prefixIcon: Icon(Icons.currency_rupee),
            ),
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 12),

          // GST toggle
          SwitchListTile(
            title: const Text('Apply GST (18%)'),
            subtitle: _enableGst
                ? Text(
                    'GST: ${AppConstants.currencySymbol}${_gstAmount.toStringAsFixed(2)}')
                : null,
            value: _enableGst,
            onChanged: (v) => setState(() => _enableGst = v),
            contentPadding: EdgeInsets.zero,
          ),
          const SizedBox(height: 16),

          // ─── Total Section ───────────────────────
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('TOTAL',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: colorScheme.onPrimaryContainer,
                    )),
                Text(
                  '${AppConstants.currencySymbol}${_totalAmount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 22,
                    color: colorScheme.onPrimaryContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    ),
    bottomNavigationBar: SafeArea(
      minimum: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: _isGenerating ? null : _generateInvoice,
          icon: _isGenerating
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.picture_as_pdf),
          label: Text(_isGenerating
              ? 'Generating...'
              : 'Generate Invoice PDF'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
    ),
  );
}
}
