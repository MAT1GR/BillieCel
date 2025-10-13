import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/pages/add_transaction_page.dart';
import 'package:mi_billetera_digital/pages/login_page.dart';
import 'package:mi_billetera_digital/app_theme.dart';
import 'package:mi_billetera_digital/widgets/loading_shimmer.dart'; // La importación de shimmer SÍ es correcta

// El resto del archivo es idéntico al anterior, solo se quitó la línea incorrecta.

class FinancialSummary {
  final double totalIngresos;
  final double totalEgresos;
  final double saldo;
  final Map<String, double> expenseByCategory;

  FinancialSummary({
    this.totalIngresos = 0.0,
    this.totalEgresos = 0.0,
    this.saldo = 0.0,
    this.expenseByCategory = const {},
  });
}

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  late final Stream<List<Map<String, dynamic>>> _transactionsStream;
  StreamSubscription? _streamSubscription;

  final _summaryNotifier = ValueNotifier<FinancialSummary>(FinancialSummary());
  final _transactionsNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);

  final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$ ');

  @override
  void initState() {
    super.initState();
    _transactionsStream = supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);

    _streamSubscription = _transactionsStream.listen((transactions) {
      _transactionsNotifier.value = transactions;
      _calculateSummary(transactions);
    });
  }

  @override
  void dispose() {
    _streamSubscription?.cancel();
    _summaryNotifier.dispose();
    _transactionsNotifier.dispose();
    super.dispose();
  }

  void _calculateSummary(List<Map<String, dynamic>> transactions) {
    final totalIngresos = transactions
        .where((t) => t['type'] == 'ingreso')
        .fold<double>(0, (sum, t) => sum + (t['amount'] ?? 0));
    final totalEgresos = transactions
        .where((t) => t['type'] == 'egreso')
        .fold<double>(0, (sum, t) => sum + (t['amount'] ?? 0));
    final saldo = totalIngresos - totalEgresos;

    final Map<String, double> expenseByCategory = {};
    transactions.where((t) => t['type'] == 'egreso').forEach((t) {
      final category = t['category'] as String;
      final amount = t['amount'] as double;
      expenseByCategory[category] = (expenseByCategory[category] ?? 0) + amount;
    });

    _summaryNotifier.value = FinancialSummary(
      totalIngresos: totalIngresos,
      totalEgresos: totalEgresos,
      saldo: saldo,
      expenseByCategory: expenseByCategory,
    );
  }

  Future<void> _showOptions(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.primaryColor),
              title: const Text('Editar'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        AddTransactionPage(transaction: transaction),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text(
                'Eliminar',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _deleteTransaction(context, transaction);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTransaction(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta transacción?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await supabase.from('transactions').delete().match({
          'id': transaction['id'],
        });
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Error al eliminar la transacción'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumen Financiero'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await supabase.auth.signOut();
              if (mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: ValueListenableBuilder<FinancialSummary>(
              valueListenable: _summaryNotifier,
              builder: (context, summary, _) {
                return FinancialSummaryCard(
                  totalIngresos: currencyFormat.format(summary.totalIngresos),
                  totalEgresos: currencyFormat.format(summary.totalEgresos),
                  saldo: currencyFormat.format(summary.saldo),
                  expenseData: summary.expenseByCategory,
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16).copyWith(top: 24, bottom: 8),
            child: Text(
              'Transacciones Recientes',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: _transactionsNotifier,
              builder: (context, transactions, _) {
                if (transactions.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48.0),
                      child: Text(
                        'Aún no tienes transacciones.',
                        style: TextStyle(
                          color: AppTheme.subtextColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return TransactionListItem(
                      transaction: transaction,
                      onLongPress: () => _showOptions(context, transaction),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => const AddTransactionPage()),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class FinancialSummaryCard extends StatelessWidget {
  final String totalIngresos;
  final String totalEgresos;
  final String saldo;
  final Map<String, double> expenseData;

  const FinancialSummaryCard({
    super.key,
    required this.totalIngresos,
    required this.totalEgresos,
    required this.saldo,
    required this.expenseData,
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
        final section = PieChartSectionData(
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
        );
        pieChartSections.add(section);
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saldo Actual',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.subtextColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      saldo,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                    ),
                  ],
                ),
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
            const Divider(height: 40),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildIncomeExpenseColumn(
                  'Ingresos',
                  totalIngresos,
                  AppTheme.accentColor,
                ),
                _buildIncomeExpenseColumn(
                  'Egresos',
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

class TransactionListItem extends StatelessWidget {
  final Map<String, dynamic> transaction;
  final VoidCallback onLongPress;
  final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$ ');

  TransactionListItem({
    super.key,
    required this.transaction,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction['type'] == 'ingreso';
    final color = isIncome ? AppTheme.accentColor : Colors.redAccent;
    final icon = isIncome ? Icons.arrow_upward : Icons.arrow_downward;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      transaction['description'],
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      transaction['category'],
                      style: const TextStyle(
                        color: AppTheme.subtextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                currencyFormat.format(transaction['amount']),
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
