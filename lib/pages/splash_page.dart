import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/pages/main_layout_page.dart';
import 'package:mi_billetera_digital/pages/login_page.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> {
  @override
  void initState() {
    super.initState();
    _redirect();
  }

  Future<void> _redirect() async {
    // Espera un momento para que la app cargue.
    await Future.delayed(Duration.zero);

    final session = supabase.auth.currentSession;

    if (!mounted) return;

    if (session != null) {
      // Si hay sesión, va a la HomePage.
      Navigator.of(context).pushReplacement(
        // dentro de splash_page.dart
        MaterialPageRoute(builder: (context) => const MainLayoutPage(initialPageIndex: 0)),
      );
    } else {
      // Si no hay sesión, va a la LoginPage.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}
