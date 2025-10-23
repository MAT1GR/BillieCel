import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/utils/currency_input_formatter.dart';

import 'package:mi_billetera_digital/widgets/account_logo_widget.dart';

class PayDebtPage extends StatefulWidget {
  final Map<String, dynamic> debt;

  const PayDebtPage({super.key, required this.debt});

  @override
  State<PayDebtPage> createState() => _PayDebtPageState();
}

class _PayDebtPageState extends State<PayDebtPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _selectedAccountId;
  List<Map<String, dynamic>> _accounts = [];

  @override
  void initState() {
    super.initState();
    _amountController.text = (widget.debt['amount'] as num).abs().toString();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    final accounts = await supabase
        .from('accounts')
        .select()
        .eq('user_id', supabase.auth.currentUser!.id);
    setState(() {
      _accounts = (accounts as List).cast<Map<String, dynamic>>();
    });
  }

  Future<void> _savePayment() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text.replaceAll('.', ''));
      final remainingAmount = (widget.debt['amount'] as num).abs();

      if (amount > remainingAmount) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('El monto no puede ser mayor a la deuda'),
          ),
        );
        return;
      }

      try {
        // 1. Create expense transaction
        await supabase.from('transactions').insert({
          'user_id': supabase.auth.currentUser!.id,
          'account_id': _selectedAccountId,
          'type': 'expense',
          'amount': amount,
          'description': 'Pago de deuda a ${widget.debt['person_name']}',
          'category': 'Pago de Deuda',
          'date': DateTime.now().toIso8601String(),
        });

        // 2. Update source account balance
        final sourceAccount = _accounts.firstWhere(
          (acc) => acc['id'] == _selectedAccountId,
        );
        final newBalance = (sourceAccount['balance'] as num) - amount;
        await supabase.from('accounts').update({'balance': newBalance}).match({
          'id': _selectedAccountId!,
        });

        // 3. Update debt amount
        final newDebtAmount = widget.debt['amount'] + amount;
        final isPaid = newDebtAmount >= 0;
        await supabase
            .from('debts')
            .update({'amount': newDebtAmount, 'is_paid': isPaid})
            .match({'id': widget.debt['id']});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Pago realizado correctamente')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar el pago: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Realizar Pago')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            Text('Deuda a: ${widget.debt['person_name']}'),
            const SizedBox(height: 10),
            Text('Monto restante: \$${(widget.debt['amount'] as num).abs()}'),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Monto a pagar'),
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, ingresa un monto';
                }
                if (double.tryParse(value.replaceAll('.', '')) == null) {
                  return 'Por favor, ingresa un número válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _selectedAccountId,
              decoration: const InputDecoration(labelText: 'Pagar con'),
              items: _accounts.map((account) {
                return DropdownMenuItem<String>(
                  value: account['id'] as String,
                  child: Row(
                    children: [
                      AccountLogoWidget(
                        accountName: account['name'] as String,
                        iconPath: null,
                      ),
                      const SizedBox(width: 10),
                      Text(account['name'] as String),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedAccountId = value;
                });
              },
              validator: (value) {
                if (value == null) {
                  return 'Por favor, selecciona una cuenta';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _savePayment,
              child: const Text('Confirmar Pago'),
            ),
          ],
        ),
      ),
    );
  }
}
