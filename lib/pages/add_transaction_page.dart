import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/app_theme.dart';
import 'package:mi_billetera_digital/utils/couple_mode_provider.dart';
import 'package:mi_billetera_digital/widgets/account_logo_widget.dart';
import 'package:mi_billetera_digital/pages/add_category_page.dart';
import 'package:mi_billetera_digital/pages/main_layout_page.dart';
import 'package:mi_billetera_digital/utils/currency_input_formatter.dart';
import 'package:provider/provider.dart';

class AddTransactionPage extends StatefulWidget {
  final Map<String, dynamic>? transaction;
  final String? initialType;

  const AddTransactionPage({super.key, this.transaction, this.initialType});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  String _selectedType = 'expense';
  String? _selectedAccountId;
  String _selectedCategory = 'Otros';

  bool _isLoading = false;
  bool get _isEditing => widget.transaction != null;
  String? _budgetWarning;
  Timer? _debounce;
  List<Map<String, dynamic>> _userAccounts = [];
  List<Map<String, dynamic>> _userCategories = [];
  CoupleModeProvider? _coupleModeProvider;
  bool _didInit = false;

  final String _addAccountValue = 'ADD_NEW_ACCOUNT';
  final String _addCategoryValue = 'ADD_NEW_CATEGORY';

  final Map<String, IconData> _iconMap = {
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

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType ?? 'expense';

    if (_isEditing) {
      final transaction = widget.transaction!;
      _descriptionController.text = transaction['description'];
      _amountController.text = transaction['amount'].toString();
      _selectedType = transaction['type'];
      _selectedCategory = transaction['category'];
      _selectedAccountId = transaction['account_id'];
    }
    _amountController.addListener(_onFormChanged);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_didInit) {
      _coupleModeProvider = Provider.of<CoupleModeProvider>(context);
      _loadInitialData();
      _didInit = true;
    }
  }

  Future<void> _loadInitialData() async {
    if (!mounted) return;
    final coupleModeProvider = _coupleModeProvider!;
    final userId = supabase.auth.currentUser!.id;

    dynamic accountsData;
    dynamic categoriesData;

    if (coupleModeProvider.isJointMode) {
      final coupleId = coupleModeProvider.coupleId!;
      accountsData = await supabase
          .from('accounts')
          .select('id, name')
          .or('user_id.eq.$userId,couple_id.eq.$coupleId');
      categoriesData = await supabase
          .from('categories')
          .select('id, name, icon, color')
          .or('user_id.eq.$userId,couple_id.eq.$coupleId');
    } else {
      accountsData = await supabase
          .from('accounts')
          .select('id, name')
          .eq('user_id', userId);
      categoriesData = await supabase
          .from('categories')
          .select('id, name, icon, color')
          .eq('user_id', userId);
    }

    if (mounted) {
      setState(() {
        _userAccounts = (accountsData as List).cast<Map<String, dynamic>>();
        _userCategories = (categoriesData as List).cast<Map<String, dynamic>>();
        if (!_isEditing && _userAccounts.length == 1) {
          _selectedAccountId = _userAccounts.first['id'];
        }
        if (_userCategories.isNotEmpty &&
            !_userCategories.any((c) => c['name'] == _selectedCategory)) {
          _selectedCategory = _userCategories.first['name'];
        }
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
      } else if (mounted) {
        setState(() => _budgetWarning = null);
      }
    });
  }

  Future<void> _checkBudgetStatus() async {
    if (!mounted) return;
    final coupleModeProvider = _coupleModeProvider!;

    final amountText = _amountController.text.replaceAll('.', '').replaceAll(',', '.');
    final amount = double.tryParse(amountText);

    if (amount == null || amount <= 0 || _selectedCategory == _addCategoryValue) {
      if (mounted) setState(() => _budgetWarning = null);
      return;
    }

    final category = _userCategories.firstWhere(
      (c) => c['name'] == _selectedCategory,
      orElse: () => {},
    );
    if (category.isEmpty) return;

    final categoryId = category['id'];
    final userId = supabase.auth.currentUser!.id;

    try {
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0, 23, 59, 59);

      var budgetQuery = supabase
          .from('budgets')
          .select('amount')
          .eq('category_id', categoryId)
          .gte('start_date', startOfMonth.toIso8601String())
          .lte('end_date', endOfMonth.toIso8601String());

      if (coupleModeProvider.isJointMode) {
        budgetQuery = budgetQuery.eq('couple_id', coupleModeProvider.coupleId!);
      } else {
        budgetQuery = budgetQuery.eq('user_id', userId);
      }

      final budgetRes = await budgetQuery.maybeSingle();

      if (budgetRes == null || budgetRes.isEmpty) {
        if (mounted) setState(() => _budgetWarning = null);
        return;
      }

      final budgetAmount = (budgetRes['amount'] as num).toDouble();

      var expensesQuery = supabase
          .from('transactions')
          .select('amount')
          .eq('category', _selectedCategory)
          .eq('type', 'expense')
          .gte('date', startOfMonth.toIso8601String())
          .lte('date', endOfMonth.toIso8601String());

      if (coupleModeProvider.isJointMode) {
        expensesQuery = expensesQuery.eq('couple_id', coupleModeProvider.coupleId!);
      } else {
        expensesQuery = expensesQuery.eq('user_id', userId);
      }

      final expensesRes = await expensesQuery;

      double currentSpent = 0.0;
      if (expensesRes.isNotEmpty) {
        currentSpent = expensesRes
            .map<double>((t) => (t['amount'] as num).toDouble())
            .fold(0.0, (prev, amount) => prev + amount);
      }

      final futureSpent = currentSpent + amount;
      final percentage = (futureSpent / budgetAmount) * 100;
      String? newWarning;

      if (percentage > 100) {
        newWarning =
            '¡Cuidado! Superarás tu presupuesto de \$${budgetAmount.toStringAsFixed(0)} para $_selectedCategory. Gastado: \$${currentSpent.toStringAsFixed(0)}.';
      } else if (percentage >= 80) {
        newWarning =
            'Alerta: Estás al ${percentage.toStringAsFixed(0)}% de tu presupuesto de \$${budgetAmount.toStringAsFixed(0)} para $_selectedCategory.';
      }

      if (mounted) {
        setState(() {
          _budgetWarning = newWarning;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _budgetWarning = null;
        });
      }
    }
  }

  Future<void> _submitTransaction() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      final selectedAccount = _userAccounts.firstWhere(
        (acc) => acc['id'] == _selectedAccountId,
      );

      try {
        final coupleModeProvider = _coupleModeProvider!;
        final data = {
          'description': _descriptionController.text.trim(),
          'amount': double.parse(_amountController.text.replaceAll('.', '')),
          'type': _selectedType,
          'category': _selectedCategory,
          'date': DateTime.now().toIso8601String(),
          'payment_method': selectedAccount['name'],
          'account_id': _selectedAccountId,
          'user_id': supabase.auth.currentUser!.id,
        };

        if (coupleModeProvider.isJointMode) {
          data['couple_id'] = coupleModeProvider.coupleId!;
        }

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
    final List<DropdownMenuItem<String>> accountItems = [];

    accountItems.addAll(
      _userAccounts.map((account) {
        return DropdownMenuItem<String>(
          value: account['id'],
          child: Row(
            children: [
              AccountLogoWidget(accountName: account['name'], iconPath: account['icon'] ?? '', size: 24),
              const SizedBox(width: 12),
              Text(account['name']),
            ],
          ),
        );
      }),
    );

    accountItems.add(
      const DropdownMenuItem<String>(enabled: false, child: Divider()),
    );
    accountItems.add(
      DropdownMenuItem<String>(
        value: _addAccountValue,
        child: const Row(
          children: [
            Icon(Icons.add, color: AppTheme.primaryColor),
            SizedBox(width: 12),
            Text(
              'Agregar nueva cuenta...',
              style: TextStyle(color: AppTheme.primaryColor),
            ),
          ],
        ),
      ),
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
              validator: (v) =>
                  (v == null || v.isEmpty) ? 'Ingresa una descripción' : null,
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
              inputFormatters: [CurrencyInputFormatter()],
              validator: (v) =>
                  (v == null || v.isEmpty || double.tryParse(v.replaceAll('.', '')) == null)
                  ? 'Ingresa un monto válido'
                  : null,
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
              value: _selectedAccountId,
              hint: const Text('Cuenta*'),
              items: accountItems,
              onChanged: (newValue) async {
                if (newValue == _addAccountValue) {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          const MainLayoutPage(initialPageIndex: 1),
                    ),
                  );
                  _loadInitialData();
                } else {
                  setState(() => _selectedAccountId = newValue);
                }
              },
              decoration: const InputDecoration(labelText: 'Cuenta'),
              validator: (v) => v == null ? 'Selecciona una cuenta' : null,
            ),
            const SizedBox(height: 24),
            DropdownButtonFormField<String>(
              value: _selectedCategory,
              items: [
                DropdownMenuItem<String>(
                  value: _addCategoryValue,
                  child: const Row(
                    children: [
                      Icon(Icons.add, color: AppTheme.primaryColor),
                      SizedBox(width: 12),
                      Text(
                        'Crear Nueva Categoría...',
                        style: TextStyle(color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                ),
                const DropdownMenuItem<String>(enabled: false, child: Divider()),
                ..._userCategories.map((category) {
                  return DropdownMenuItem<String>(
                    value: category['name'],
                    child: Row(
                      children: [
                        Icon(
                          _iconMap[category['icon']] ?? Icons.category,
                        color: Color(int.parse(category['color']?.substring(2) ?? 'FFFFFFFF', radix: 16)),
                        ),
                        const SizedBox(width: 12),
                        Text(category['name']),
                      ],
                    ),
                  );
                }),
              ],
              onChanged: (newValue) async {
                if (newValue == _addCategoryValue) {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => const AddCategoryPage(),
                    ),
                  );
                  _loadInitialData();
                } else {
                  setState(() {
                    _selectedCategory = newValue!;
                    _onFormChanged();
                  });
                }
              },
              decoration: const InputDecoration(labelText: 'Categoría'),
              menuMaxHeight: 350,
              icon: const Icon(Icons.arrow_downward),
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _userAccounts.isEmpty
                        ? null
                        : _submitTransaction,
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