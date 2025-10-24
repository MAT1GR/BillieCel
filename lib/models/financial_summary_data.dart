class FinancialSummaryData {
  final double totalIngresos;
  final double totalEgresos;
  final double saldo;
  final Map<String, double> expenseByCategory;
  final double totalBalance;
  final double cashBalance;
  final double virtualBalance;

  FinancialSummaryData({
    this.totalIngresos = 0.0,
    this.totalEgresos = 0.0,
    this.saldo = 0.0,
    this.expenseByCategory = const {},
    this.totalBalance = 0.0,
    this.cashBalance = 0.0,
    this.virtualBalance = 0.0,
  });
}
