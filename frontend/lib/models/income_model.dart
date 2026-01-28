class Income {
  final int id;
  final String source;
  final double amount;
  final String currency;
  final String recurrence;

  Income({
    required this.id,
    required this.source,
    required this.amount,
    required this.currency,
    required this.recurrence,
  });

  factory Income.fromJson(Map<String, dynamic> json) {
    return Income(
      id: json['id'],
      source: json['source'],
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      currency: json['currency'],
      recurrence: json['recurrence'],
    );
  }
}