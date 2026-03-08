import 'package:payparse/features/sms/domain/parsed_transaction.dart';
import 'package:payparse/features/sms/domain/sms_message_model.dart';

/// Parses SMS messages to extract transaction details.
/// Uses regex patterns and keyword matching for multiple bank formats.
class TransactionParser {
  // ─── Amount Patterns ─────────────────────────────────

  static final List<RegExp> _amountPatterns = [
    // ₹1,234.56 or Rs. 1234 or INR 1,234.56
    RegExp(r'(?:Rs\.?|INR|₹)\s*([\d,]+\.?\d*)', caseSensitive: false),
    // "amount of Rs 1234"
    RegExp(r'amount\s+(?:of\s+)?(?:Rs\.?|INR|₹)\s*([\d,]+\.?\d*)',
        caseSensitive: false),
    // "credited with 1234" or "debited with 1234"
    RegExp(r'(?:credited|debited|received)\s+(?:with\s+)?(?:Rs\.?|INR|₹)?\s*([\d,]+\.?\d*)',
        caseSensitive: false),
  ];

  // ─── Transaction ID Patterns ─────────────────────────

  static final List<RegExp> _txnIdPatterns = [
    RegExp(r'UPI\s*(?:Ref|ref\.?|ID|id)\s*[:\s]*(\d{8,})', caseSensitive: false),
    RegExp(r'(?:Txn|TXN|txn|Transaction)\s*(?:ID|Id|id|No|no)?[:\s]*([A-Za-z0-9]{8,})',
        caseSensitive: false),
    RegExp(r'(?:Ref|REF|ref)\s*(?:No|no|ID|id)?[:\s]*([A-Za-z0-9]{8,})',
        caseSensitive: false),
    RegExp(r'IMPS\s*(?:Ref|ref)?[:\s]*(\d{8,})', caseSensitive: false),
    RegExp(r'NEFT\s*(?:Ref|ref)?[:\s]*([A-Za-z0-9]{8,})', caseSensitive: false),
  ];

  // ─── Date Pattern ────────────────────────────────────

  // ignore: unused_field
  static final RegExp _datePattern = RegExp(
    r'(\d{1,2})[-/](\w{3,9})[-/](\d{2,4})',
    caseSensitive: false,
  );

  // ─── Payment Mode Detection ──────────────────────────

  static final Map<String, String> _paymentModes = {
    'upi': 'UPI',
    'imps': 'IMPS',
    'neft': 'NEFT',
    'rtgs': 'RTGS',
    'card': 'Card',
    'debit card': 'Debit Card',
    'credit card': 'Credit Card',
    'net banking': 'Net Banking',
    'cheque': 'Cheque',
    'cash deposit': 'Cash Deposit',
  };

  // ─── Bank Name Detection ─────────────────────────────

  static final List<String> _bankKeywords = [
    'HDFC', 'SBI', 'ICICI', 'Axis', 'Kotak', 'PNB', 'BOB',
    'Canara', 'Union', 'IndusInd', 'Yes Bank', 'Federal',
    'IDBI', 'BOI', 'Indian', 'UCO', 'Bandhan', 'RBL',
    'Paytm', 'PhonePe', 'GPay', 'Google Pay', 'Amazon Pay',
  ];

  // ─── Transaction Message Detection ───────────────────

  static final List<String> _transactionKeywords = [
    'credited', 'debited', 'received', 'sent', 'transferred',
    'payment', 'transaction', 'withdrawn', 'deposited',
    'upi', 'imps', 'neft', 'rtgs',
  ];

  /// Checks if an SMS is likely a transaction message.
  static bool isTransactionMessage(String body) {
    if (body.isEmpty) return false;
    final lower = body.toLowerCase();

    // Must contain at least one transaction keyword
    final hasKeyword = _transactionKeywords.any((k) => lower.contains(k));
    if (!hasKeyword) return false;

    // Must contain an amount
    return _amountPatterns.any((p) => p.hasMatch(body));
  }

  /// Parses an SMS into a ParsedTransaction.
  /// Returns null if parsing fails (not a valid transaction SMS).
  static ParsedTransaction? parse(SmsMessageModel sms) {
    final body = sms.body;
    if (!isTransactionMessage(body)) return null;

    final amount = _extractAmount(body);
    if (amount == null) return null;

    return ParsedTransaction(
      amount: amount,
      transactionId: _extractTransactionId(body),
      paymentMode: _extractPaymentMode(body),
      bankName: _extractBankName(body, sms.sender),
      date: sms.date,
      rawMessage: body,
      sender: sms.sender,
    );
  }

  // ─── Private Extraction Methods ──────────────────────

  static double? _extractAmount(String body) {
    for (final pattern in _amountPatterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        final raw = match.group(1)?.replaceAll(',', '');
        if (raw != null) {
          final value = double.tryParse(raw);
          if (value != null && value > 0) return value;
        }
      }
    }
    return null;
  }

  static String? _extractTransactionId(String body) {
    for (final pattern in _txnIdPatterns) {
      final match = pattern.firstMatch(body);
      if (match != null) {
        return match.group(1);
      }
    }
    return null;
  }

  static String? _extractPaymentMode(String body) {
    final lower = body.toLowerCase();
    for (final entry in _paymentModes.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return null;
  }

  static String? _extractBankName(String body, String sender) {
    // Check body first
    for (final bank in _bankKeywords) {
      if (body.toUpperCase().contains(bank.toUpperCase())) {
        return bank;
      }
    }
    // Check sender
    for (final bank in _bankKeywords) {
      if (sender.toUpperCase().contains(bank.toUpperCase())) {
        return bank;
      }
    }
    return null;
  }
}
