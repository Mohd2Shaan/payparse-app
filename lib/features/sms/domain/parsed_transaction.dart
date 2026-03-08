class ParsedTransaction {
  final double amount;
  final String? transactionId;
  final String? paymentMode;
  final String? bankName;
  final DateTime date;
  final String rawMessage;
  final String sender;

  const ParsedTransaction({
    required this.amount,
    this.transactionId,
    this.paymentMode,
    this.bankName,
    required this.date,
    required this.rawMessage,
    required this.sender,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'transactionId': transactionId,
      'paymentMode': paymentMode,
      'bankName': bankName,
      'date': date.toIso8601String(),
      'rawMessage': rawMessage,
      'sender': sender,
    };
  }

  factory ParsedTransaction.fromMap(Map<String, dynamic> map) {
    return ParsedTransaction(
      amount: (map['amount'] as num).toDouble(),
      transactionId: map['transactionId'] as String?,
      paymentMode: map['paymentMode'] as String?,
      bankName: map['bankName'] as String?,
      date: DateTime.parse(map['date'] as String),
      rawMessage: map['rawMessage'] as String? ?? '',
      sender: map['sender'] as String? ?? '',
    );
  }

  @override
  String toString() =>
      'ParsedTransaction(amount: $amount, txnId: $transactionId, mode: $paymentMode)';
}
