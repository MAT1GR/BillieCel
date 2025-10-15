import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:async';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/pages/add_transaction_page.dart';
import 'package:mi_billetera_digital/pages/login_page.dart';
import 'package:mi_billetera_digital/app_theme.dart';
import 'package:mi_billetera_digital/widgets/loading_shimmer.dart';
import 'package:mi_billetera_digital/pages/transaction_detail_page.dart';
import 'package:mi_billetera_digital/widgets/my_app_bar.dart';
import 'package:mi_billetera_digital/pages/profile_page.dart';

class FinancialSummary {
  final double totalIngresos;
  final double totalEgresos;
  final double saldo; // Este es el saldo de transacciones (ingresos - egresos)
  final Map<String, double> expenseByCategory;
  final double totalBalance; // Saldo total de todas las cuentas
  final double cashBalance; // Saldo solo de efectivo
  final double virtualBalance; // Saldo del resto de las cuentas

  FinancialSummary({
    this.totalIngresos = 0.0,
    this.totalEgresos = 0.0,
    this.saldo = 0.0,
    this.expenseByCategory = const {},
    this.totalBalance = 0.0,
    this.cashBalance = 0.0,
    this.virtualBalance = 0.0,
  });
}

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  // Streams para transacciones y cuentas
  late final Stream<List<Map<String, dynamic>>> _transactionsStream;
  late final Stream<List<Map<String, dynamic>>> _accountsStream;
  StreamSubscription? _transactionsSubscription;
  StreamSubscription? _accountsSubscription;

  // Notificadores para actualizar la UI
  final _summaryNotifier = ValueNotifier<FinancialSummary>(FinancialSummary());
  final _transactionsNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);
  final _accountsNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);

  final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$ ');

  @override
  void initState() {
    super.initState();
    // Preparamos los streams
    _transactionsStream = supabase
        .from('transactions')
        .stream(primaryKey: ['id'])
        .order('date', ascending: false);
    _accountsStream = supabase
        .from('accounts')
        .stream(primaryKey: ['id'])
        .order('name');

    // Escuchamos los cambios en las transacciones
    _transactionsSubscription = _transactionsStream.listen((transactions) {
      _transactionsNotifier.value = transactions;
      _recalculateSummary();
    });

    // Escuchamos los cambios en las cuentas
    _accountsSubscription = _accountsStream.listen((accounts) {
      _accountsNotifier.value = accounts;
      _recalculateSummary();
    });
  }

  @override
  void dispose() {
    // Cancelamos las suscripciones para evitar errores
    _transactionsSubscription?.cancel();
    _accountsSubscription?.cancel();
    _summaryNotifier.dispose();
    _transactionsNotifier.dispose();
    _accountsNotifier.dispose();
    super.dispose();
  }

  void _recalculateSummary() {
    // Obtenemos los datos más recientes de los notificadores
    final transactions = _transactionsNotifier.value;
    final accounts = _accountsNotifier.value;

    // Calculamos ingresos, egresos y gastos por categoría
    double totalIngresos = 0;
    double totalEgresos = 0;
    final Map<String, double> expenseByCategory = {};

    for (var t in transactions) {
      final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
      if (t['type'] == 'income') {
        totalIngresos += amount;
      } else {
        totalEgresos += amount;
        final category = t['category'] as String;
        expenseByCategory[category] =
            (expenseByCategory[category] ?? 0) + amount;
      }
    }

    // Calculamos los balances de las cuentas
    double totalBalance = 0;
    double cashBalance = 0;
    double virtualBalance = 0;

    for (var acc in accounts) {
      final balance = (acc['balance'] as num?)?.toDouble() ?? 0.0;
      totalBalance += balance;
      if ((acc['name'] as String).toLowerCase() == 'efectivo') {
        cashBalance += balance;
      } else {
        virtualBalance += balance;
      }
    }

    // Actualizamos el notificador del resumen con toda la información
    _summaryNotifier.value = FinancialSummary(
      totalIngresos: totalIngresos,
      totalEgresos: totalEgresos,
      saldo: totalIngresos - totalEgresos,
      expenseByCategory: expenseByCategory,
      totalBalance: totalBalance,
      cashBalance: cashBalance,
      virtualBalance: virtualBalance,
    );
  }

  void _navigateToAddTransaction(String type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddTransactionPage(initialType: type),
      ),
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
                    builder: (context) => AddTransactionPage(
                      transaction: transaction,
                      initialType: '',
                    ),
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
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await supabase.from('transactions').delete().match({
          'id': transaction['id'],
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transacción eliminada')));
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
      appBar: MyAppBar(
        title: 'Resumen Financiero',
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined), // Icono de perfil
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (context) => const ProfilePage()),
              );
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
              builder: (context, summary, _) => FinancialSummaryCard(
                totalIngresos: currencyFormat.format(summary.totalIngresos),
                totalEgresos: currencyFormat.format(summary.totalEgresos),
                saldo: currencyFormat.format(
                  summary.totalBalance,
                ), // Usamos el nuevo saldo total
                cashBalance: currencyFormat.format(
                  summary.cashBalance,
                ), // Pasamos el saldo de efectivo
                virtualBalance: currencyFormat.format(
                  summary.virtualBalance,
                ), // Pasamos el saldo virtual
                expenseData: summary.expenseByCategory,
              ),
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
                if (transactions.isEmpty &&
                    _summaryNotifier.value.totalIngresos == 0 &&
                    _summaryNotifier.value.totalEgresos == 0) {
                  // Muestra el shimmer solo si no hay datos iniciales
                  if (_accountsNotifier.value.isEmpty) {
                    return const LoadingShimmer();
                  }
                }
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
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 32.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton.extended(
              heroTag: 'fab_expense',
              onPressed: () => _navigateToAddTransaction('expense'),
              label: const Text('Egreso'),
              icon: const Icon(Icons.remove),
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            FloatingActionButton.extended(
              heroTag: 'fab_income',
              onPressed: () => _navigateToAddTransaction('income'),
              label: const Text('Ingreso'),
              icon: const Icon(Icons.add),
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

class FinancialSummaryCard extends StatelessWidget {
  final String totalIngresos, totalEgresos, saldo, cashBalance, virtualBalance;
  final Map<String, double> expenseData;

  const FinancialSummaryCard({
    super.key,
    required this.totalIngresos,
    required this.totalEgresos,
    required this.saldo,
    required this.cashBalance,
    required this.virtualBalance,
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
                        'Saldo Total', // <-- Título cambiado
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(color: AppTheme.subtextColor),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        saldo,
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryColor,
                            ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      // --- NUEVO: Desglose de efectivo y virtual ---
                      Row(
                        children: [
                          _buildBalanceDetail(
                            context,
                            Icons.money,
                            'Efectivo',
                            cashBalance,
                          ),
                          const SizedBox(width: 16),
                          _buildBalanceDetail(
                            context,
                            Icons.credit_card,
                            'Virtual',
                            virtualBalance,
                          ),
                        ],
                      ),
                      // --- FIN DEL NUEVO WIDGET ---
                    ],
                  ),
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

  // --- WIDGET AUXILIAR NUEVO ---
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
  // --- FIN DEL WIDGET AUXILIAR ---

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
    final isIncome = transaction['type'] == 'income';
    final color = isIncome ? AppTheme.accentColor : Colors.redAccent;
    final icon = isIncome ? Icons.arrow_upward : Icons.arrow_downward;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) =>
                  TransactionDetailPage(transaction: transaction),
            ),
          );
        },
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
                      '${transaction['category']} • ${DateFormat.yMMMd('es_AR').format(DateTime.parse(transaction['date']))}',
                      style: const TextStyle(
                        color: AppTheme.subtextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                currencyFormat.format(
                  (transaction['amount'] as num).toDouble(),
                ),
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
