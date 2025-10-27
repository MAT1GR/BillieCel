import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/models/debt_model.dart';
import 'package:mi_billetera_digital/utils/currency_input_formatter.dart';
import 'package:mi_billetera_digital/utils/couple_mode_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddDebtPage extends StatefulWidget {
  final DebtType? initialDebtType;
  final Map<String, dynamic>? debt;

  const AddDebtPage({super.key, this.initialDebtType, this.debt});

  @override
  State<AddDebtPage> createState() => _AddDebtPageState();
}

class _AddDebtPageState extends State<AddDebtPage> {
  final _formKey = GlobalKey<FormState>();
  DebtType _debtType = DebtType.owed;
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime? _dueDate;

  @override
  void initState() {
    super.initState();
    if (widget.initialDebtType != null) {
      _debtType = widget.initialDebtType!;
    }
    if (widget.debt != null) {
      final debt = widget.debt!;
      _nameController.text = debt['person_name'];
      _amountController.text = (debt['original_amount'] as num).toString();
      _descriptionController.text = debt['description'] ?? '';
      _dueDate = debt['due_date'] != null ? DateTime.parse(debt['due_date']) : null;
      _debtType = (debt['amount'] as num) > 0 ? DebtType.owed : DebtType.owing;
    }
  }

  Future<void> _saveDebt() async {
    if (_formKey.currentState!.validate()) {
      final amount = double.parse(_amountController.text.replaceAll('.', ''));
      final finalAmount = _debtType == DebtType.owed ? amount : -amount;

      final userId = supabase.auth.currentUser!.id;
      final coupleModeProvider = context.read<CoupleModeProvider>();

      try {
        final data = {
          'person_name': _nameController.text,
          'amount': finalAmount,
          'original_amount': amount,
          'description': _descriptionController.text,
          'due_date': _dueDate?.toIso8601String(),
          'is_paid': false,
        };

        if (coupleModeProvider.isJointMode) {
          data['couple_id'] = coupleModeProvider.coupleId!;
          data['user_id'] = userId; // Still associate with user for RLS/tracking
        } else {
          data['user_id'] = userId;
        }

        if (widget.debt != null) {
          PostgrestFilterBuilder updateQuery = supabase.from('debts').update(data).match({'id': widget.debt!['id']});
          if (coupleModeProvider.isJointMode) {
            updateQuery = updateQuery.eq('couple_id', coupleModeProvider.coupleId!); // Ensure updating correct couple debt
          } else {
            updateQuery = updateQuery.eq('user_id', userId); // Ensure updating correct personal debt
          }
          await updateQuery;
        } else {
          await supabase.from('debts').insert(data);
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Deuda guardada correctamente')),
          );
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error al guardar la deuda: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Añadir Deuda'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            SegmentedButton<DebtType>(
              segments: const [
                ButtonSegment(value: DebtType.owed, label: Text('Me Deben')),
                ButtonSegment(value: DebtType.owing, label: Text('Debo')),
              ],
              selected: {_debtType},
              onSelectionChanged: (newSelection) {
                setState(() {
                  _debtType = newSelection.first;
                });
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Persona'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, ingresa un nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(labelText: 'Monto'),
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
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
            const SizedBox(height: 20),
            ListTile(
              title: const Text('Fecha de Vencimiento'),
              subtitle: Text(_dueDate == null
                  ? 'Opcional'
                  : '${_dueDate!.day}/${_dueDate!.month}/${_dueDate!.year}'),
              trailing: const Icon(Icons.calendar_today),
              onTap: () async {
                final pickedDate = await showDatePicker(
                  context: context,
                  initialDate: _dueDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(2101),
                );
                if (pickedDate != null) {
                  setState(() {
                    _dueDate = pickedDate;
                  });
                }
              },
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveDebt,
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }
}
