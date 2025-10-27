import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/app_theme.dart';

class FinancialSummaryCard extends StatelessWidget {
  final String saldo, cashBalance, virtualBalance;
  final String totalIngresos, totalEgresos;
  final Map<String, double> expenseData; // Made optional
  final bool showMonthlySummary;

  const FinancialSummaryCard({
    super.key,
    this.totalIngresos = '',
    this.totalEgresos = '',
    required this.saldo,
    required this.cashBalance,
    required this.virtualBalance,
    this.expenseData = const {},
    this.showMonthlySummary = true,
  });

  Color _getColorForCategory(String category) {
    int hash = category.hashCode;
    double hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Saldo Total',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppTheme.subtextColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        saldo,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).primaryColor,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildBalanceDetail(
                            context,
                            Icons.money,
                            'Efectivo',
                            cashBalance,
                          ),
                          const SizedBox(height: 8),
                          _buildBalanceDetail(
                            context,
                            Icons.credit_card,
                            'Virtual',
                            virtualBalance,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (showMonthlySummary) ...[
              const Divider(height: 40),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildIncomeExpenseColumn(
                    'Ingresos (Mes)',
                    totalIngresos,
                    AppTheme.accentColor,
                  ),
                  _buildIncomeExpenseColumn(
                    'Egresos (Mes)',
                    totalEgresos,
                    Colors.redAccent,
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBalanceDetail(
    BuildContext context,
    IconData icon,
    String label,
    String amount,
  ) {
    return Row(
      children: [
        Icon(icon, color: AppTheme.subtextColor, size: 14),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 12, color: AppTheme.subtextColor),
        ),
        Text(
          amount,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.subtextColor,
          ),
        ),
      ],
    );
  }

  Widget _buildIncomeExpenseColumn(String title, String amount, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 16, color: AppTheme.subtextColor),
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
