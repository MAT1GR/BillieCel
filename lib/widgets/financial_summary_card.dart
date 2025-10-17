import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:mi_billetera_digital/app_theme.dart';

class FinancialSummaryCard extends StatelessWidget {
  final String totalIngresos, totalEgresos, saldo, cashBalance, virtualBalance;
  final Map<String, double> expenseData;
  final bool showPieChart;

  const FinancialSummaryCard({
    super.key,
    required this.totalIngresos,
    required this.totalEgresos,
    required this.saldo,
    required this.cashBalance,
    required this.virtualBalance,
    required this.expenseData,
    this.showPieChart = true, // Default to true
  });

  Color _getColorForCategory(String category) {
    int hash = category.hashCode;
    double hue = (hash % 360).toDouble();
    return HSLColor.fromAHSL(1.0, hue, 0.6, 0.5).toColor();
  }

  @override
  Widget build(BuildContext context) {
    final List<PieChartSectionData> pieChartSections = [];
    final totalAmount = expenseData.values.fold<double>(0, (a, b) => a + b);

    if (totalAmount > 0) {
      expenseData.forEach((category, amount) {
        pieChartSections.add(
          PieChartSectionData(
            color: _getColorForCategory(category),
            value: amount,
            title: '${(amount / totalAmount * 100).toStringAsFixed(0)}%',
            radius: 45,
            titleStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              shadows: [Shadow(color: Colors.black26, blurRadius: 2)],
            ),
          ),
        );
      });
    }

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
                if (showPieChart)
                  SizedBox(
                    height: 100,
                    width: 100,
                    child: pieChartSections.isEmpty
                        ? const Icon(
                            Icons.pie_chart_outline,
                            size: 60,
                            color: Colors.grey,
                          )
                        : PieChart(
                            PieChartData(
                              sections: pieChartSections,
                              borderData: FlBorderData(show: false),
                              sectionsSpace: 2,
                              centerSpaceRadius: 20,
                            ),
                          ),
                  ),
              ],
            ),
            if (showPieChart && expenseData.isNotEmpty) ...[
              const Divider(height: 30),
              _CategoryLegend(expenseData: expenseData, getColorForCategory: _getColorForCategory),
            ],
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

class _CategoryLegend extends StatelessWidget {
  final Map<String, double> expenseData;
  final Color Function(String) getColorForCategory;

  const _CategoryLegend({required this.expenseData, required this.getColorForCategory});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$ ');
    final sortedExpenses = expenseData.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Wrap(
      spacing: 24.0,
      runSpacing: 8.0,
      alignment: WrapAlignment.center,
      children: sortedExpenses.map((entry) {
        return _LegendItem(
          color: getColorForCategory(entry.key),
          label: entry.key,
          amount: currencyFormat.format(entry.value),
        );
      }).toList(),
    );
  }
}

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final String amount;

  const _LegendItem({required this.color, required this.label, required this.amount});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 13)),
        const SizedBox(width: 6),
        Text(amount, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
