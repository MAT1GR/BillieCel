import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:mi_billetera_digital/pages/pay_debt_page.dart';
import 'package:mi_billetera_digital/pages/receive_payment_page.dart';

class DebtListItem extends StatelessWidget {
  final Map<String, dynamic> debt;
  final VoidCallback onLongPress;

  const DebtListItem({super.key, required this.debt, required this.onLongPress});

  @override
  Widget build(BuildContext context) {
    final amount = (debt['amount'] as num).toDouble();
    final isOwed = amount > 0;
    final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$ ');

    final originalAmount = (debt['original_amount'] as num?)?.toDouble();
    final progress = (originalAmount != null && originalAmount > 0)
        ? (originalAmount - amount.abs()) / originalAmount
        : 0.0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: InkWell(
        onLongPress: onLongPress,
        onTap: () {
          if (isOwed) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ReceivePaymentPage(debt: debt),
              ),
            );
          } else {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => PayDebtPage(debt: debt),
              ),
            );
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            children: [
              Row(
                children: [
                  Icon(
                    isOwed ? Icons.arrow_upward : Icons.arrow_downward,
                    color: isOwed ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          debt['person_name'],
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (debt['description'] != null &&
                            debt['description'].isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              debt['description'],
                              style: TextStyle(
                                fontSize: 14,
                                color: Theme.of(context)
                                    .textTheme
                                    .bodySmall
                                    ?.color
                                    ?.withOpacity(0.75),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        currencyFormat.format(amount.abs()),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                          color: isOwed ? Colors.green : Colors.red,
                        ),
                      ),
                      if (originalAmount != null && originalAmount != amount.abs())
                        Text(
                          'de ${currencyFormat.format(originalAmount)}',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.grey,
                          ),
                        ),
                    ],
                  ),
                ],
              ),
              if (originalAmount != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.grey[300],
                    valueColor: AlwaysStoppedAnimation<Color>(
                      isOwed ? Colors.green : Colors.red,
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
