// lib/pages/add_transaction_page.dart
import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/main.dart';

class AddTransactionPage extends StatefulWidget {
  // 1. Aceptará una transacción opcional para editar
  final Map<String, dynamic>? transaction;

  const AddTransactionPage({super.key, this.transaction});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();
  String _selectedType = 'egreso';
  String _selectedCategory = 'Otros';
  bool _isLoading = false;
  bool get _isEditing =>
      widget.transaction != null; // Saber si estamos en modo edición

  final List<String> _categories = [
    'Comida',
    'Transporte',
    'Vivienda',
    'Suscripciones',
    'Ocio',
    'Salud',
    'Sueldo',
    'Otros',
  ];

  @override
  void initState() {
    super.initState();
    // 2. Si estamos editando, llenamos el formulario con los datos existentes
    if (_isEditing) {
      final transaction = widget.transaction!;
      _descriptionController.text = transaction['description'];
      _amountController.text = transaction['amount'].toString();
      _selectedType = transaction['type'];
      _selectedCategory = transaction['category'];
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
        final userId = supabase.auth.currentUser!.id;

        final data = {
          'description': description,
          'amount': amount,
          'type': _selectedType,
          'category': _selectedCategory,
          'transaction_date': DateTime.now().toIso8601String(),
          'user_id': userId,
        };

        if (_isEditing) {
          // 3. Si editamos, hacemos un "update" en lugar de "insert"
          await supabase.from('transactions').update(data).match({
            'id': widget.transaction!['id'],
          });
        } else {
          await supabase.from('transactions').insert(data);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Transacción guardada con éxito')),
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
        // 4. El título cambia si estamos editando
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
            const SizedBox(height: 16),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Monto',
                prefixText: '\$ ',
              ),
              keyboardType: TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value == null ||
                    value.isEmpty ||
                    double.tryParse(value) == null) {
                  return 'Por favor, ingresa un monto válido';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedType,
              items: ['egreso', 'ingreso'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value == 'egreso' ? 'Egreso' : 'Ingreso'),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedType = newValue!;
                });
              },
              decoration: const InputDecoration(labelText: 'Tipo'),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              items: _categories.map((String category) {
                return DropdownMenuItem<String>(
                  value: category,
                  child: Text(category),
                );
              }).toList(),
              onChanged: (newValue) {
                setState(() {
                  _selectedCategory = newValue!;
                });
              },
              decoration: const InputDecoration(labelText: 'Categoría'),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitTransaction,
                    child: const Text('Guardar Transacción'),
                  ),
          ],
        ),
      ),
    );
  }
}
