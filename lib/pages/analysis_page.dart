import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/widgets/financial_summary_card.dart';
import 'package:mi_billetera_digital/widgets/expense_pie_chart_card.dart';
import 'package:mi_billetera_digital/widgets/transaction_list_item.dart';
import 'package:mi_billetera_digital/pages/add_transaction_page.dart';
import 'package:mi_billetera_digital/models/financial_summary_data.dart';

enum SummaryViewType { weekly, monthly, yearly }

class AnalysisPage extends StatefulWidget {
  const AnalysisPage({super.key});

  @override
  State<AnalysisPage> createState() => _AnalysisPageState();
}

class _AnalysisPageState extends State<AnalysisPage> {
  StreamSubscription? _transactionsSubscription;
  StreamSubscription? _accountsSubscription;

  final _summaryNotifier = ValueNotifier<FinancialSummaryData>(
    FinancialSummaryData(),
  );
  final _transactionsNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);
  final _filteredTransactionsNotifier =
      ValueNotifier<List<Map<String, dynamic>>>([]);
  final _accountsNotifier = ValueNotifier<List<Map<String, dynamic>>>([]);

  SummaryViewType _viewType = SummaryViewType.monthly;
  DateTime _selectedDate = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );

  @override
  void initState() {
    super.initState();
    final transactionsStream = supabase
        .from('transactions')
        .stream(primaryKey: ['id']);
    final accountsStream = supabase.from('accounts').stream(primaryKey: ['id']);

    _transactionsSubscription = transactionsStream.listen((transactions) {
      _transactionsNotifier.value = transactions;
      _recalculateSummary();
    });

    _accountsSubscription = accountsStream.listen((accounts) {
      _accountsNotifier.value = accounts;
      _recalculateSummary();
    });
  }

  @override
  void dispose() {
    _transactionsSubscription?.cancel();
    _accountsSubscription?.cancel();
    _summaryNotifier.dispose();
    _transactionsNotifier.dispose();
    _filteredTransactionsNotifier.dispose();
    _accountsNotifier.dispose();
    super.dispose();
  }

  void _recalculateSummary() {
    final allTransactions = _transactionsNotifier.value;
    final accounts = _accountsNotifier.value;

    List<Map<String, dynamic>> filteredTransactions;

    if (_viewType == SummaryViewType.monthly) {
      filteredTransactions = allTransactions.where((t) {
        final transactionDate = DateTime.parse(t['date']);
        return transactionDate.year == _selectedDate.year &&
            transactionDate.month == _selectedDate.month;
      }).toList();
    } else if (_viewType == SummaryViewType.weekly) {
      final startOfWeek = _selectedDate.subtract(
        Duration(days: _selectedDate.weekday - 1),
      );
      final endOfWeek = startOfWeek.add(const Duration(days: 7));
      filteredTransactions = allTransactions.where((t) {
        final transactionDate = DateTime.parse(t['date']);
        return transactionDate.isAfter(
              startOfWeek.subtract(const Duration(microseconds: 1)),
            ) &&
            transactionDate.isBefore(endOfWeek);
      }).toList();
    } else {
      // Yearly
      filteredTransactions = allTransactions.where((t) {
        final transactionDate = DateTime.parse(t['date']);
        return transactionDate.year == _selectedDate.year;
      }).toList();
    }

    _filteredTransactionsNotifier.value = filteredTransactions;

    double totalIngresos = 0;
    double totalEgresos = 0;
    final Map<String, double> expenseByCategory = {};

    for (var t in filteredTransactions) {
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

  void _changeDate(int increment) {
    setState(() {
      if (_viewType == SummaryViewType.monthly) {
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month + increment,
          1,
        );
      } else if (_viewType == SummaryViewType.weekly) {
        _selectedDate = _selectedDate.add(Duration(days: 7 * increment));
      } else {
        // Yearly
        _selectedDate = DateTime(
          _selectedDate.year + increment,
          _selectedDate.month,
          _selectedDate.day,
        );
      }
      _recalculateSummary();
    });
  }

  void _toggleView(SummaryViewType newViewType) {
    setState(() {
      _viewType = newViewType;
      _selectedDate = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
      );
      _recalculateSummary();
    });
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
        );
      },
    );
  }

  Future<void> _deleteTransaction(
    BuildContext context,
    Map<String, dynamic> transaction,
  ) async {
    final bool? confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirmar eliminación'),
        content: const Text(
          '¿Estás seguro de que quieres eliminar esta transacción?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      try {
        await supabase.from('transactions').delete().match({
          'id': transaction['id'],
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Transacción eliminada')));
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Error al eliminar la transacción'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Análisis')),
      body: MonthlySummaryView(
        summaryNotifier: _summaryNotifier,
        filteredTransactionsNotifier: _filteredTransactionsNotifier,
        selectedDate: _selectedDate,
        viewType: _viewType,
        onDateChange: _changeDate,
        onViewChange: _toggleView,
        onTransactionLongPress: (transaction) =>
            _showOptions(context, transaction),
      ),
    );
  }
}

class MonthlySummaryView extends StatelessWidget {
  final ValueNotifier<FinancialSummaryData> summaryNotifier;
  final ValueNotifier<List<Map<String, dynamic>>> filteredTransactionsNotifier;
  final DateTime selectedDate;
  final SummaryViewType viewType;
  final void Function(int) onDateChange;
  final void Function(SummaryViewType) onViewChange;
  final void Function(Map<String, dynamic>) onTransactionLongPress;

  const MonthlySummaryView({
    super.key,
    required this.summaryNotifier,
    required this.filteredTransactionsNotifier,
    required this.selectedDate,
    required this.viewType,
    required this.onDateChange,
    required this.onViewChange,
    required this.onTransactionLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final currencyFormat = NumberFormat.currency(
      locale: 'es_AR',
      symbol: '\$ ',
    );

    return ListView(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: SegmentedButton<SummaryViewType>(
            segments: const [
              ButtonSegment(
                value: SummaryViewType.monthly,
                label: Text('Mensual'),
              ),
              ButtonSegment(
                value: SummaryViewType.weekly,
                label: Text('Semanal'),
              ),
              ButtonSegment(value: SummaryViewType.yearly, label: Text('Anual')),
            ],
            selected: {viewType},
            onSelectionChanged: (newSelection) {
              onViewChange(newSelection.first);
            },
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: _buildDateNavigator(context),
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<FinancialSummaryData>(
          valueListenable: summaryNotifier,
          builder: (context, summary, _) => FinancialSummaryCard(
            totalIngresos: currencyFormat.format(summary.totalIngresos),
            totalEgresos: currencyFormat.format(summary.totalEgresos),
            saldo: currencyFormat.format(summary.saldo),
            cashBalance: currencyFormat.format(summary.cashBalance),
            virtualBalance: currencyFormat.format(summary.virtualBalance),
            expenseData: summary.expenseByCategory,
            showMonthlySummary: true,
          ),
        ),
        const SizedBox(height: 16),
        ValueListenableBuilder<FinancialSummaryData>(
          valueListenable: summaryNotifier,
          builder: (context, summary, _) => ExpensePieChartCard(
            expenseData: summary.expenseByCategory,
          ),
        ),
        const Divider(height: 32),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'Movimientos del Periodo',
            style: Theme.of(context).textTheme.titleLarge,
          ),
        ),
        const SizedBox(height: 8),
        ValueListenableBuilder<List<Map<String, dynamic>>>(
          valueListenable: filteredTransactionsNotifier,
          builder: (context, transactions, _) {
            if (transactions.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 32.0),
                  child: Text('No hay movimientos en este periodo.'),
                ),
              );
            }
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction = transactions[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: TransactionListItem(
                    transaction: transaction,
                    onLongPress: () => onTransactionLongPress(transaction),
                  ),
                );
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateNavigator(BuildContext context) {
    String dateText;
    bool isFuture;
    final now = DateTime.now();

    if (viewType == SummaryViewType.monthly) {
      dateText = DateFormat.yMMMM('es_AR').format(selectedDate);
      isFuture =
          selectedDate.year == now.year && selectedDate.month == now.month;
    } else if (viewType == SummaryViewType.weekly) {
      final startOfWeek = selectedDate.subtract(
        Duration(days: selectedDate.weekday - 1),
      );
      final endOfWeek = startOfWeek.add(const Duration(days: 6));
      dateText =
          '${DateFormat.d('es_AR').format(startOfWeek)} - ${DateFormat.yMMMd('es_AR').format(endOfWeek)}';
      isFuture =
          now.isAfter(startOfWeek) &&
          now.isBefore(endOfWeek.add(const Duration(days: 1)));
    } else {
      // Yearly
      dateText = DateFormat.y('es_AR').format(selectedDate);
      isFuture = selectedDate.year == now.year;
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onDateChange(-1),
        ),
        Expanded(
          child: Text(
            dateText,
            style: Theme.of(context).textTheme.titleLarge,
            textAlign: TextAlign.center,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: isFuture ? null : () => onDateChange(1),
        ),
      ],
    );
  }
}