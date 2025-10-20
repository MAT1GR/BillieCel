import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:math_expressions/math_expressions.dart';

import 'package:google_fonts/google_fonts.dart';

class CalculatorPage extends StatefulWidget {
  const CalculatorPage({super.key});

  @override
  State<CalculatorPage> createState() => _CalculatorPageState();
}

class _CalculatorPageState extends State<CalculatorPage> {
  String _expression = '';
  String _result = '';

  double _cashBalance = 0;
  double _virtualBalance = 0;
  double _totalBalance = 0;

  @override
  void initState() {
    super.initState();
    _listenToAccountChanges();
  }

  void _listenToAccountChanges() {
    supabase.from('accounts').stream(primaryKey: ['id']).listen((accounts) {
      double cash = 0;
      double virtual = 0;
      for (var acc in accounts) {
        final balance = (acc['balance'] as num?)?.toDouble() ?? 0.0;
        if ((acc['name'] as String).toLowerCase() == 'efectivo') {
          cash += balance;
        } else {
          virtual += balance;
        }
      }
      if (mounted) {
        setState(() {
          _cashBalance = cash;
          _virtualBalance = virtual;
          _totalBalance = cash + virtual;
        });
      }
    });
  }

  void _onButtonPressed(String buttonText) {
    setState(() {
      if (buttonText == 'C') {
        _expression = '';
        _result = '';
      } else if (buttonText == '⌫') {
        if (_expression.isNotEmpty) {
          _expression = _expression.substring(0, _expression.length - 1);
        }
      } else if (buttonText == '=') {
        try {
          String finalExpression = _expression.replaceAll('×', '*').replaceAll('÷', '/');
          Parser p = Parser();
          Expression exp = p.parse(finalExpression);
          ContextModel cm = ContextModel();
          _result = exp.evaluate(EvaluationType.REAL, cm).toString();
        } catch (e) {
          _result = 'Error';
        }
      } else {
        _expression += buttonText;
      }
    });
  }

  void _onBalanceButtonPressed(double balance) {
    setState(() {
      _expression += balance.toStringAsFixed(2);
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final displayTextColor = isDarkMode ? Colors.white : Colors.black;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora'),
        elevation: 0,
        backgroundColor: Colors.transparent,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              flex: 2,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                alignment: Alignment.bottomRight,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    FittedBox(
                      fit: BoxFit.fitWidth,
                      child: Text(
                        _expression,
                        style: GoogleFonts.robotoMono(fontSize: 48, color: Colors.grey),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.fitWidth,
                      child: Text(
                        _result,
                        style: GoogleFonts.robotoMono(
                          fontSize: 80,
                          fontWeight: FontWeight.bold,
                          color: displayTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _balanceButton('Efectivo', _cashBalance, isDarkMode),
                  _balanceButton('Virtual', _virtualBalance, isDarkMode),
                  _balanceButton('Total', _totalBalance, isDarkMode),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              flex: 3,
              child: _buildCalculatorButtons(isDarkMode),
            ),
          ],
        ),
      ),
    );
  }

  Widget _balanceButton(String title, double balance, bool isDarkMode) {
    return ElevatedButton(
      onPressed: () => _onBalanceButtonPressed(balance),
      style: ElevatedButton.styleFrom(
        backgroundColor: isDarkMode ? Colors.blue[800] : Colors.blue,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildCalculatorButtons(bool isDarkMode) {
    return Container(
      color: isDarkMode ? Colors.black : Colors.white,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildButtonRow(['C', '⌫', '%', '÷'], isDarkMode),
          _buildButtonRow(['7', '8', '9', '×'], isDarkMode),
          _buildButtonRow(['4', '5', '6', '-'], isDarkMode),
          _buildButtonRow(['1', '2', '3', '+'], isDarkMode),
          _buildButtonRow(['00', '0', '.', '='], isDarkMode),
        ],
      ),
    );
  }

  Widget _buildButtonRow(List<String> buttons, bool isDarkMode) {
    return Expanded(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: buttons.map((buttonText) {
          return _buildCalculatorButton(buttonText, isDarkMode);
        }).toList(),
      ),
    );
  }

  Widget _buildCalculatorButton(String buttonText, bool isDarkMode) {
    Color textColor = isDarkMode ? Colors.white : Colors.black;
    Color backgroundColor;

    if (['÷', '×', '-', '+', '='].contains(buttonText)) {
      backgroundColor = isDarkMode ? Colors.orange : Colors.blue;
      textColor = Colors.white;
    } else if (['C', '⌫', '%'].contains(buttonText)) {
      backgroundColor = isDarkMode ? Colors.grey[700]! : Colors.grey[400]!;
    } else {
      backgroundColor = isDarkMode ? Colors.grey[850]! : Colors.grey[300]!;
    }

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          onPressed: () => _onButtonPressed(buttonText),
          style: ElevatedButton.styleFrom(
            backgroundColor: backgroundColor,
            foregroundColor: textColor,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(20),
          ),
          child: buttonText == '⌫'
              ? const Icon(Icons.backspace_outlined)
              : Text(
                  buttonText,
                  style: GoogleFonts.robotoMono(fontSize: 28, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}
