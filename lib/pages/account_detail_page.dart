import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/app_theme.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/widgets/loading_shimmer.dart'; // <-- ESTA ES LA LÍNEA CORREGIDA
import 'package:mi_billetera_digital/pages/transactions_page.dart'; // Reutilizaremos el TransactionListItem

class AccountDetailPage extends StatelessWidget {
  final Map<String, dynamic> account;

  const AccountDetailPage({super.key, required this.account});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(account['name'])),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _getTransactionsForAccount(account['id']),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const LoadingShimmer();
          }
          final transactions = snapshot.data!;

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
                onLongPress: () {
                  // Opcional: Aquí podrías añadir la lógica para editar/eliminar
                  // desde esta pantalla también, si lo deseas en el futuro.
                },
              );
            },
          );
        },
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getTransactionsForAccount(
    String accountId,
  ) async {
    final response = await supabase
        .from('transactions')
        .select()
        .eq('account_id', accountId)
        .order('date', ascending: false);
    return (response as List).cast<Map<String, dynamic>>();
  }
}
