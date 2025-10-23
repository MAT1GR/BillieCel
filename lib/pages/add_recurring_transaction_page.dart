import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mi_billetera_digital/main.dart'; // Import supabase instance

class AddRecurringTransactionPage extends StatefulWidget {
  const AddRecurringTransactionPage({super.key});

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

  late Future<List<Map<String, dynamic>>> _accountsFuture;
  late Future<List<Map<String, dynamic>>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _accountsFuture = _fetchAccounts();
    _categoriesFuture = _fetchCategories();
    _startDate = DateTime.now(); // Default start date to today
  }

  Future<List<Map<String, dynamic>>> _fetchAccounts() async {
    final userId = supabase.auth.currentUser!.id;
    return await supabase.from('accounts').select().eq('user_id', userId).order('name');
  }

  Future<List<Map<String, dynamic>>> _fetchCategories() async {
    final userId = supabase.auth.currentUser!.id;
    return await supabase.from('categories').select().eq('user_id', userId).order('name');
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
        await supabase.from('recurring_transactions').insert({
          'user_id': userId,
          'type': _type,
          'amount': _amount,
          'description': _description,
          'category': _selectedCategory,
          'account_id': _selectedAccountId,
          'frequency': _frequency,
          'start_date': _startDate!.toIso8601String(),
          'end_date': _endDate?.toIso8601String(),
          'next_occurrence_date': _startDate!.toIso8601String(), // Initialize with start date
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transacción recurrente guardada con éxito!')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar transacción recurrente: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Transacción Recurrente'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: FutureBuilder<List<List<Map<String, dynamic>>>>(
            future: Future.wait([_accountsFuture, _categoriesFuture]),
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
                    initialValue: _type,
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
                    onSaved: (value) => _description = value,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Introduce una descripción' : null,
                  ),
                  const SizedBox(height: 16),

                  // Category
                  DropdownButtonFormField<String>(
                    decoration: const InputDecoration(labelText: 'Categoría'),
                    initialValue: _selectedCategory,
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
                    initialValue: _selectedAccountId,
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
                    initialValue: _frequency,
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
                    child: const Text('Guardar Transacción Recurrente'),
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
