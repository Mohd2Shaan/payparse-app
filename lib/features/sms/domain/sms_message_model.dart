class SmsMessageModel {
  final int? id;
  final String sender;
  final String body;
  final DateTime date;

  const SmsMessageModel({
    this.id,
    required this.sender,
    required this.body,
    required this.date,
  });

  factory SmsMessageModel.fromMap(Map<String, dynamic> map) {
    return SmsMessageModel(
      id: map['id'] as int?,
      sender: map['address'] as String? ?? 'Unknown',
      body: map['body'] as String? ?? '',
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'address': sender,
      'body': body,
      'date': date.millisecondsSinceEpoch,
    };
  }

  @override
  String toString() => 'SmsMessageModel(sender: $sender, date: $date)';
}
