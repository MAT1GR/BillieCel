import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/app_theme.dart';
import 'package:mi_billetera_digital/widgets/loading_shimmer.dart';
import 'package:mi_billetera_digital/pages/add_budget_page.dart';

import 'package:rxdart/rxdart.dart';

class BudgetsPage extends StatefulWidget {
  const BudgetsPage({super.key});

  @override
  State<BudgetsPage> createState() => _BudgetsPageState();
}

class _BudgetsPageState extends State<BudgetsPage> {
  final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$ ');
  late final Stream<List<Map<String, dynamic>>> _budgetsStream;
  late final Stream<List<Map<String, dynamic>>> _transactionsStream;
  Map<String, Map<String, dynamic>> _categoryDetails = {};

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _budgetsStream = supabase.from('budgets').stream(primaryKey: ['id']).map((listOfBudgets) {
      return listOfBudgets
          .where((budget) => budget['month'] == now.month && budget['year'] == now.year)
          .toList();
    });

    dynamic query = supabase.from('transactions').stream(primaryKey: ['id']);
    query = query.eq('type', 'expense');
    query = query.gte('date', DateTime(now.year, now.month, 1).toIso8601String());
    _transactionsStream = query.lte('date', DateTime(now.year, now.month + 1, 0).toIso8601String());

    _loadCategoryDetails();
  }

  Future<void> _loadCategoryDetails() async {
    final categoriesData = await supabase.from('categories').select('name, icon, color');
    final Map<String, Map<String, dynamic>> details = {};
    for (var cat in (categoriesData as List)) {
      details[cat['name']] = cat;
    }
    if (mounted) {
      setState(() {
        _categoryDetails = details;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<List<dynamic>>(
        stream: CombineLatestStream.list([
          _budgetsStream,
          _transactionsStream,
        ]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting || _categoryDetails.isEmpty) {
            return const LoadingShimmer();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final budgets = (snapshot.data?[0] as List<Map<String, dynamic>>?) ?? [];
          final transactions = (snapshot.data?[1] as List<Map<String, dynamic>>?) ?? [];

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

          final spentByCategory = <String, double>{};
          for (var transaction in transactions) {
            final category = transaction['category'] as String;
            final amount = (transaction['amount'] as num?)?.toDouble() ?? 0.0;
            spentByCategory[category] = (spentByCategory[category] ?? 0) + amount;
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: budgets.length,
            itemBuilder: (context, index) {
              final budget = budgets[index];
              final categoryDetail = _categoryDetails[budget['category']];
              final spentAmount = spentByCategory[budget['category']] ?? 0.0;

              return BudgetListItem(
                budget: budget,
                categoryDetail: categoryDetail,
                spentAmount: spentAmount,
                currencyFormat: currencyFormat,
                onLongPress: () => _showBudgetOptions(context, budget),
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
        backgroundColor: Theme.of(context).primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  void _showBudgetOptions(BuildContext context, Map<String, dynamic> budget) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: Theme.of(context).primaryColor),
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
  final Map<String, dynamic>? categoryDetail;
  final double spentAmount;
  final NumberFormat currencyFormat;
  final VoidCallback onLongPress;

  const BudgetListItem({
    super.key,
    required this.budget,
    this.categoryDetail,
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
        : (progress > 0.6 ? Colors.orangeAccent : Theme.of(context).primaryColor);
        
    final Map<String, IconData> iconMap = {
      'category': Icons.category,
      'fastfood': Icons.fastfood,
      'directions_bus': Icons.directions_bus,
      'hotel': Icons.hotel,
      'healing': Icons.healing,
      'theaters': Icons.theaters,
      'shopping_cart': Icons.shopping_cart,
      'home': Icons.home,
      'school': Icons.school,
      'pets': Icons.pets,
      'fitness_center': Icons.fitness_center,
      'card_giftcard': Icons.card_giftcard,
      'attach_money': Icons.attach_money,
      'savings': Icons.savings,
      'lightbulb': Icons.lightbulb,
      'receipt': Icons.receipt,
      'build': Icons.build,
      'flight': Icons.flight,
    };

    final iconData = iconMap[categoryDetail?['icon']] ?? Icons.category;
    final iconColor = Color(int.parse(categoryDetail?['color']?.substring(2) ?? 'FFFFFFFF', radix: 16));

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
              Row(
                children: [
                  Icon(iconData, color: iconColor),
                  const SizedBox(width: 8),
                  Text(
                    budget['category'],
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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