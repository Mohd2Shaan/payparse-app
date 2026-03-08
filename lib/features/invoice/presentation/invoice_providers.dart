import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:payparse/features/invoice/data/invoice_repository.dart';
import 'package:payparse/features/invoice/domain/invoice_model.dart';

final invoiceRepositoryProvider = Provider((ref) => InvoiceRepository());

/// Provides list of all saved invoices.
final invoiceListProvider =
    StateNotifierProvider<InvoiceListNotifier, List<InvoiceModel>>(
  (ref) => InvoiceListNotifier(ref),
);

class InvoiceListNotifier extends StateNotifier<List<InvoiceModel>> {
  final Ref _ref;

  InvoiceListNotifier(this._ref) : super([]) {
    loadInvoices();
  }

  void loadInvoices() {
    final repo = _ref.read(invoiceRepositoryProvider);
    state = repo.getAllInvoices();
  }

  Future<void> addInvoice(InvoiceModel invoice) async {
    final repo = _ref.read(invoiceRepositoryProvider);
    await repo.saveInvoice(invoice);
    loadInvoices();
  }

  Future<void> deleteInvoice(String invoiceNumber) async {
    final repo = _ref.read(invoiceRepositoryProvider);
    await repo.deleteInvoice(invoiceNumber);
    loadInvoices();
  }

  String generateInvoiceNumber() {
    final repo = _ref.read(invoiceRepositoryProvider);
    return repo.generateInvoiceNumber();
  }
}
