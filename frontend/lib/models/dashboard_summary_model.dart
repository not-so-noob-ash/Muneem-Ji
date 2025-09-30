class DashboardSummary {
  final double netWorth;
  final double totalIncome;
  final double totalBudgeted;
  final String currency;

  DashboardSummary({
    required this.netWorth,
    required this.totalIncome,
    required this.totalBudgeted,
    required this.currency,
  });

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSummary(
      netWorth: double.tryParse(json['net_worth'].toString()) ?? 0.0,
      totalIncome: double.tryParse(json['total_income'].toString()) ?? 0.0,
      totalBudgeted: double.tryParse(json['total_budgeted'].toString()) ?? 0.0,
      currency: json['currency'],
    );
  }
}
