import 'package:hive_flutter/hive_flutter.dart';
import 'package:payparse/core/constants/app_constants.dart';
import 'package:payparse/features/company_profile/domain/company_model.dart';
import 'package:payparse/features/invoice/domain/invoice_model.dart';

/// Manages all local data persistence using Hive.
class StorageService {
  static late Box _companyBox;
  static late Box _invoiceBox;
  static late Box _settingsBox;

  /// Initialize Hive and open all required boxes.
  static Future<void> initialize() async {
    await Hive.initFlutter();
    _companyBox = await Hive.openBox(AppConstants.companyProfileBox);
    _invoiceBox = await Hive.openBox(AppConstants.invoiceBox);
    _settingsBox = await Hive.openBox(AppConstants.settingsBox);
  }

  // ─── Company Profile ───────────────────────────────────

  static Future<void> saveCompanyProfile(CompanyProfile profile) async {
    await _companyBox.put(AppConstants.companyProfileKey, profile.toMap());
  }

  static CompanyProfile? getCompanyProfile() {
    final data = _companyBox.get(AppConstants.companyProfileKey);
    if (data == null) return null;
    return CompanyProfile.fromMap(Map<String, dynamic>.from(data));
  }

  static bool hasCompanyProfile() {
    return _companyBox.containsKey(AppConstants.companyProfileKey);
  }

  // ─── Invoices ──────────────────────────────────────────

  static Future<void> saveInvoice(InvoiceModel invoice) async {
    final invoices = getAllInvoices();
    invoices.insert(0, invoice); // newest first
    await _invoiceBox.put(
      'all',
      invoices.map((e) => e.toMap()).toList(),
    );
  }

  static List<InvoiceModel> getAllInvoices() {
    final data = _invoiceBox.get('all');
    if (data == null) return [];
    final list = List<dynamic>.from(data);
    return list
        .map((e) => InvoiceModel.fromMap(Map<String, dynamic>.from(e)))
        .toList();
  }

  static Future<void> deleteInvoice(String invoiceNumber) async {
    final invoices = getAllInvoices();
    invoices.removeWhere((i) => i.invoiceNumber == invoiceNumber);
    await _invoiceBox.put(
      'all',
      invoices.map((e) => e.toMap()).toList(),
    );
  }

  // ─── Invoice Counter ──────────────────────────────────

  static int getInvoiceCounter() {
    return _settingsBox.get(AppConstants.invoiceCounterKey, defaultValue: 0);
  }

  static Future<void> incrementInvoiceCounter() async {
    final current = getInvoiceCounter();
    await _settingsBox.put(AppConstants.invoiceCounterKey, current + 1);
  }

  static String generateInvoiceNumber() {
    final counter = getInvoiceCounter() + 1;
    final date = DateTime.now();
    final dateStr =
        '${date.year}${date.month.toString().padLeft(2, '0')}${date.day.toString().padLeft(2, '0')}';
    return '${AppConstants.invoicePrefix}-$dateStr-${counter.toString().padLeft(3, '0')}';
  }
}
