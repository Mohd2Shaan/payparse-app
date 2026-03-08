class InvoiceModel {
  final String invoiceNumber;
  final String customerName;
  final double amount;
  final double? gstAmount;
  final double totalAmount;
  final String paymentMode;
  final String transactionId;
  final DateTime date;
  final String pdfPath;
  final String description;
  final DateTime createdAt;

  const InvoiceModel({
    required this.invoiceNumber,
    required this.customerName,
    required this.amount,
    this.gstAmount,
    required this.totalAmount,
    required this.paymentMode,
    required this.transactionId,
    required this.date,
    required this.pdfPath,
    required this.description,
    required this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'invoiceNumber': invoiceNumber,
      'customerName': customerName,
      'amount': amount,
      'gstAmount': gstAmount,
      'totalAmount': totalAmount,
      'paymentMode': paymentMode,
      'transactionId': transactionId,
      'date': date.toIso8601String(),
      'pdfPath': pdfPath,
      'description': description,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory InvoiceModel.fromMap(Map<String, dynamic> map) {
    return InvoiceModel(
      invoiceNumber: map['invoiceNumber'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      gstAmount: (map['gstAmount'] as num?)?.toDouble(),
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0,
      paymentMode: map['paymentMode'] as String? ?? 'N/A',
      transactionId: map['transactionId'] as String? ?? 'N/A',
      date: DateTime.parse(map['date'] as String),
      pdfPath: map['pdfPath'] as String? ?? '',
      description: map['description'] as String? ?? '',
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
}
