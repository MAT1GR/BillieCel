import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/utils/currency_input_formatter.dart';
import 'package:mi_billetera_digital/utils/couple_mode_provider.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AddSavingsGoalPage extends StatefulWidget {
  const AddSavingsGoalPage({super.key, required Map<String, dynamic> goal});

  @override
  State<AddSavingsGoalPage> createState() => _AddSavingsGoalPageState();
}

class _AddSavingsGoalPageState extends State<AddSavingsGoalPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitGoal() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final userId = supabase.auth.currentUser!.id;
        final coupleModeProvider = context.read<CoupleModeProvider>();

        final data = {
          'name': _nameController.text.trim(),
          'target_amount': double.parse(_amountController.text.replaceAll('.', '')),
          'current_amount': 0.0, // New goals start with 0 current amount
        };

        if (coupleModeProvider.isJointMode) {
          data['couple_id'] = coupleModeProvider.coupleId!;
          data['user_id'] = userId; // Still associate with user for RLS/tracking
        } else {
          data['user_id'] = userId;
        }

        await supabase.from('savings_goals').insert(data);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Meta de ahorro creada con éxito')),
          );
          Navigator.of(context).pop();
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Error al crear la meta'),
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
      appBar: AppBar(title: const Text('Nueva Meta de Ahorro')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'Nombre de la Meta'),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Por favor, ingresa un nombre';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Monto Objetivo',
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
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
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitGoal,
                    child: const Text('Crear Meta'),
                  ),
          ],
        ),
      ),
    );
  }
}

