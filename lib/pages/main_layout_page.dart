// lib/pages/main_layout_page.dart

import 'package:flutter/material.dart'; // <-- Esta es la línea clave para toda la UI de Material Design.
import 'package:mi_billetera_digital/pages/transactions_page.dart'; // Actualizamos al nuevo nombre
import 'package:mi_billetera_digital/pages/tasks_page.dart';

class MainLayoutPage extends StatefulWidget {
  const MainLayoutPage({super.key});

  @override
  State<MainLayoutPage> createState() => _MainLayoutPageState();
}

class _MainLayoutPageState extends State<MainLayoutPage> {
  int _selectedIndex = 0;

  // Ahora la lista de páginas es más clara.
  static const List<Widget> _widgetOptions = <Widget>[
    TransactionsPage(), // Usamos el nuevo nombre
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
          BottomNavigationBarItem(icon: Icon(Icons.checklist), label: 'Tareas'),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.blue[800], // Pequeña mejora visual
      ),
    );
  }
}
