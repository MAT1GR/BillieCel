import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mi_billetera_digital/main.dart'; // Import supabase instance
import 'package:mi_billetera_digital/utils/couple_mode_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddRecurringTransactionPage extends StatefulWidget {
  final Map<String, dynamic>? recurringTransaction;

  const AddRecurringTransactionPage({super.key, this.recurringTransaction});

  @override
  State<AddRecurringTransactionPage> createState() => _AddRecurringTransactionPageState();
}

class _AddRecurringTransactionPageState extends State<AddRecurringTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  String? _type; // income or expense
  double? _amount;
  String? _description;
  String? _selectedCategory;
  String? _selectedAccountId;
  String? _frequency; // e.g., 'daily', 'weekly', 'monthly', 'yearly'
  DateTime? _startDate;
  DateTime? _endDate;

  Future<List<Map<String, dynamic>>>? _accountsFuture;
  Future<List<Map<String, dynamic>>>? _categoriesFuture;
  bool _futuresInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_futuresInitialized) {
      _accountsFuture = _fetchAccounts();
      _categoriesFuture = _fetchCategories();
      _futuresInitialized = true;
    }
  }

  @override
  void initState() {
    super.initState();

    if (widget.recurringTransaction != null) {
      _type = widget.recurringTransaction!['type'];
      _amount = (widget.recurringTransaction!['amount'] as num).toDouble();
      _description = widget.recurringTransaction!['description'];
      _selectedCategory = widget.recurringTransaction!['category'];
      _selectedAccountId = widget.recurringTransaction!['account_id'];
      _frequency = widget.recurringTransaction!['frequency'];
      _startDate = DateTime.parse(widget.recurringTransaction!['start_date']);
      if (widget.recurringTransaction!['end_date'] != null) {
        _endDate = DateTime.parse(widget.recurringTransaction!['end_date']);
      }
    } else {
      _startDate = DateTime.now(); // Default start date to today for new transactions
    }
  }

  Future<List<Map<String, dynamic>>> _fetchAccounts() async {
    final userId = supabase.auth.currentUser!.id;
    final coupleModeProvider = context.read<CoupleModeProvider>();

    var queryBuilder = supabase.from('accounts').select('id, name');

    if (coupleModeProvider.isJointMode) {
      final coupleId = coupleModeProvider.coupleId!;
      queryBuilder = queryBuilder.or('user_id.eq.$userId,couple_id.eq.$coupleId');
    } else {
      queryBuilder = queryBuilder.eq('user_id', userId);
    }
    return await queryBuilder.order('name');
  }

  Future<List<Map<String, dynamic>>> _fetchCategories() async {
    final userId = supabase.auth.currentUser!.id;
    final coupleModeProvider = context.read<CoupleModeProvider>();

    var queryBuilder = supabase.from('categories').select('name');

    if (coupleModeProvider.isJointMode) {
      final coupleId = coupleModeProvider.coupleId!;
      queryBuilder = queryBuilder.or('user_id.eq.$userId,couple_id.eq.$coupleId');
    } else {
      queryBuilder = queryBuilder.eq('user_id', userId);
    }
    return await queryBuilder.order('name');
  }

  Future<void> _saveRecurringTransaction() async {
    if (_formKey.currentState!.validate()) {
      _formKey.currentState!.save();

      if (_type == null || _amount == null || _description == null || _selectedCategory == null || _selectedAccountId == null || _frequency == null || _startDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, completa todos los campos requeridos.')),
        );
        return;
      }

      try {
        final userId = supabase.auth.currentUser!.id;
        final coupleModeProvider = context.read<CoupleModeProvider>();

        final transactionData = {
          'type': _type,
          'amount': _amount,
          'description': _description,
          'category': _selectedCategory,
          'account_id': _selectedAccountId,
          'frequency': _frequency,
          'start_date': _startDate!.toIso8601String(),
          'end_date': _endDate?.toIso8601String(),
          'next_occurrence_date': _startDate!.toIso8601String(), // Re-initialize next occurrence on save/update
        };

        if (coupleModeProvider.isJointMode) {
          transactionData['couple_id'] = coupleModeProvider.coupleId!;
          transactionData['user_id'] = userId; // Still associate with user for RLS/tracking
        } else {
          transactionData['user_id'] = userId;
        }

        if (widget.recurringTransaction == null) {
          // Add new recurring transaction
          await supabase.from('recurring_transactions').insert(transactionData);

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Transacción recurrente guardada con éxito!')),
            );
            Navigator.of(context).pop();
          }
        } else {
          // Update existing recurring transaction
          PostgrestFilterBuilder updateQuery = supabase.from('recurring_transactions').update(transactionData).eq('id', widget.recurringTransaction!['id']);
          if (coupleModeProvider.isJointMode) {
            updateQuery = updateQuery.eq('couple_id', coupleModeProvider.coupleId!); // Ensure updating correct couple recurring transaction
          } else {
            updateQuery = updateQuery.eq('user_id', userId); // Ensure updating correct personal recurring transaction
          }
          await updateQuery;

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Transacción recurrente actualizada con éxito!')),
            );
            Navigator.of(context).pop();
          }
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar/actualizar transacción recurrente: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.recurringTransaction == null
            ? 'Añadir Transacción Recurrente'
            : 'Editar Transacción Recurrente'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: FutureBuilder<List<List<Map<String, dynamic>>>>(
            future: Future.wait([_accountsFuture!, _categoriesFuture!]),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Error al cargar datos: ${snapshot.error}'));
              }
              if (!snapshot.hasData || snapshot.data![0].isEmpty || snapshot.data![1].isEmpty) {
                return const Center(child: Text('No hay cuentas o categorías disponibles. Por favor, crea algunas primero.'));
              }

              final accounts = snapshot.data![0];
              final categories = snapshot.data![1];

              return ListView(
                children: [
                  // Type selection (Income/Expense)
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    value: _type,
                    items: const [
                      DropdownMenuItem(value: 'income', child: Text('Ingreso')),
                      DropdownMenuItem(value: 'expense', child: Text('Egreso')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _type = value;
                      });
                    },
                    validator: (value) => value == null ? 'Selecciona un tipo' : null,
                  ),
                  const SizedBox(height: 16),

                  // Amount
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                    keyboardType: TextInputType.number,
                    initialValue: _amount?.toString(), // Set initial value
                    onSaved: (value) => _amount = double.tryParse(value ?? ''),
                    validator: (value) =>
                        value == null || double.tryParse(value) == null
                            ? 'Introduce una cantidad válida'
                            : null,
                  ),
                  const SizedBox(height: 16),

                  // Description
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Descripción'),
                    initialValue: _description, // Set initial value
                    onSaved: (value) => _description = value,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Introduce una descripción' : null,
                  ),
                  const SizedBox(height: 16),

                  // Category
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    value: _selectedCategory,
                    items: categories.map((category) {
                      return DropdownMenuItem<String>(
                        value: category['name'] as String,
                        child: Text(category['name'] as String),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategory = value;
                      });
                    },
                    validator: (value) => value == null ? 'Selecciona una categoría' : null,
                  ),
                  const SizedBox(height: 16),

                  // Account
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Cuenta'),
                    value: _selectedAccountId,
                    items: accounts.map((account) {
                      return DropdownMenuItem(
                        value: account['id'].toString(),
                        child: Text(account['name']),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedAccountId = value;
                      });
                    },
                    validator: (value) => value == null ? 'Selecciona una cuenta' : null,
                  ),
                  const SizedBox(height: 16),

                  // Frequency
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Frecuencia'),
                    value: _frequency,
                    items: const [
                      DropdownMenuItem(value: 'daily', child: Text('Diaria')),
                      DropdownMenuItem(value: 'weekly', child: Text('Semanal')),
                      DropdownMenuItem(value: 'monthly', child: Text('Mensual')),
                      DropdownMenuItem(value: 'yearly', child: Text('Anual')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _frequency = value;
                      });
                    },
                    validator: (value) => value == null ? 'Selecciona una frecuencia' : null,
                  ),
                  const SizedBox(height: 16),

                  // Start Date
                  ListTile(
                    title: Text('Fecha de Inicio: ${_startDate == null ? '' : DateFormat.yMd().format(_startDate!)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null && picked != _startDate) {
                        setState(() {
                          _startDate = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  // End Date (Optional)
                  ListTile(
                    title: Text('Fecha de Fin (Opcional): ${_endDate == null ? '' : DateFormat.yMd().format(_endDate!)}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate ?? DateTime.now(),
                        firstDate: DateTime(2000),
                        lastDate: DateTime(2101),
                      );
                      if (picked != null && picked != _endDate) {
                        setState(() {
                          _endDate = picked;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  ElevatedButton(
                    onPressed: _saveRecurringTransaction,
                    child: Text(widget.recurringTransaction == null
                        ? 'Guardar Transacción Recurrente'
                        : 'Guardar Cambios'),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}