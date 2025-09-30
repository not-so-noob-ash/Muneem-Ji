class Budget {
  final int id;
  final String title;
  final String category;
  final double amount;
  final String recurrence;

  Budget({
    required this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.recurrence,
  });

  factory Budget.fromJson(Map<String, dynamic> json) {
    return Budget(
      id: json['id'],
      title: json['title'],
      category: json['category'],
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
      recurrence: json['recurrence'],
    );
  }
}
