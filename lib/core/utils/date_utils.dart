import 'package:intl/intl.dart';

class AppDateUtils {
  static final DateFormat _invoiceDateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _invoiceNumberFormat = DateFormat('yyyyMMdd');
  static final DateFormat _displayFormat = DateFormat('dd/MM/yyyy hh:mm a');

  static String formatForInvoice(DateTime date) {
    return _invoiceDateFormat.format(date);
  }

  static String formatForInvoiceNumber(DateTime date) {
    return _invoiceNumberFormat.format(date);
  }

  static String formatForDisplay(DateTime date) {
    return _displayFormat.format(date);
  }

  static String timeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 365) {
      return '${(difference.inDays / 365).floor()}y ago';
    } else if (difference.inDays > 30) {
      return '${(difference.inDays / 30).floor()}mo ago';
    } else if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
