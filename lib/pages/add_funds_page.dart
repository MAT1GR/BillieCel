import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/utils/currency_input_formatter.dart';
import 'package:mi_billetera_digital/utils/couple_mode_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddFundsPage extends StatefulWidget {
  final Map<String, dynamic> goal;
  const AddFundsPage({super.key, required this.goal});

  @override
  State<AddFundsPage> createState() => _AddFundsPageState();
}

class _AddFundsPageState extends State<AddFundsPage> {
  final _formKey = GlobalKey<FormState>();

  final _amountController = TextEditingController();

  bool _isLoading = false;

  List<Map<String, dynamic>> _userAccounts = [];

  String? _selectedAccountId;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final userId = supabase.auth.currentUser!.id;
    final coupleModeProvider = context.read<CoupleModeProvider>();

    PostgrestFilterBuilder queryBuilder = supabase
        .from('accounts')
        .select('id, name, balance');

    if (coupleModeProvider.isJointMode) {
      queryBuilder = queryBuilder.eq('couple_id', coupleModeProvider.coupleId!); // Filter by couple_id
    } else {
      queryBuilder = queryBuilder.eq('user_id', userId); // Filter by user_id
    }

    final accountsData = await queryBuilder;

    if (mounted) {
      setState(() {
        _userAccounts = (accountsData as List).cast<Map<String, dynamic>>();
        if (_userAccounts.length == 1) {
          _selectedAccountId = _userAccounts.first['id'];
        }
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitFunds() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final amount = double.parse(_amountController.text.replaceAll('.', ''));
        final newCurrentAmount = (widget.goal['current_amount'] as num) + amount;

        final userId = supabase.auth.currentUser!.id;
        final coupleModeProvider = context.read<CoupleModeProvider>();

        // 1. Create the expense transaction
        final transactionData = {
          'description': 'Aporte a meta: ${widget.goal['name']}',
          'amount': amount,
          'type': 'expense',
          'category': 'Ahorros', // Assuming 'Ahorros' category exists
          'date': DateTime.now().toIso8601String(),
          'account_id': _selectedAccountId,
        };

        if (coupleModeProvider.isJointMode) {
          transactionData['couple_id'] = coupleModeProvider.coupleId!;
          transactionData['user_id'] = userId; // Still associate with user for RLS/tracking
        } else {
          transactionData['user_id'] = userId;
        }
        await supabase.from('transactions').insert(transactionData);

        // 2. Update source account balance
        final sourceAccount = _userAccounts.firstWhere((acc) => acc['id'] == _selectedAccountId);
        final newBalance = (sourceAccount['balance'] as num) - amount;

        PostgrestFilterBuilder updateAccountQuery = supabase
            .from('accounts')
            .update({'balance': newBalance})
            .match({'id': _selectedAccountId!});

        if (coupleModeProvider.isJointMode) {
          updateAccountQuery = updateAccountQuery.eq('couple_id', coupleModeProvider.coupleId!); // Ensure updating correct couple account
        } else {
          updateAccountQuery = updateAccountQuery.eq('user_id', userId); // Ensure updating correct personal account
        }
        await updateAccountQuery;

        // 3. Update the savings goal
        PostgrestFilterBuilder updateGoalQuery = supabase
            .from('savings_goals')
            .update({'current_amount': newCurrentAmount})
            .match({'id': widget.goal['id']});

        if (coupleModeProvider.isJointMode) {
          updateGoalQuery = updateGoalQuery.eq('couple_id', coupleModeProvider.coupleId!); // Ensure updating correct couple goal
        } else {
          updateGoalQuery = updateGoalQuery.eq('user_id', userId); // Ensure updating correct personal goal
        }
        await updateGoalQuery;

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fondos añadidos y transacción creada')),
          );
          Navigator.of(context).pop();
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al añadir fondos: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Añadir Fondos a "${widget.goal['name']}"' )),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Monto a Añadir',
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              autofocus: true,
              inputFormatters: [CurrencyInputFormatter()],
              validator: (value) {
                if (value == null ||
                    value.isEmpty ||
                    double.tryParse(value.replaceAll('.', '')) == null ||
                    double.parse(value.replaceAll('.', '')) <= 0) {
                  return 'Ingresa un monto válido y mayor a cero';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            if (_userAccounts.isNotEmpty)
              DropdownButtonFormField<String>(
                initialValue: _selectedAccountId,
                hint: const Text('Cuenta de Origen*'),
                items: _userAccounts.map((account) {
                  return DropdownMenuItem<String>(
                    value: account['id'],
                    child: Text(account['name']),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedAccountId = newValue;
                  });
                },
                validator: (value) => value == null ? 'Selecciona una cuenta' : null,
              ),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitFunds,
                    child: const Text('Añadir Fondos'),
                  ),
          ],
        ),
      ),
    );
  }
}
