import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class CategoryAnalysisView extends StatefulWidget {
  final List<Map<String, dynamic>> transactions;

  const CategoryAnalysisView({super.key, required this.transactions});

  @override
  State<CategoryAnalysisView> createState() => _CategoryAnalysisViewState();
}

class _CategoryAnalysisViewState extends State<CategoryAnalysisView> {
  Map<String, Map<String, double>> _categoryData = {};

  @override
  void initState() {
    super.initState();
    _processTransactions();
  }

  @override
  void didUpdateWidget(CategoryAnalysisView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.transactions != oldWidget.transactions) {
      _processTransactions();
    }
  }

  void _processTransactions() {
    final now = DateTime.now();
    Map<String, Map<String, double>> data = {};

    final recentExpenses = widget.transactions.where((t) {
      final date = DateTime.parse(t['date']);
      return t['type'] == 'expense' && date.isAfter(DateTime(now.year, now.month - 5, 1));
    });

    for (var t in recentExpenses) {
      final category = t['category'] as String;
      final date = DateTime.parse(t['date']);
      final monthKey = DateFormat('yyyy-MM').format(date);
      final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;

      data.putIfAbsent(category, () => {});
      data[category]![monthKey] = (data[category]![monthKey] ?? 0) + amount;
    }

    setState(() {
      _categoryData = data;
    });
  }

  Widget _buildChartForCategory(Map<String, double> monthlyData) {
    final now = DateTime.now();
    final months = List.generate(6, (index) {
      return DateTime(now.year, now.month - index, 1);
    }).reversed.toList();

    final barGroups = months.asMap().entries.map((entry) {
      final index = entry.key;
      final month = entry.value;
      final monthKey = DateFormat('yyyy-MM').format(month);
      final amount = monthlyData[monthKey] ?? 0.0;

      return BarChartGroupData(
        x: index,
        barRods: [
          BarChartRodData(toY: amount, color: Colors.blue, width: 14, borderRadius: BorderRadius.circular(4)),
        ],
      );
    }).toList();

    return SizedBox(
      height: 150,
      child: BarChart(
        BarChartData(
          barGroups: barGroups,
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final month = months[value.toInt()];
                  return Text(DateFormat.MMM('es_AR').format(month));
                },
                reservedSize: 30,
              ),
            ),
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(show: false),
          borderData: FlBorderData(show: false),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_categoryData.isEmpty) {
      return const Center(child: Text('No hay datos de gastos para analizar.'));
    }

    final categories = _categoryData.keys.toList();

    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final monthlyData = _categoryData[category]!;
        return Card(
          margin: const EdgeInsets.only(bottom: 16),
          clipBehavior: Clip.antiAlias,
          child: ExpansionTile(
            title: Text(category, style: Theme.of(context).textTheme.titleLarge),
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0).copyWith(top: 0),
                child: _buildChartForCategory(monthlyData),
              ),
            ],
          ),
        );
      },
    );
  }
}