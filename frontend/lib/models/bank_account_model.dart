class BankAccount {
  final int id;
  final String bankName;
  final String accountType;
  final double balance;
  final String currency;

  BankAccount({
    required this.id,
    required this.bankName,
    required this.accountType,
    required this.balance,
    required this.currency,
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id'],
      bankName: json['bank_name'],
      accountType: json['account_type'],
      balance: double.parse(json['balance'].toString()),
      currency: json['currency'],
    );
  }
}
