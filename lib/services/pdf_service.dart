import 'dart:io';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:path_provider/path_provider.dart';
import 'package:payparse/core/constants/app_constants.dart';
import 'package:payparse/core/utils/date_utils.dart';
import 'package:payparse/features/company_profile/domain/company_model.dart';
import 'package:payparse/features/invoice/domain/invoice_model.dart';

/// Generates professional invoice PDFs.
class PdfService {
  /// Currency label safe for default PDF fonts (₹ is not supported).
  static const _rs = 'Rs.';

  /// Generates a PDF invoice and returns the saved File.
  static Future<File> generateInvoice({
    required InvoiceModel invoice,
    required CompanyProfile company,
  }) async {
    final pdf = pw.Document();

    // Load logo if available
    pw.ImageProvider? logoImage;
    if (company.hasLogo) {
      final logoFile = File(company.logoPath!);
      if (await logoFile.exists()) {
        final logoBytes = await logoFile.readAsBytes();
        logoImage = pw.MemoryImage(logoBytes);
      }
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(40),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // ─── Header ───────────────────────────────
              _buildHeader(company, logoImage),
              pw.SizedBox(height: 8),
              pw.Divider(thickness: 2, color: PdfColors.grey800),
              pw.SizedBox(height: 20),

              // ─── Invoice Title ────────────────────────
              pw.Center(
                child: pw.Text(
                  'INVOICE',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.grey900,
                  ),
                ),
              ),
              pw.SizedBox(height: 20),

              // ─── Invoice Details ──────────────────────
              _buildInvoiceDetails(invoice),
              pw.SizedBox(height: 20),

              // ─── Bill To ──────────────────────────────
              _buildBillTo(invoice),
              pw.SizedBox(height: 20),

              // ─── Line Items Table ─────────────────────
              _buildItemsTable(invoice),
              pw.SizedBox(height: 20),

              // ─── Totals ───────────────────────────────
              _buildTotals(invoice),
              pw.SizedBox(height: 20),

              // ─── Payment Info ─────────────────────────
              _buildPaymentInfo(invoice, company),

              pw.Spacer(),

              // ─── Footer ───────────────────────────────
              _buildFooter(company),
            ],
          );
        },
      ),
    );

    // Save file
    final output = await getApplicationDocumentsDirectory();
    final invoicesDir = Directory('${output.path}/invoices');
    if (!await invoicesDir.exists()) {
      await invoicesDir.create(recursive: true);
    }

    final file = File(
      '${invoicesDir.path}/${invoice.invoiceNumber}.pdf',
    );
    await file.writeAsBytes(await pdf.save());
    return file;
  }

  // ─── Header Section ──────────────────────────────────

  static pw.Widget _buildHeader(
    CompanyProfile company,
    pw.ImageProvider? logo,
  ) {
    return pw.Row(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        if (logo != null) ...[
          pw.Container(
            width: 60,
            height: 60,
            child: pw.Image(logo, fit: pw.BoxFit.contain),
          ),
          pw.SizedBox(width: 16),
        ],
        pw.Expanded(
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                company.companyName,
                style: pw.TextStyle(
                  fontSize: 18,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(company.address,
                  style: const pw.TextStyle(fontSize: 10)),
              pw.SizedBox(height: 2),
              pw.Text('Phone: ${company.phone}',
                  style: const pw.TextStyle(fontSize: 10)),
              if (company.hasGst)
                pw.Text('GST: ${company.gstNumber}',
                    style: const pw.TextStyle(fontSize: 10)),
            ],
          ),
        ),
      ],
    );
  }

  // ─── Invoice Details Section ─────────────────────────

  static pw.Widget _buildInvoiceDetails(InvoiceModel invoice) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _labelValue('Invoice No:', invoice.invoiceNumber),
        pw.SizedBox(height: 4),
        _labelValue(
          'Date:',
          AppDateUtils.formatForInvoice(invoice.date),
        ),
      ],
    );
  }

  // ─── Bill To Section ─────────────────────────────────

  static pw.Widget _buildBillTo(InvoiceModel invoice) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: const pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Bill To:',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 12,
              )),
          pw.SizedBox(height: 4),
          pw.Text(
            invoice.customerName.isNotEmpty
                ? invoice.customerName
                : 'Customer',
            style: const pw.TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }

  // ─── Items Table Section ─────────────────────────────

  static pw.Widget _buildItemsTable(InvoiceModel invoice) {
    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey400),
      columnWidths: {
        0: const pw.FlexColumnWidth(3),
        1: const pw.FlexColumnWidth(1),
      },
      children: [
        // Header row
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey800),
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Description',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 11,
                  )),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text('Amount',
                  textAlign: pw.TextAlign.right,
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    fontSize: 11,
                  )),
            ),
          ],
        ),
        // Item row
        pw.TableRow(
          children: [
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                invoice.description.isNotEmpty
                    ? invoice.description
                    : 'Payment Received',
                style: const pw.TextStyle(fontSize: 11),
              ),
            ),
            pw.Padding(
              padding: const pw.EdgeInsets.all(8),
              child: pw.Text(
                '$_rs ${invoice.amount.toStringAsFixed(2)}',
                textAlign: pw.TextAlign.right,
                style: const pw.TextStyle(fontSize: 11),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Totals Section ──────────────────────────────────

  static pw.Widget _buildTotals(InvoiceModel invoice) {
    return pw.Container(
      alignment: pw.Alignment.centerRight,
      child: pw.Container(
        width: 200,
        child: pw.Column(
          children: [
            _totalRow('Subtotal',
                '$_rs ${invoice.amount.toStringAsFixed(2)}'),
            if (invoice.gstAmount != null && invoice.gstAmount! > 0) ...[
              pw.SizedBox(height: 4),
              _totalRow('GST',
                  '$_rs ${invoice.gstAmount!.toStringAsFixed(2)}'),
            ],
            pw.Divider(thickness: 2),
            pw.SizedBox(height: 4),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('TOTAL',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    )),
                pw.Text(
                  '$_rs ${invoice.totalAmount.toStringAsFixed(2)}',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─── Payment Info Section ────────────────────────────

  static pw.Widget _buildPaymentInfo(
    InvoiceModel invoice,
    CompanyProfile company,
  ) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey300),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text('Payment Details',
              style: pw.TextStyle(
                fontWeight: pw.FontWeight.bold,
                fontSize: 11,
              )),
          pw.SizedBox(height: 6),
          _labelValue('Payment Mode:', invoice.paymentMode),
          pw.SizedBox(height: 2),
          _labelValue('Transaction ID:', invoice.transactionId),
          if (company.upiId != null && company.upiId!.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            _labelValue('UPI ID:', company.upiId!),
          ],
          if (company.bankDetails != null &&
              company.bankDetails!.isNotEmpty) ...[
            pw.SizedBox(height: 2),
            _labelValue('Bank Details:', company.bankDetails!),
          ],
        ],
      ),
    );
  }

  // ─── Footer Section ──────────────────────────────────

  static pw.Widget _buildFooter(CompanyProfile company) {
    return pw.Column(
      children: [
        pw.Divider(color: PdfColors.grey400),
        pw.SizedBox(height: 4),
        pw.Center(
          child: pw.Text(
            'Thank you for your business!',
            style: pw.TextStyle(
              fontSize: 10,
              fontStyle: pw.FontStyle.italic,
              color: PdfColors.grey600,
            ),
          ),
        ),
        pw.SizedBox(height: 2),
        pw.Center(
          child: pw.Text(
            'Generated by ${AppConstants.appName}',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColors.grey500,
            ),
          ),
        ),
      ],
    );
  }

  // ─── Helper Widgets ──────────────────────────────────

  static pw.Widget _labelValue(String label, String value) {
    return pw.RichText(
      text: pw.TextSpan(
        children: [
          pw.TextSpan(
            text: '$label ',
            style: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
          ),
          pw.TextSpan(
            text: value,
            style: const pw.TextStyle(fontSize: 10),
          ),
        ],
      ),
    );
  }

  static pw.Widget _totalRow(String label, String value) {
    return pw.Row(
      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
      children: [
        pw.Text(label, style: const pw.TextStyle(fontSize: 11)),
        pw.Text(value, style: const pw.TextStyle(fontSize: 11)),
      ],
    );
  }
}
