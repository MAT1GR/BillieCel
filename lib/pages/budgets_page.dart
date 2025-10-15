import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/app_theme.dart';
import 'package:mi_billetera_digital/widgets/loading_shimmer.dart';
import 'package:mi_billetera_digital/pages/add_budget_page.dart';
import 'package:mi_billetera_digital/widgets/my_app_bar.dart';
import 'package:supabase/src/supabase_query_builder.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$ ');
  late final Stream<List<Map<String, dynamic>>> _budgetsStream;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _budgetsStream = supabase.from('budgets').stream(primaryKey: ['id']).map((
      listOfBudgets,
    ) {
      return listOfBudgets
          .where(
            (budget) =>
                budget['month'] == now.month && budget['year'] == now.year,
          )
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(title: 'Presupuestos del Mes'),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _budgetsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingShimmer();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final budgets = snapshot.data ?? [];

          if (budgets.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24.0),
                child: Text(
                  'No has creado presupuestos para este mes.\nUsa el botón + para empezar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.subtextColor, fontSize: 16),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: budgets.length,
            itemBuilder: (context, index) {
              final budget = budgets[index];
              return FutureBuilder<double>(
                future: _getSpentAmount(budget['category']),
                builder: (context, spentSnapshot) {
                  final spentAmount = spentSnapshot.data ?? 0.0;
                  return BudgetListItem(
                    budget: budget,
                    spentAmount: spentAmount,
                    currencyFormat: currencyFormat,
                    onLongPress: () => _showBudgetOptions(context, budget),
                  );
                },
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddBudgetPage(budget: {}),
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Future<double> _getSpentAmount(String category) async {
    final now = DateTime.now();
    final firstDayOfMonth = DateTime(now.year, now.month, 1).toIso8601String();
    final response = await supabase
        .from('transactions')
        .select('amount')
        .eq('type', 'expense')
        .eq('category', category)
        .gte('date', firstDayOfMonth);

    double total = 0.0;
    for (var trans in (response as List)) {
      total += (trans['amount'] as num?)?.toDouble() ?? 0.0;
    }
    return total;
  }

  void _showBudgetOptions(BuildContext context, Map<String, dynamic> budget) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.primaryColor),
              title: const Text('Editar Presupuesto'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddBudgetPage(budget: budget),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text(
                'Eliminar Presupuesto',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _deleteBudget(context, budget);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteBudget(
    BuildContext context,
    Map<String, dynamic> budget,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Seguro que quieres eliminar el presupuesto para "${budget['category']}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await supabase.from('budgets').delete().match({'id': budget['id']});
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Presupuesto eliminado')));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error: $e')));
        }
      }
    }
  }
}

class BudgetListItem extends StatelessWidget {
  final Map<String, dynamic> budget;
  final double spentAmount;
  final NumberFormat currencyFormat;
  final VoidCallback onLongPress;

  const BudgetListItem({
    super.key,
    required this.budget,
    required this.spentAmount,
    required this.currencyFormat,
    required this.onLongPress,
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
      child: InkWell(
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(16.0),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                budget['category'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
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
      ),
    );
  }
}
