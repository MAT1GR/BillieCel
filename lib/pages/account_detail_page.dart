import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/app_theme.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/widgets/loading_shimmer.dart'; // <-- ESTA ES LA LÍNEA CORREGIDA
import 'package:mi_billetera_digital/widgets/transaction_list_item.dart';

import 'package:mi_billetera_digital/pages/add_transaction_page.dart';
import 'package:mi_billetera_digital/utils/couple_mode_provider.dart';
import 'package:provider/provider.dart';

class AccountDetailPage extends StatefulWidget {
  final Map<String, dynamic> account;

  const AccountDetailPage({super.key, required this.account});

  @override
  State<AccountDetailPage> createState() => _AccountDetailPageState();
}

class _AccountDetailPageState extends State<AccountDetailPage> {
  late Stream<List<Map<String, dynamic>>> _transactionsStream;

  @override
  void initState() {
    super.initState();
    // Listen to couple mode changes to refresh the stream
    context.read<CoupleModeProvider>().addListener(_onCoupleModeChanged);
    _transactionsStream = _createStream();
  }

  @override
  void dispose() {
    context.read<CoupleModeProvider>().removeListener(_onCoupleModeChanged);
    super.dispose();
  }

  void _onCoupleModeChanged() {
    if (mounted) {
      setState(() {
        _transactionsStream = _createStream();
      });
    }
  }

  Stream<List<Map<String, dynamic>>> _createStream() {
    // NOTE: This is now a Future-based stream, not a realtime stream,
    // to fix a compilation error with the current Supabase library version.
    final future = () async {
      final userId = supabase.auth.currentUser!.id;
      final coupleModeProvider = context.read<CoupleModeProvider>();

      final query = supabase.from('transactions').select();

      final filteredQuery = coupleModeProvider.isJointMode
          ? query.eq('couple_id', coupleModeProvider.coupleId!)
          : query.eq('user_id', userId);

      final data = await filteredQuery
          .eq('account_id', widget.account['id'])
          .order('date', ascending: false);
      return data;
    }();
    return Stream.fromFuture(future);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.account['name'])),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _transactionsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingShimmer();
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          final transactions = snapshot.data ?? [];

          if (transactions.isEmpty) {
            return const Center(
              child: Text(
                'No hay movimientos en esta cuenta.',
                style: TextStyle(color: AppTheme.subtextColor, fontSize: 16),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16.0),
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              return TransactionListItem(
                transaction: transaction,
                onLongPress: () => _showTransactionOptions(context, transaction),
              );
            },
          );
        },
      ),
    );
  }

  void _showTransactionOptions(
      BuildContext context, Map<String, dynamic> transaction) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: Theme.of(context).primaryColor),
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
              title: const Text('Eliminar',
                  style: TextStyle(color: Colors.redAccent)),
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
      BuildContext context, Map<String, dynamic> transaction) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content:
            const Text('¿Seguro que quieres eliminar esta transacción?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await supabase
            .from('transactions')
            .delete()
            .match({'id': transaction['id']});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Transacción eliminada')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al eliminar: $e')));
        }
      }
    }
  }
}
