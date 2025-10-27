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
      final future = supabase
          .from('recurring_transactions')
          .select('id, description, amount, next_occurrence_date, is_active, accounts(name), categories(name)')
          .eq('user_id', userId)
          .order('next_occurrence_date', ascending: true);
      _recurringTransactionsStream = Stream.fromFuture(future);
    } else {
      _recurringTransactionsStream = Stream.value([]);
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
          setState(() {
            _setupRecurringTransactionsStream();
          });
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

  void _refreshTransactions() {
    if (mounted) {
      setState(() {
        _setupRecurringTransactionsStream();
      });
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
              _refreshTransactions();
            },
          ),
        ],
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
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
                  ElevatedButton.icon(
                    icon: const Icon(Icons.add),
                    label: const Text('Crear Transacción Automática'),
                    onPressed: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const AddRecurringTransactionPage(),
                        ),
                      );
                      _refreshTransactions();
                    },
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

              final accountName = transaction['accounts']?['name'] ?? 'N/A';
              final accountIcon = transaction['accounts']?['icon'] ?? '';
              final categoryName = transaction['categories']?['name'] ?? 'N/A';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => AddRecurringTransactionPage(
                          recurringTransaction: transaction,
                        ),
                      ),
                    );
                    _refreshTransactions();
                  },
                  leading: AccountLogoWidget(
                    accountName: accountName,
                    iconPath: accountIcon,
                    size: 40,
                  ),
                  title: Text(transaction['description'] ?? 'Sin descripción'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Monto: $formattedAmount'),
                      Text(
                        'Próxima ocurrencia: ${DateFormat.yMd().format(nextOccurrence)}',
                      ),
                      Row(
                        children: [
                          const Icon(Icons.category, size: 16),
                          const SizedBox(width: 4),
                          Text(categoryName),
                        ],
                      ),
                      Row(
                        children: [
                          const Text('Activa:'),
                          Switch(
                            value: transaction['is_active'] ?? true,
                            onChanged: (bool value) async {
                              try {
                                await supabase
                                    .from('recurring_transactions')
                                    .update({'is_active': value}).eq(
                                        'id', transaction['id']);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Transacción ${value ? 'activada' : 'pausada'}.',
                                      ),
                                    ),
                                  );
                                  _refreshTransactions();
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Error al cambiar estado: $e',
                                      ),
                                    ),
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
                    onPressed: () => _deleteRecurringTransaction(
                        transaction['id'].toString()),
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
