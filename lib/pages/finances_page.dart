import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/pages/accounts_page.dart';
import 'package:mi_billetera_digital/pages/budgets_page.dart';
import 'package:mi_billetera_digital/pages/savings_goals_page.dart';

class FinancesPage extends StatelessWidget {
  const FinancesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Finanzas'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Cuentas'),
              Tab(text: 'Presupuestos'),
              Tab(text: 'Metas'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            AccountsPage(),
            BudgetsPage(),
            SavingsGoalsPage(),
          ],
        ),
      ),
    );
  }
}
