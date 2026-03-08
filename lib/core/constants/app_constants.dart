class AppConstants {
  // App info
  static const String appName = 'PayParse';
  static const String appVersion = '1.0.0';

  // SMS
  static const int maxSmsToLoad = 200;

  // Hive box names
  static const String companyProfileBox = 'company_profile';
  static const String invoiceBox = 'invoices';
  static const String settingsBox = 'settings';

  // Hive keys
  static const String companyProfileKey = 'profile';
  static const String invoiceCounterKey = 'invoice_counter';

  // Invoice
  static const String invoicePrefix = 'INV';
  static const double defaultGstRate = 18.0;

  // Method channel
  static const String smsChannel = 'com.payparse/sms';

  // Currency
  static const String currencySymbol = '₹';
}
