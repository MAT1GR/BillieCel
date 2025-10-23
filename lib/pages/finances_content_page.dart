import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/pages/accounts_page.dart';
import 'package:mi_billetera_digital/pages/budgets_page.dart';
import 'package:mi_billetera_digital/pages/savings_goals_page.dart';
import 'package:mi_billetera_digital/utils/couple_mode_provider.dart';

class FinancesContentPage extends StatefulWidget {
  final CoupleMode mode;
  const FinancesContentPage({super.key, required this.mode});

  @override
  State<FinancesContentPage> createState() => _FinancesContentPageState();
}

class _FinancesContentPageState extends State<FinancesContentPage> with TickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Cuentas'),
            Tab(text: 'Presupuestos'),
            Tab(text: 'Metas'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          AccountsPage(mode: widget.mode),
          BudgetsPage(mode: widget.mode),
          SavingsGoalsPage(mode: widget.mode),
        ],
      ),
    );
  }
}
