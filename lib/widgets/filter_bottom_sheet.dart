import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mi_billetera_digital/main.dart';

class FilterBottomSheet extends StatefulWidget {
  final String? initialAccountId;
  final String? initialCategory;
  final DateTime? initialStartDate;
  final DateTime? initialEndDate;

  const FilterBottomSheet({
    super.key,
    this.initialAccountId,
    this.initialCategory,
    this.initialStartDate,
    this.initialEndDate,
  });

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  String? _selectedAccountId;
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;

  late final Future<List<Map<String, dynamic>>> _accountsFuture;
  late final Future<List<Map<String, dynamic>>> _categoriesFuture;

  @override
  void initState() {
    super.initState();
    _selectedAccountId = widget.initialAccountId;
    _selectedCategory = widget.initialCategory;
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;

    _accountsFuture = supabase.from('accounts').select();
    _categoriesFuture = supabase.from('categories').select().order('name');
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0).copyWith(bottom: MediaQuery.of(context).viewInsets.bottom + 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Filtros', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 24),
          _buildAccountsDropdown(),
          const SizedBox(height: 16),
          _buildCategoriesDropdown(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildDatePicker('Desde', _startDate, (date) => setState(() => _startDate = date))),
              const SizedBox(width: 16),
              Expanded(child: _buildDatePicker('Hasta', _endDate, (date) => setState(() => _endDate = date))),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedAccountId = null;
                    _selectedCategory = null;
                    _startDate = null;
                    _endDate = null;
                  });
                },
                child: const Text('Limpiar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop({
                    'accountId': _selectedAccountId,
                    'category': _selectedCategory,
                    'startDate': _startDate,
                    'endDate': _endDate,
                  });
                },
                child: const Text('Aplicar Filtros'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsDropdown() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _accountsFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final accounts = snapshot.data!;
        return DropdownButtonFormField<String>(
          value: _selectedAccountId,
          hint: const Text('Todas las cuentas'),
          isExpanded: true,
          onChanged: (value) {
            setState(() {
              _selectedAccountId = value;
            });
          },
          items: accounts.map((account) {
            return DropdownMenuItem<String>(
              value: account['id'].toString(),
              child: Text(account['name']),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildCategoriesDropdown() {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _categoriesFuture,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final categories = snapshot.data!;
        return DropdownButtonFormField<String>(
          value: _selectedCategory,
          hint: const Text('Todas las categorías'),
          isExpanded: true,
          onChanged: (value) {
            setState(() {
              _selectedCategory = value;
            });
          },
          items: categories.map((category) {
            return DropdownMenuItem<String>(
              value: category['name'],
              child: Text(category['name']),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildDatePicker(String label, DateTime? date, Function(DateTime) onDateChanged) {
    return InkWell(
      onTap: () async {
        final pickedDate = await showDatePicker(
          context: context,
          initialDate: date ?? DateTime.now(),
          firstDate: DateTime(2000),
          lastDate: DateTime.now(),
        );
        if (pickedDate != null) {
          onDateChanged(pickedDate);
        }
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        ),
        child: Text(date != null ? DateFormat.yMd('es_AR').format(date) : 'Seleccionar'),
      ),
    );
  }
}
