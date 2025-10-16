import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:mi_billetera_digital/pages/splash_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthGatePage extends StatefulWidget {
  const AuthGatePage({super.key});

  @override
  State<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends State<AuthGatePage> {
  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  Future<void> _authenticate() async {
    final prefs = await SharedPreferences.getInstance();
    final bool biometricEnabled = prefs.getBool('biometric_enabled') ?? false;

    if (biometricEnabled) {
      final LocalAuthentication auth = LocalAuthentication();
      try {
        final bool didAuthenticate = await auth.authenticate(
          localizedReason: 'Por favor, autentícate para acceder a Billie',
          options: const AuthenticationOptions(biometricOnly: true),
        );
        if (didAuthenticate) {
          _navigateToHome();
        } else {
          // Handle case where authentication is cancelled
        }
      } catch (e) {
        // Handle error
        _navigateToHome(); // For now, navigate to home on error
      }
    } else {
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const SplashPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
