import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/app_theme.dart';

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
  final _otherPaymentMethodController = TextEditingController();
  String _selectedType = 'expense';
  String _selectedCategory = 'Otros';
  String _selectedPaymentMethod = 'Efectivo';
  bool _isLoading = false;
  bool get _isEditing => widget.transaction != null;

  String? _budgetWarning;
  Timer? _debounce;

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

  final List<String> _paymentMethods = [
    'Efectivo',
    'Mercado Pago',
    'Banco',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    if (_isEditing) {
      final transaction = widget.transaction!;
      _descriptionController.text = transaction['description'];
      _amountController.text = transaction['amount'].toString();
      _selectedType = transaction['type'];
      _selectedCategory = transaction['category'];

      final existingMethod = transaction['payment_method'] as String?;
      if (existingMethod != null && _paymentMethods.contains(existingMethod)) {
        _selectedPaymentMethod = existingMethod;
      } else if (existingMethod != null) {
        _selectedPaymentMethod = 'Otro';
        _otherPaymentMethodController.text = existingMethod;
      }
    }
    _amountController.addListener(_onFormChanged);
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.removeListener(_onFormChanged);
    _amountController.dispose();
    _otherPaymentMethodController.dispose();
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

      double currentSpent = 0;
      if (expensesResponse.isNotEmpty) {
        currentSpent = (expensesResponse as List).fold<double>(
          0,
          (sum, t) => sum + ((t['amount'] as num?)?.toDouble() ?? 0.0),
        );
      }

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
      setState(() {
        _isLoading = true;
      });
      try {
        final amount = double.parse(_amountController.text);
        final description = _descriptionController.text;
        final finalPaymentMethod = _selectedPaymentMethod == 'Otro'
            ? _otherPaymentMethodController.text.trim()
            : _selectedPaymentMethod;

        final data = {
          'description': description,
          'amount': amount,
          'type': _selectedType,
          'category': _selectedCategory,
          'date': DateTime.now().toIso8601String(),
          'payment_method': finalPaymentMethod,
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
              content: const Text('Error al guardar la transacción'),
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
              decoration: const InputDecoration(labelText: 'Descripción'),
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
                labelText: 'Monto',
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
            if (_budgetWarning != null)
              Padding(
                padding: const EdgeInsets.only(top: 16.0),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.warning_amber_rounded,
                        color: Colors.orange.shade800,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _budgetWarning!,
                          style: TextStyle(
                            color: Colors.orange.shade900,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
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
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedPaymentMethod,
              items: _paymentMethods.map((String method) {
                return DropdownMenuItem<String>(
                  value: method,
                  child: Text(method),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedPaymentMethod = newValue!;
                });
              },
              decoration: const InputDecoration(labelText: 'Método de Pago'),
            ),
            if (_selectedPaymentMethod == 'Otro')
              Padding(
                padding: const EdgeInsets.only(top: 24.0),
                child: TextFormField(
                  controller: _otherPaymentMethodController,
                  decoration: const InputDecoration(
                    labelText: 'Especificar otro método',
                  ),
                  validator: (value) {
                    if (_selectedPaymentMethod == 'Otro' &&
                        (value == null || value.isEmpty)) {
                      return 'Por favor, especifica el método';
                    }
                    return null;
                  },
                ),
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
