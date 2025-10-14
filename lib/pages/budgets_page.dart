import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:async';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/app_theme.dart';
import 'package:mi_billetera_digital/widgets/loading_shimmer.dart';
import 'package:mi_billetera_digital/pages/add_budget_page.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$ ');

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final dataFuture = Future.wait([
      supabase
          .from('budgets')
          .select()
          .eq('month', now.month)
          .eq('year', now.year),
      supabase
          .from('transactions')
          .select('category, amount')
          .eq('type', 'expense')
          .gte('date', DateTime(now.year, now.month, 1).toIso8601String())
          .lte('date', DateTime(now.year, now.month + 1, 0).toIso8601String()),
    ]);

    return Scaffold(
      appBar: AppBar(title: const Text('Presupuestos del Mes')),
      body: FutureBuilder<List<dynamic>>(
        future: dataFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingShimmer();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final budgets = (snapshot.data![0] as List)
              .cast<Map<String, dynamic>>();
          final transactions = (snapshot.data![1] as List)
              .cast<Map<String, dynamic>>();

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {}); // Vuelve a ejecutar el FutureBuilder
            },
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                if (budgets.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 48.0),
                      child: Text(
                        'No has creado presupuestos para este mes.\nUsa el botón + para empezar.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppTheme.subtextColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  )
                else
                  ...budgets.map((budget) {
                    final spentAmount = transactions
                        .where((t) => t['category'] == budget['category'])
                        .fold<double>(
                          0,
                          (sum, t) =>
                              sum + ((t['amount'] as num?)?.toDouble() ?? 0.0),
                        );

                    return BudgetListItem(
                      budget: budget,
                      spentAmount: spentAmount,
                      currencyFormat: currencyFormat,
                    );
                  }).toList(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddBudgetPage()),
          );
          setState(() {}); // Recarga la página al volver del formulario
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class BudgetListItem extends StatelessWidget {
  final Map<String, dynamic> budget;
  final double spentAmount;
  final NumberFormat currencyFormat;

  const BudgetListItem({
    super.key,
    required this.budget,
    required this.spentAmount,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final budgetAmount = (budget['amount'] as num).toDouble();
    final progress = (budgetAmount > 0)
        ? (spentAmount / budgetAmount).clamp(0.0, 1.0)
        : 0.0;
    final remainingAmount = budgetAmount - spentAmount;
    final progressColor = progress > 0.85
        ? Colors.redAccent
        : (progress > 0.6 ? Colors.orangeAccent : AppTheme.primaryColor);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              budget['category'],
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gastado: ${currencyFormat.format(spentAmount)}',
                  style: const TextStyle(color: AppTheme.subtextColor),
                ),
                Text(
                  'Límite: ${currencyFormat.format(budgetAmount)}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(5),
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            ),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: Text(
                remainingAmount >= 0
                    ? 'Quedan: ${currencyFormat.format(remainingAmount)}'
                    : 'Excedido: ${currencyFormat.format(remainingAmount * -1)}',
                style: TextStyle(
                  color: remainingAmount < 0
                      ? Colors.red
                      : AppTheme.accentColor.withGreen(180),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
