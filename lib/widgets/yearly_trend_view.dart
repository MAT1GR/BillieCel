import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class YearlyTrendView extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;

  const YearlyTrendView({super.key, required this.transactions});

  @override
  State<YearlyTrendView> createState() => _YearlyTrendViewState();
}

class _YearlyTrendViewState extends State<YearlyTrendView> {
  // Data structure: { '2025-01': 500.0, '2025-02': -150.0, ... }
  Map<String, double> _netSavingsPerMonth = {};

  @override
  void initState() {
    super.initState();
    _processTransactions();
  }

  @override
  void didUpdateWidget(YearlyTrendView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transactions != oldWidget.transactions) {
      _processTransactions();
    }
  }

  void _processTransactions() {
    final now = DateTime.now();
    Map<String, double> data = {};

    // Initialize the months of the current year
    for (int i = 1; i <= 12; i++) {
      final month = DateTime(now.year, i, 1);
      final monthKey = DateFormat('yyyy-MM').format(month);
      data[monthKey] = 0;
    }

    final transactionsForCurrentYear = widget.transactions.where((t) {
      final date = DateTime.parse(t['date']);
      return date.year == now.year;
    });

    for (var t in transactionsForCurrentYear) {
      final date = DateTime.parse(t['date']);
      final monthKey = DateFormat('yyyy-MM').format(date);
      final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;

      if (t['type'] == 'income') {
        data[monthKey] = (data[monthKey] ?? 0) + amount;
      } else {
        data[monthKey] = (data[monthKey] ?? 0) - amount;
      }
    }

    setState(() {
      _netSavingsPerMonth = data;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_netSavingsPerMonth.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final sortedMonths = _netSavingsPerMonth.keys.toList()..sort();
    final spots = sortedMonths.asMap().entries.map((entry) {
      final index = entry.key.toDouble();
      final monthKey = entry.value;
      final netSaving = _netSavingsPerMonth[monthKey]!;
      return FlSpot(index, netSaving);
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: LineChart(
        LineChartData(
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: Colors.blue,
              barWidth: 4,
              belowBarData: BarAreaData(
                show: true,
                color: Colors.blue.withOpacity(0.3),
              ),
            ),
          ],
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final monthKey = sortedMonths[value.toInt()];
                  return Text(DateFormat.MMM('es_AR').format(DateTime.parse('${monthKey}-01')));
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
