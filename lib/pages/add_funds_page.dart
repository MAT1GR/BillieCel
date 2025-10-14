import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/main.dart';

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
        final newAmount =
            (widget.goal['current_amount'] as num) +
            double.parse(_amountController.text);
        await supabase
            .from('savings_goals')
            .update({'current_amount': newAmount})
            .match({'id': widget.goal['id']});

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fondos añadidos con éxito')),
          );
          Navigator.of(context).pop();
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Error al añadir fondos'),
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
      appBar: AppBar(title: Text('Añadir Fondos a "${widget.goal['name']}"')),
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
              validator: (value) {
                if (value == null ||
                    value.isEmpty ||
                    double.tryParse(value) == null ||
                    double.parse(value) <= 0) {
                  return 'Ingresa un monto válido y mayor a cero';
                }
                return null;
              },
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
