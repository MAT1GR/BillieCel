import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mi_billetera_digital/app_theme.dart';

class TransactionDetailPage extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '\$ ',
    );
    final isIncome = transaction['type'] == 'income';
    final amount = (transaction['amount'] as num).toDouble();
    final date = DateTime.parse(transaction['date']);
    final formattedDate = DateFormat.yMMMd('es_AR').add_jm().format(date);

    return Scaffold(
      appBar: AppBar(title: const Text('Detalle de Transacción')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction['description'],
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    currencyFormat.format(isIncome ? amount : -amount),
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isIncome ? AppTheme.accentColor : Colors.redAccent,
                    ),
                  ),
                  const Divider(height: 32),
                  _buildDetailRow(
                    context,
                    icon: Icons.calendar_today,
                    title: 'Fecha',
                    value: formattedDate,
                  ),
                  _buildDetailRow(
                    context,
                    icon: Icons.category,
                    title: 'Categoría',
                    value: transaction['category'],
                  ),
                  _buildDetailRow(
                    context,
                    icon: Icons.payment,
                    title: 'Método de Pago',
                    value: transaction['payment_method'] ?? 'No especificado',
                  ),
                  _buildDetailRow(
                    context,
                    icon: isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                    title: 'Tipo',
                    value: isIncome ? 'Ingreso' : 'Egreso',
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.subtextColor, size: 20),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: AppTheme.subtextColor),
                ),
                const SizedBox(height: 2),
                Text(value, style: Theme.of(context).textTheme.bodyLarge),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
