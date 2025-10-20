import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'dart:async';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/pages/add_transaction_page.dart';
import 'package:mi_billetera_digital/app_theme.dart';
import 'package:mi_billetera_digital/widgets/loading_shimmer.dart';
import 'package:mi_billetera_digital/widgets/my_app_bar.dart';
import 'package:mi_billetera_digital/widgets/financial_summary_card.dart';
import 'package:mi_billetera_digital/pages/analysis_page.dart';
import 'package:mi_billetera_digital/widgets/transaction_list_item.dart';

class TransactionsPage extends StatefulWidget {
  const TransactionsPage({super.key});

  @override
  State<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends State<TransactionsPage> {
  final _searchController = TextEditingController();
  Timer? _debounce;

  // Filter state
  String? _searchQuery;
  String? _selectedAccountId;
  String? _selectedCategory;
  DateTime? _startDate;
  DateTime? _endDate;

  // Streams
  late Stream<List<Map<String, dynamic>>> _transactionsStream;
  late Stream<List<Map<String, dynamic>>> _accountsStream;
  StreamSubscription? _transactionsSubscription;
  StreamSubscription? _accountsSubscription;

  // Notifiers
  final _summaryNotifier = ValueNotifier<FinancialSummaryData>(
    FinancialSummaryData(),
  );
  final _transactionsNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);
  final _accountsNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);

  final currencyFormat = NumberFormat.currency(locale: 'es_AR', symbol: '\$ ');

  @override
  void initState() {
    super.initState();
    _resetAndBuildStreams();

    _searchController.addListener(() {
      if (_debounce?.isActive ?? false) _debounce!.cancel();
      _debounce = Timer(const Duration(milliseconds: 500), () {
        if (_searchQuery != _searchController.text) {
          setState(() {
            _searchQuery = _searchController.text.trim();
            _resetAndBuildStreams();
          });
        }
      });
    });
  }

  void _resetAndBuildStreams() {
    _transactionsSubscription?.cancel();
    _accountsSubscription?.cancel();

    _transactionsStream = _buildTransactionsStream();
    _accountsStream = supabase
        .from('accounts')
        .stream(primaryKey: ['id'])
        .order('name');

    _transactionsSubscription = _transactionsStream.listen((transactions) {
      _transactionsNotifier.value = transactions;
      _recalculateSummary();
    });

    _accountsSubscription = _accountsStream.listen((accounts) {
      _accountsNotifier.value = accounts;
      _recalculateSummary();
    });
  }

  Stream<List<Map<String, dynamic>>> _buildTransactionsStream() {
    dynamic query = supabase.from('transactions').stream(primaryKey: ['id']);

    if (_searchQuery != null && _searchQuery!.isNotEmpty) {
      query = query.ilike('description', '%$_searchQuery%');
    }
    if (_selectedAccountId != null) {
      query = query.eq('account_id', _selectedAccountId!);
    }
    if (_selectedCategory != null) {
      query = query.eq('category', _selectedCategory!);
    }
    if (_startDate != null) {
      query = query.gte('date', _startDate!.toIso8601String());
    }
    if (_endDate != null) {
      query = query.lte(
        'date',
        _endDate!.add(const Duration(days: 1)).toIso8601String(),
      );
    }

    return query.order('date', ascending: false);
  }

  @override
  void dispose() {
    _transactionsSubscription?.cancel();
    _accountsSubscription?.cancel();
    _summaryNotifier.dispose();
    _transactionsNotifier.dispose();
    _accountsNotifier.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _recalculateSummary() {
    final transactions = _transactionsNotifier.value;
    final accounts = _accountsNotifier.value;

    double totalIngresos = 0;
    double totalEgresos = 0;
    final Map<String, double> expenseByCategory = {};

    for (var t in transactions) {
      final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
      if (t['type'] == 'income') {
        totalIngresos += amount;
      } else {
        totalEgresos += amount;
        final category = t['category'] as String;
        expenseByCategory[category] =
            (expenseByCategory[category] ?? 0) + amount;
      }
    }

    double totalBalance = 0;
    double cashBalance = 0;
    double virtualBalance = 0;

    for (var acc in accounts) {
      final balance = (acc['balance'] as num?)?.toDouble() ?? 0.0;
      totalBalance += balance;
      if ((acc['name'] as String).toLowerCase() == 'efectivo') {
        cashBalance += balance;
      } else {
        virtualBalance += balance;
      }
    }

    _summaryNotifier.value = FinancialSummaryData(
      totalIngresos: totalIngresos,
      totalEgresos: totalEgresos,
      saldo: totalIngresos - totalEgresos,
      expenseByCategory: expenseByCategory,
      totalBalance: totalBalance,
      cashBalance: cashBalance,
      virtualBalance: virtualBalance,
    );
  }

  void _navigateToAddTransaction(String type) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddTransactionPage(initialType: type),
      ),
    );
  }

  Future<void> _showOptions(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Wrap(
          children: [
            ListTile(
              leading: Icon(Icons.edit, color: Theme.of(context).primaryColor),
              title: const Text('Editar'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) =>
                        AddTransactionPage(transaction: transaction),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text('Eliminar',
                  style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.of(context).pop();
                _deleteTransaction(context, transaction);
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteTransaction(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content:
            const Text('¿Seguro que quieres eliminar esta transacción?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await supabase
            .from('transactions')
            .delete()
            .match({'id': transaction['id']});
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Transacción eliminada')));
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error al eliminar: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const MyAppBar(title: 'Inicio'),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: ValueListenableBuilder<FinancialSummaryData>(
              valueListenable: _summaryNotifier,
              builder: (context, summary, _) => FinancialSummaryCard(
                totalIngresos: currencyFormat.format(summary.totalIngresos),
                totalEgresos: currencyFormat.format(summary.totalEgresos),
                saldo: currencyFormat.format(summary.totalBalance),
                cashBalance: currencyFormat.format(summary.cashBalance),
                virtualBalance: currencyFormat.format(summary.virtualBalance),
                expenseData: summary.expenseByCategory,
                showPieChart: false,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 16.0,
              vertical: 8.0,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Buscar transacción...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: Theme.of(context).scaffoldBackgroundColor,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.filter_list),
                  onPressed: () {
                    // TODO: Implement filter dialog
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16).copyWith(top: 8, bottom: 8),
            child: Text(
              'Transacciones Recientes',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<List<Map<String, dynamic>>>(
              valueListenable: _transactionsNotifier,
              builder: (context, transactions, _) {
                if (transactions.isEmpty && _accountsNotifier.value.isEmpty) {
                  return const LoadingShimmer();
                }
                if (transactions.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.symmetric(vertical: 48.0),
                      child: Text(
                        'Aún no tienes transacciones.',
                        style: TextStyle(
                          color: AppTheme.subtextColor,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  itemCount: transactions.length,
                  itemBuilder: (context, index) {
                    final transaction = transactions[index];
                    return TransactionListItem(
                      transaction: transaction,
                      onLongPress: () => _showOptions(context, transaction),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(left: 32.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FloatingActionButton.extended(
              heroTag: 'fab_expense',
              onPressed: () => _navigateToAddTransaction('expense'),
              label: const Text('Egreso'),
              icon: const Icon(Icons.remove),
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
            ),
            FloatingActionButton.extended(
              heroTag: 'fab_income',
              onPressed: () => _navigateToAddTransaction('income'),
              label: const Text('Ingreso'),
              icon: const Icon(Icons.add),
              backgroundColor: AppTheme.accentColor,
              foregroundColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}
