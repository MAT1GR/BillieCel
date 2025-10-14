import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/pages/transactions_page.dart';
import 'package:mi_billetera_digital/pages/tasks_page.dart';
import 'package:mi_billetera_digital/pages/budgets_page.dart'; // <-- Nueva página

class MainLayoutPage extends StatefulWidget {
  const MainLayoutPage({super.key});

  @override
  State<MainLayoutPage> createState() => _MainLayoutPageState();
}

class _MainLayoutPageState extends State<MainLayoutPage> {
  int _selectedIndex = 0;

  static const List<Widget> _widgetOptions = <Widget>[
    TransactionsPage(),
    BudgetsPage(), // <-- Nueva página en el medio
    TasksPage(),
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
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet),
            label: 'Transacciones',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.pie_chart_outline), // <-- Nuevo ícono
            label: 'Presupuestos',
          ),
          BottomNavigationBarItem(icon: Icon(Icons.checklist), label: 'Tareas'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}
