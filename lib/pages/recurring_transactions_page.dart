import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/pages/add_recurring_transaction_page.dart';
import 'package:mi_billetera_digital/widgets/account_logo_widget.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RecurringTransactionsPage extends StatefulWidget {
  const RecurringTransactionsPage({super.key});

  @override
  State<RecurringTransactionsPage> createState() =>
      _RecurringTransactionsPageState();
}

class _RecurringTransactionsPageState extends State<RecurringTransactionsPage> {
  late Stream<List<Map<String, dynamic>>> _recurringTransactionsStream;

  @override
  void initState() {
    super.initState();
    _setupRecurringTransactionsStream();
  }

  void _setupRecurringTransactionsStream() {
    final currentUser = supabase.auth.currentUser;
    if (currentUser != null) {
      final userId = currentUser.id;
      _recurringTransactionsStream = supabase
          .from('recurring_transactions')
          .stream(primaryKey: ['id'])
          .eq('user_id', userId)
          .select('*, accounts(name, icon), categories(name, icon)')
          .order('next_occurrence_date', ascending: true);
    }
  }

  Future<void> _deleteRecurringTransaction(String transactionId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta transacción recurrente?',
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

    if (confirm == true) {
      try {
        await supabase.from('recurring_transactions').delete().match({
          'id': transactionId,
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transacción recurrente eliminada.')),
          );
        }
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
      appBar: AppBar(
        title: const Text('Transacciones Automáticas'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => const AddRecurringTransactionPage(),
                ),
              );
              _setupRecurringTransactionsStream(); // Refresh stream
            },
          ),
        ],
      ),
      body: _recurringTransactionsStream == null
          ? const Center(
              child: Text(
                'Inicia sesión para ver tus transacciones recurrentes.',
              ),
            )
          : StreamBuilder<List<Map<String, dynamic>>>(
              stream: _recurringTransactionsStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'No hay transacciones automáticas.',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        FloatingActionButton.extended(
                          onPressed: () async {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) =>
                                    const AddRecurringTransactionPage(),
                              ),
                            );
                            _setupRecurringTransactionsStream(); // Refresh stream
                          },
                          label: const Text('Crear Transacción Automática'),
                          icon: const Icon(Icons.add),
                        ),
                      ],
                    ),
                  );
                }

                final transactions = snapshot.data!;

                return ListView.builder(
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    final nextOccurrence = DateTime.parse(
                      transaction['next_occurrence_date'],
                    );
                    final formattedAmount = NumberFormat.currency(
                      symbol: '\$',
                    ).format(transaction['amount']);

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (context) => AddRecurringTransactionPage(
                                recurringTransaction: transaction,
                              ),
                            ),
                          );
                        },
                        leading: AccountLogoWidget(
                          accountName: transaction['accounts']['name'],
                          iconPath: transaction['accounts']['icon'] ?? '',
                          size: 40,
                        ),
                        title: Text(transaction['description']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Monto: $formattedAmount'),
                            Text('Próxima ocurrencia: ${DateFormat.yMd().format(nextOccurrence)}'),
                            Row(
                              children: [
                                const Icon(Icons.category, size: 16),
                                const SizedBox(width: 4),
                                Text(transaction['categories']['name']),
                              ],
                            ),
                            Row(
                              children: [
                                const Text('Activa:'),
                                Switch(
                                  value: transaction['is_active'] ?? true, // Assuming 'is_active' column exists, default to true
                                  onChanged: (bool value) async {
                                    try {
                                      await supabase.from('recurring_transactions').update({'is_active': value}).eq('id', transaction['id']);
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Transacción ${value ? 'activada' : 'pausada'}.')),
                                        );
                                      }
                                    } catch (e) {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Error al cambiar estado: $e')),
                                        );
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ],
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () =>
                              _deleteRecurringTransaction(transaction['id']),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}


