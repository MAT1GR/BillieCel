import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/app_theme.dart';
import 'package:mi_billetera_digital/widgets/loading_shimmer.dart';
import 'package:mi_billetera_digital/pages/add_savings_goal_page.dart';
import 'package:mi_billetera_digital/pages/add_funds_page.dart';
import 'package:mi_billetera_digital/widgets/my_app_bar.dart';

class SavingsGoalsPage extends StatefulWidget {
  const SavingsGoalsPage({super.key});

  @override
  State<SavingsGoalsPage> createState() => _SavingsGoalsPageState();
}

class _SavingsGoalsPageState extends State<SavingsGoalsPage> {
  late final Stream<List<Map<String, dynamic>>> _goalsStream;
  final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$ ');

  @override
  void initState() {
    super.initState();
    _goalsStream = supabase
        .from('savings_goals')
        .stream(primaryKey: ['id'])
        .order('created_at', ascending: false);
  }

  void _showGoalOptions(BuildContext context, Map<String, dynamic> goal) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: const Icon(
                Icons.add_circle_outline,
                color: AppTheme.primaryColor,
              ),
              title: const Text('Añadir Fondos'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddFundsPage(goal: goal),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: AppTheme.primaryColor),
              title: const Text('Editar Meta'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => AddSavingsGoalPage(goal: goal),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text(
                'Eliminar Meta',
                style: TextStyle(color: Colors.redAccent),
              ),
              onTap: () {
                Navigator.of(context).pop();
                _deleteGoal(context, goal);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteGoal(
    BuildContext context,
    Map<String, dynamic> goal,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: Text(
          '¿Seguro que quieres eliminar la meta "${goal['name']}"?',
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
        await supabase.from('savings_goals').delete().match({'id': goal['id']});
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Meta eliminada')));
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: MyAppBar(title: 'Metas de Ahorro'),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _goalsStream,
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const LoadingShimmer();
          final goals = snapshot.data!;

          if (goals.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 48.0, horizontal: 24.0),
                child: Text(
                  'Aún no tienes metas de ahorro.\n¡Crea una para empezar a ahorrar!',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppTheme.subtextColor, fontSize: 16),
                ),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: goals.length,
            itemBuilder: (context, index) {
              final goal = goals[index];
              return SavingsGoalListItem(
                goal: goal,
                currencyFormat: currencyFormat,
                onLongPress: () => _showGoalOptions(context, goal),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => const AddSavingsGoalPage(goal: {}),
            ),
          );
        },
        backgroundColor: AppTheme.primaryColor,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}

class SavingsGoalListItem extends StatelessWidget {
  final Map<String, dynamic> goal;
  final NumberFormat currencyFormat;
  final VoidCallback onLongPress;

  const SavingsGoalListItem({
    super.key,
    required this.goal,
    required this.currencyFormat,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final targetAmount = (goal['target_amount'] as num).toDouble();
    final currentAmount = (goal['current_amount'] as num).toDouble();
    final progress = (targetAmount > 0)
        ? (currentAmount / targetAmount).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        borderRadius: BorderRadius.circular(16.0),
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                goal['name'],
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                borderRadius: BorderRadius.circular(6),
                backgroundColor: Colors.grey[200],
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.accentColor,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    currencyFormat.format(currentAmount),
                    style: const TextStyle(
                      color: AppTheme.subtextColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    currencyFormat.format(targetAmount),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  icon: const Icon(Icons.add_circle_outline, size: 20),
                  label: const Text('Añadir Fondos'),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AddFundsPage(goal: goal),
                      ),
                    );
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: AppTheme.primaryColor,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
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
