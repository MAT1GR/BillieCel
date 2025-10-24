import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class ExpensePieChartCard extends StatelessWidget {
  final Map<String, double> expenseData;

  const ExpensePieChartCard({super.key, required this.expenseData});

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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0), // Add horizontal padding here
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 8.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Distribución de Gastos',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 250, // Increased height for a larger chart
                child: pieChartSections.isEmpty
                    ? const Center(
                        child: Icon(
                          Icons.pie_chart_outline,
                          size: 100,
                          color: Colors.grey,
                        ),
                      )
                    : PieChart(
                        PieChartData(
                          sections: pieChartSections,
                          borderData: FlBorderData(show: false),
                          sectionsSpace: 2,
                          centerSpaceRadius: 60, // Adjusted for larger chart
                        ),
                      ),
              ),
              if (expenseData.isNotEmpty) ...[
                const Divider(height: 30),
                _CategoryLegend(expenseData: expenseData, getColorForCategory: _getColorForCategory),
              ],
            ],
          ),
        ),
      ),
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
