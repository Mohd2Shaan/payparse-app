import 'package:payparse/features/invoice/domain/invoice_model.dart';
import 'package:payparse/services/storage_service.dart';

/// Repository for managing invoice data in local storage.
class InvoiceRepository {
  /// Saves a new invoice.
  Future<void> saveInvoice(InvoiceModel invoice) async {
    await StorageService.saveInvoice(invoice);
    await StorageService.incrementInvoiceCounter();
  }

  /// Retrieves all saved invoices, newest first.
  List<InvoiceModel> getAllInvoices() {
    return StorageService.getAllInvoices();
  }

  /// Deletes an invoice by its invoice number.
  Future<void> deleteInvoice(String invoiceNumber) async {
    await StorageService.deleteInvoice(invoiceNumber);
  }

  /// Generates the next invoice number.
  String generateInvoiceNumber() {
    return StorageService.generateInvoiceNumber();
  }
}
