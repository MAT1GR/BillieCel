import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'dart:async';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/pages/add_transaction_page.dart';
import 'package:mi_billetera_digital/app_theme.dart';
import 'package:mi_billetera_digital/widgets/loading_shimmer.dart';
import 'package:mi_billetera_digital/widgets/my_app_bar.dart';
import 'package:mi_billetera_digital/widgets/financial_summary_card.dart';
import 'package:mi_billetera_digital/widgets/transaction_list_item.dart';
import 'package:mi_billetera_digital/widgets/filter_bottom_sheet.dart';
import 'package:mi_billetera_digital/models/financial_summary_data.dart'; // Import FinancialSummaryData from its new location

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

    _transactionsSubscription =
        _transactionsStream.listen((transactions) {
          _transactionsNotifier.value = transactions;
          _recalculateSummary();
        })..onError((error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al cargar transacciones: $error'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
        });

    _accountsSubscription =
        _accountsStream.listen((accounts) {
          _accountsNotifier.value = accounts;
          _recalculateSummary();
        })..onError((error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error al cargar cuentas: $error'),
                backgroundColor: Theme.of(context).colorScheme.error,
              ),
            );
          }
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

  void _showFilterBottomSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FilterBottomSheet(
        initialAccountId: _selectedAccountId,
        initialCategory: _selectedCategory,
        initialStartDate: _startDate,
        initialEndDate: _endDate,
      ),
    );

    if (result != null) {
      setState(() {
        _selectedAccountId = result['accountId'];
        _selectedCategory = result['category'];
        _startDate = result['startDate'];
        _endDate = result['endDate'];
        _resetAndBuildStreams();
      });
    }
  }

  void _navigateToAddTransaction(String type) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddTransactionPage(initialType: type),
      ),
    );
    _resetAndBuildStreams();
  }

  Future<void> _showOptions(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) async {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return Container(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).padding.bottom,
          ),
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(
                  Icons.edit,
                  color: Theme.of(context).primaryColor,
                ),
                title: const Text('Editar'),
                onTap: () async {
                  // Made async
                  Navigator.of(context).pop();
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) =>
                          AddTransactionPage(transaction: transaction),
                    ),
                  );
                  _resetAndBuildStreams(); // Refresh after edit
                },
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.redAccent),
                title: const Text(
                  'Eliminar',
                  style: TextStyle(color: Colors.redAccent),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  _deleteTransaction(context, transaction);
                },
              ),
            ],
          ),
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
        content: const Text('¿Seguro que quieres eliminar esta transacción?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await supabase.from('transactions').delete().match({
          'id': transaction['id'],
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transacción eliminada')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error al eliminar: $e')));
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
                saldo: currencyFormat.format(summary.totalBalance),
                cashBalance: currencyFormat.format(summary.cashBalance),
                virtualBalance: currencyFormat.format(summary.virtualBalance),
                expenseData: const {},
                showMonthlySummary: false,
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
                  onPressed: _showFilterBottomSheet,
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
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long,
                          size: 80,
                          color: AppTheme.subtextColor.withOpacity(0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Aún no tienes transacciones registradas.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.subtextColor,
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          '¡Empieza a añadir tus movimientos financieros!',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppTheme.subtextColor,
                            fontSize: 14,
                          ),
                        ),
                      ],
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
      floatingActionButton: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(
                  sigmaX: 5,
                  sigmaY: 5,
                ), // Subtle blur effect
                child: Container(
                  height: 100, // Adjust height as needed to cover FABs
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor
                        .withOpacity(0.7), // Semi-transparent overlay
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(20),
                    ),
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(
              left: 32.0,
              top: 16.0,
              bottom: 16.0,
              right: 16.0,
            ),
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
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}
