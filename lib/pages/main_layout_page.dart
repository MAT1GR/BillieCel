import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/pages/finances_page.dart';
import 'package:mi_billetera_digital/pages/profile_page.dart';
import 'package:mi_billetera_digital/pages/analysis_page.dart';
import 'package:mi_billetera_digital/pages/transactions_page.dart';
import 'package:mi_billetera_digital/pages/debts_page.dart';
import 'package:mi_billetera_digital/pages/calculator_page.dart';

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
    FinancesPage(),
    DebtsPage(),
    AnalysisPage(),
    CalculatorPage(),
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
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Inicio',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_balance_wallet_outlined),
            activeIcon: Icon(Icons.account_balance_wallet),
            label: 'Finanzas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.request_quote_outlined),
            activeIcon: Icon(Icons.request_quote),
            label: 'Deudas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_outlined),
            activeIcon: Icon(Icons.bar_chart),
            label: 'Análisis',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calculate_outlined),
            activeIcon: Icon(Icons.calculate),
            label: 'Calculadora',
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
