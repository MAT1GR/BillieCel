import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/main.dart';

class AddBudgetPage extends StatefulWidget {
  const AddBudgetPage({super.key, required Map<String, dynamic> budget});

  @override
  State<AddBudgetPage> createState() => _AddBudgetPageState();
}

class _AddBudgetPageState extends State<AddBudgetPage> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  String? _selectedCategory;
  bool _isLoading = false;

  List<Map<String, dynamic>> _userCategories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final categoriesData = await supabase
        .from('categories')
        .select('name, icon, color')
        .eq('type', 'expense'); // Only expense categories for budgets
    if (mounted) {
      setState(() {
        _userCategories = (categoriesData as List).cast<Map<String, dynamic>>();
      });
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _submitBudget() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      try {
        final now = DateTime.now();
        await supabase.from('budgets').insert({
          'category': _selectedCategory,
          'amount': double.parse(_amountController.text),
          'month': now.month,
          'year': now.year,
          'user_id': supabase.auth.currentUser!.id,
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Presupuesto guardado con éxito')),
          );
          Navigator.of(context).pop();
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                'Error: Es posible que ya exista un presupuesto para esta categoría este mes.',
              ),
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
    // This is needed to map string icon names to IconData
    final Map<String, IconData> iconMap = {
      'category': Icons.category,
      'fastfood': Icons.fastfood,
      'directions_bus': Icons.directions_bus,
      'hotel': Icons.hotel,
      'healing': Icons.healing,
      'theaters': Icons.theaters,
      'shopping_cart': Icons.shopping_cart,
      'home': Icons.home,
      'school': Icons.school,
      'pets': Icons.pets,
      'fitness_center': Icons.fitness_center,
      'card_giftcard': Icons.card_giftcard,
      'attach_money': Icons.attach_money,
      'savings': Icons.savings,
      'lightbulb': Icons.lightbulb,
      'receipt': Icons.receipt,
      'build': Icons.build,
      'flight': Icons.flight,
    };

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo Presupuesto')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            if (_userCategories.isEmpty)
              const Center(child: CircularProgressIndicator())
            else
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                hint: const Text('Selecciona una categoría'),
                items: _userCategories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category['name'],
                    child: Row(
                      children: [
                        Icon(
                          iconMap[category['icon']] ?? Icons.category,
                          color: Color(int.parse(category['color']?.substring(2) ?? 'FFFFFFFF', radix: 16)),
                        ),
                        const SizedBox(width: 12),
                        Text(category['name']),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                },
                decoration: const InputDecoration(labelText: 'Categoría'),
                validator: (value) =>
                    value == null ? 'Por favor, selecciona una categoría' : null,
              ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Monto Límite',
                prefixText: '\$ ',
              ),
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              validator: (value) {
                if (value == null ||
                    value.isEmpty ||
                    double.tryParse(value) == null ||
                    double.parse(value) <= 0) {
                  return 'Por favor, ingresa un monto válido y mayor a cero';
                }
                return null;
              },
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _submitBudget,
                    child: const Text('Guardar Presupuesto'),
                  ),
          ],
        ),
      ),
    );
  }
}
