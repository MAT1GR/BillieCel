import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/pages/transactions_page.dart';
import 'package:mi_billetera_digital/pages/budgets_page.dart';
import 'package:mi_billetera_digital/pages/savings_goals_page.dart';
import 'package:mi_billetera_digital/pages/tasks_page.dart';
import 'package:mi_billetera_digital/pages/accounts_page.dart';
import 'package:mi_billetera_digital/pages/profile_page.dart';

class MainLayoutPage extends StatefulWidget {
  final int initialPageIndex;
  const MainLayoutPage({super.key, required this.initialPageIndex});

  @override
  State<MainLayoutPage> createState() => _MainLayoutPageState();
}

class _MainLayoutPageState extends State<MainLayoutPage> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialPageIndex;
  }

  // --- LISTA DE PÁGINAS REORDENADA ---
  static const List<Widget> _widgetOptions = <Widget>[
    TransactionsPage(),
    AccountsPage(),
    BudgetsPage(),
    SavingsGoalsPage(),
    TasksPage(),
    ProfilePage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(child: _widgetOptions.elementAt(_selectedIndex)),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        // --- LISTA DE ÍTEMS REORDENADA ---
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Resumen', // Cambiado para mayor claridad
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.credit_card_outlined),
            activeIcon: Icon(Icons.credit_card),
            label: 'Cuentas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline),
            activeIcon: Icon(Icons.pie_chart),
            label: 'Presupuestos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.star_border_outlined),
            activeIcon: Icon(Icons.star),
            label: 'Metas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.checklist_outlined),
            activeIcon: Icon(Icons.checklist),
            label: 'Tareas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
