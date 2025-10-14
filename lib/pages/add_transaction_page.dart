import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/app_theme.dart';
import 'package:mi_billetera_digital/widgets/account_logo_widget.dart';

class AddTransactionPage extends StatefulWidget {
  final Map<String, dynamic>? transaction;
  const AddTransactionPage({super.key, this.transaction});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedType = 'expense';
  String _selectedCategory = 'Otros';
  String?
  _selectedPaymentValue; // Valor unificado (ej: "account_id" o "Efectivo")

  bool _isLoading = false;
  bool get _isEditing => widget.transaction != null;
  String? _budgetWarning;
  Timer? _debounce;
  List<Map<String, dynamic>> _userAccounts = [];

  // Lista de métodos de pago genéricos
  final List<String> _genericPaymentMethods = [
    'Efectivo',
    'Transferencia',
    'Otro',
  ];

  final List<String> _categories = [
    'Comida',
    'Transporte',
    'Vivienda',
    'Suscripciones',
    'Ocio',
    'Salud',
    'Sueldo',
    'Otros',
    'Alimentación',
    'Entretenimiento',
    'Educación',
    'Servicios',
    'Inversiones',
  ];

  @override
  void initState() {
    super.initState();
    _loadInitialData();

    if (_isEditing) {
      final transaction = widget.transaction!;
      _descriptionController.text = transaction['description'];
      _amountController.text = transaction['amount'].toString();
      _selectedType = transaction['type'];
      _selectedCategory = transaction['category'];

      if (transaction['account_id'] != null) {
        _selectedPaymentValue = transaction['account_id'];
      } else {
        _selectedPaymentValue = transaction['payment_method'];
      }
    }
    _amountController.addListener(_onFormChanged);
  }

  Future<void> _loadInitialData() async {
    final accountsData = await supabase.from('accounts').select('id, name');
    if (mounted) {
      setState(() {
        _userAccounts = (accountsData as List).cast<Map<String, dynamic>>();
      });
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.removeListener(_onFormChanged);
    _amountController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onFormChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (_selectedType == 'expense' && _amountController.text.isNotEmpty) {
        _checkBudgetStatus();
      } else {
        if (mounted) {
          setState(() {
            _budgetWarning = null;
          });
        }
      }
    });
  }

  Future<void> _checkBudgetStatus() async {
    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    final now = DateTime.now();
    try {
      final budgetResponse = await supabase
          .from('budgets')
          .select('amount')
          .eq('category', _selectedCategory)
          .eq('month', now.month)
          .eq('year', now.year)
          .maybeSingle();

      if (budgetResponse == null) {
        if (mounted) setState(() => _budgetWarning = null);
        return;
      }

      final budgetAmount = (budgetResponse['amount'] as num).toDouble();
      final firstDayOfMonth = DateTime(now.year, now.month, 1);
      final expensesResponse = await supabase
          .from('transactions')
          .select('amount')
          .eq('type', 'expense')
          .eq('category', _selectedCategory)
          .gte('date', firstDayOfMonth.toIso8601String());

      double currentSpent = (expensesResponse as List).fold<double>(
        0,
        (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0.0),
      );

      if (currentSpent + amount > budgetAmount) {
        if (mounted) {
          setState(() {
            _budgetWarning =
                '¡Atención! Este gasto superará tu presupuesto de \$${budgetAmount.toStringAsFixed(0)} para "$_selectedCategory".';
          });
        }
      } else {
        if (mounted) setState(() => _budgetWarning = null);
      }
    } catch (error) {
      if (mounted) setState(() => _budgetWarning = null);
    }
  }

  Future<void> _submitTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      String? accountId;
      String paymentMethod;

      if (_userAccounts.any((acc) => acc['id'] == _selectedPaymentValue)) {
        final account = _userAccounts.firstWhere(
          (acc) => acc['id'] == _selectedPaymentValue,
        );
        accountId = account['id'];
        paymentMethod = account['name'];
      } else {
        accountId = null;
        paymentMethod = _selectedPaymentValue!;
      }

      try {
        final data = {
          'description': _descriptionController.text.trim(),
          'amount': double.parse(_amountController.text),
          'type': _selectedType,
          'category': _selectedCategory,
          'date': DateTime.now().toIso8601String(),
          'payment_method': paymentMethod,
          'account_id': accountId,
          'user_id': supabase.auth.currentUser!.id,
        };

        if (_isEditing) {
          await supabase.from('transactions').update(data).match({
            'id': widget.transaction!['id'],
          });
        } else {
          await supabase.from('transactions').insert(data);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transacción guardada con éxito')),
          );
          Navigator.of(context).pop();
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error al guardar: $error'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final List<DropdownMenuItem<String>> paymentItems = [];

    paymentItems.addAll(
      _userAccounts.map((account) {
        return DropdownMenuItem<String>(
          value: account['id'],
          child: Row(
            children: [
              AccountLogoWidget(accountName: account['name'], size: 24),
              const SizedBox(width: 12),
              Text(account['name']),
            ],
          ),
        );
      }),
    );

    if (_userAccounts.isNotEmpty) {
      paymentItems.add(
        const DropdownMenuItem<String>(enabled: false, child: Divider()),
      );
    }

    paymentItems.addAll(
      _genericPaymentMethods.map((method) {
        return DropdownMenuItem<String>(
          value: method,
          child: Row(
            children: [
              AccountLogoWidget(accountName: method, size: 24),
              const SizedBox(width: 12),
              Text(method),
            ],
          ),
        );
      }),
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Editar Transacción' : 'Nueva Transacción'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descripción*'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, ingresa una descripción';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Monto*',
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null ||
                    value.isEmpty ||
                    double.tryParse(value) == null) {
                  return 'Por favor, ingresa un monto válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedPaymentValue,
              hint: const Text('Método de Pago / Cuenta*'),
              items: paymentItems,
              onChanged: (newValue) {
                setState(() => _selectedPaymentValue = newValue);
              },
              decoration: const InputDecoration(
                labelText: 'Método de Pago / Cuenta',
              ),
              validator: (value) =>
                  value == null ? 'Selecciona una opción' : null,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedType,
              items: ['expense', 'income'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value == 'expense' ? 'Egreso' : 'Ingreso'),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedType = newValue!;
                  _onFormChanged();
                });
              },
              decoration: const InputDecoration(labelText: 'Tipo'),
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: _categories.toSet().toList().map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                  _onFormChanged();
                });
              },
              decoration: const InputDecoration(labelText: 'Categoría'),
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitTransaction,
                    child: Text(
                      _isEditing ? 'Guardar Cambios' : 'Guardar Transacción',
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
