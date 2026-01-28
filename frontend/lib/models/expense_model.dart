class Expense {
  final int id;
  final String description;
  final String category;
  final double amount;
  final String currency;
  final DateTime transactionDate;
  final String paymentMethod;

  Expense({
    required this.id,
    required this.description,
    required this.category,
    required this.amount,
    required this.currency,
    required this.transactionDate,
    required this.paymentMethod,
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: json['id'],
      description: json['description'],
      category: json['category'],
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      currency: json['currency'],
      transactionDate: DateTime.parse(json['transaction_date']),
      paymentMethod: json['payment_method'],
    );
  }
}