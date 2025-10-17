import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class MonthlyEvolutionView extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;

  const MonthlyEvolutionView({super.key, required this.transactions});

  @override
  State<MonthlyEvolutionView> createState() => _MonthlyEvolutionViewState();
}

class _MonthlyEvolutionViewState extends State<MonthlyEvolutionView> {
  Map<String, Map<String, double>> _monthlyData = {};

  @override
  void initState() {
    super.initState();
    _processTransactions();
  }

  @override
  void didUpdateWidget(MonthlyEvolutionView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transactions != oldWidget.transactions) {
      _processTransactions();
    }
  }

  void _processTransactions() {
    final now = DateTime.now();
    Map<String, Map<String, double>> data = {};

    // Initialize the last 6 months
    for (int i = 0; i < 6; i++) {
      final month = DateTime(now.year, now.month - i, 1);
      final monthKey = DateFormat('yyyy-MM').format(month);
      data[monthKey] = {'income': 0, 'expense': 0};
    }

    for (var t in widget.transactions) {
      final transactionDate = DateTime.parse(t['date']);
      final monthKey = DateFormat('yyyy-MM').format(transactionDate);

      if (data.containsKey(monthKey)) {
        final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
        if (t['type'] == 'income') {
          data[monthKey]!['income'] = (data[monthKey]!['income'] ?? 0) + amount;
        } else {
          data[monthKey]!['expense'] = (data[monthKey]!['expense'] ?? 0) + amount;
        }
      }
    }

    setState(() {
      _monthlyData = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_monthlyData.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final sortedMonths = _monthlyData.keys.toList()..sort((a, b) => b.compareTo(a));

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          barGroups: sortedMonths.map((month) {
            final index = sortedMonths.indexOf(month);
            final data = _monthlyData[month]!;
            return BarChartGroupData(
              x: index,
              barRods: [
                BarChartRodData(toY: data['income']!, color: Colors.green, width: 16),
                BarChartRodData(toY: data['expense']!, color: Colors.red, width: 16),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final month = sortedMonths[value.toInt()];
                  return Text(DateFormat.MMM('es_AR').format(DateTime.parse('${month}-01')));
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 40)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(show: true),
        ),
      ),
    );
  }
}
