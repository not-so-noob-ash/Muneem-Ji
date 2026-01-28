class GroupBalance {
  final int lenderId;
  final String lenderName;
  final int borrowerId;
  final String borrowerName;
  final double amount;

  GroupBalance({
    required this.lenderId,
    required this.lenderName,
    required this.borrowerId,
    required this.borrowerName,
    required this.amount,
  });

  factory GroupBalance.fromJson(Map<String, dynamic> json) {
    return GroupBalance(
      lenderId: json['lender']['id'],
      lenderName: json['lender']['full_name'] ?? json['lender']['email'],
      borrowerId: json['borrower']['id'],
      borrowerName: json['borrower']['full_name'] ?? json['borrower']['email'],
      amount: double.tryParse(json['amount'].toString()) ?? 0.0,
    );
  }
}

class GroupExpense {
  final int id;
  final String description;
  final double totalAmount;
  final String creatorName;
  final DateTime date;

  GroupExpense({
    required this.id,
    required this.description,
    required this.totalAmount,
    required this.creatorName,
    required this.date,
  });

  factory GroupExpense.fromJson(Map<String, dynamic> json) {
    return GroupExpense(
      id: json['id'],
      description: json['description'],
      totalAmount: double.tryParse(json['total_amount'].toString()) ?? 0.0,
      creatorName: json['creator']['full_name'] ?? json['creator']['email'],
      date: DateTime.parse(json['created_at']),
    );
  }
}