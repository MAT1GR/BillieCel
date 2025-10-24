import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/pages/add_debt_page.dart';
import 'package:mi_billetera_digital/models/debt_model.dart';
import 'package:mi_billetera_digital/pages/pay_debt_page.dart';
import 'package:mi_billetera_digital/widgets/debt_list_item.dart';
import 'package:mi_billetera_digital/widgets/loading_shimmer.dart';

class DebtsPage extends StatefulWidget {
  const DebtsPage({super.key});

  @override
  State<DebtsPage> createState() => _DebtsPageState();
}

class _DebtsPageState extends State<DebtsPage> with SingleTickerProviderStateMixin {
  late Stream<List<Map<String, dynamic>>> _debtsStream;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _setupStream();
  }

  void _setupStream() {
    dynamic query = supabase.from('debts').stream(primaryKey: ['id']);
    query = query.eq('is_paid', false);
    _debtsStream = query.order('created_at', ascending: false);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Deudas y Préstamos'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Me Deben'),
            Tab(text: 'Debo'),
          ],
        ),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _debtsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingShimmer();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final debts = snapshot.data ?? [];

          final owedDebts = debts.where((d) => (d['amount'] as num) > 0).toList();
          final owingDebts = debts.where((d) => (d['amount'] as num) < 0).toList();

          final totalOwed = owedDebts.fold<double>(0, (sum, d) => sum + (d['amount'] as num));
          final totalOwing = owingDebts.fold<double>(0, (sum, d) => sum + (d['amount'] as num));

          final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$ ');

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Column(
                          children: [
                            const Text('Total por Cobrar', style: TextStyle(fontSize: 16)),
                            Text(
                              currencyFormat.format(totalOwed),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        Column(
                          children: [
                            const Text('Total por Pagar', style: TextStyle(fontSize: 16)),
                            Text(
                              currencyFormat.format(totalOwing.abs()),
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildDebtList(owedDebts),
                    _buildDebtList(owingDebts),
                  ],
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final debtType = _tabController.index == 0 ? DebtType.owed : DebtType.owing;
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => AddDebtPage(initialDebtType: debtType)),
          );
          _setupStream(); // Refresh stream after adding debt
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildDebtList(List<Map<String, dynamic>> debts) {
    if (debts.isEmpty) {
      return const Center(
        child: Text('No hay deudas en esta categoría.'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16.0),
      itemCount: debts.length,
      itemBuilder: (context, index) {
        final debt = debts[index];
        return DebtListItem(
          debt: debt,
          onLongPress: () => _showDebtOptions(context, debt),
        );
      },
    );
  }

  void _showDebtOptions(BuildContext context, Map<String, dynamic> debt) {
    final isOwing = (debt['amount'] as num) < 0;

    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: Wrap(
            children: [
              if (isOwing)
                ListTile(
                  leading: Icon(Icons.payment, color: Theme.of(context).primaryColor),
                  title: const Text('Realizar Pago'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => PayDebtPage(debt: debt),
                      ),
                    );
                    _setupStream(); // Refresh stream after paying debt
                  },
                ),
              ListTile(
                leading: Icon(Icons.edit, color: Theme.of(context).primaryColor),
                title: const Text('Editar Deuda'),
                onTap: () async {
                  Navigator.of(context).pop();
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AddDebtPage(debt: debt),
                    ),
                  );
                  _setupStream(); // Refresh stream after editing debt
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text('Eliminar', style: TextStyle(color: Colors.redAccent)),
                onTap: () {
                  Navigator.of(context).pop();
                  _deleteDebt(context, debt);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _markAsPaid(BuildContext context, Map<String, dynamic> debt) async {
    try {
      await supabase.from('debts').update({'is_paid': true}).match({'id': debt['id']});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Deuda marcada como pagada')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al marcar como pagada: $e')),
        );
      }
    }
  }

  Future<void> _deleteDebt(BuildContext context, Map<String, dynamic> debt) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text('¿Seguro que quieres eliminar esta deuda?'),
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
        await supabase.from('debts').delete().match({'id': debt['id']});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Deuda eliminada')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al eliminar: $e')),
          );
        }
      }
    }
  }
}

