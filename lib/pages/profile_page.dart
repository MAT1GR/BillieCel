import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/pages/categories_page.dart';
import 'package:mi_billetera_digital/pages/change_password_page.dart';
import 'package:mi_billetera_digital/pages/login_page.dart';
import 'package:mi_billetera_digital/app_theme.dart';

import 'package:shared_preferences/shared_preferences.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late bool isDarkMode;
  bool _biometricEnabled = true;
  String _selectedCurrency = 'ARS';

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? false;
      _selectedCurrency = prefs.getString('currency') ?? 'ARS';
    });
  }

  Future<void> _saveBiometricPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', value);
  }

  Future<void> _saveCurrencyPreference(String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('currency', value);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    isDarkMode = AppTheme.themeNotifier.value == ThemeMode.dark;
  }

  @override
  Widget build(BuildContext context) {
    final userEmail = supabase.auth.currentUser?.email ?? 'No disponible';

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildSectionTitle('Cuenta'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.email_outlined, color: Theme.of(context).primaryColor),
                    title: const Text('Email'),
                    subtitle: Text(userEmail),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.lock_outline, color: Theme.of(context).primaryColor),
                    title: const Text('Cambiar Contraseña'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ChangePasswordPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.category_outlined, color: Theme.of(context).primaryColor),
                    title: const Text('Gestionar Categorías'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CategoriesPage(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          _buildSectionTitle('Apariencia'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.brightness_6_outlined, color: Theme.of(context).primaryColor),
                    title: const Text('Modo Oscuro'),
                    trailing: Switch(
                      value: isDarkMode,
                      onChanged: (value) {
                        setState(() {
                          isDarkMode = value;
                          AppTheme.setThemeMode(
                              isDarkMode ? ThemeMode.dark : ThemeMode.light);
                        });
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.attach_money, color: Theme.of(context).primaryColor),
                    title: const Text('Moneda'),
                    subtitle: Text(_selectedCurrency),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showCurrencyPicker(),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(Icons.language, color: Theme.of(context).primaryColor),
                    title: const Text('Idioma'),
                    subtitle: const Text('Español'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Esta función estará disponible próximamente')),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          _buildSectionTitle('Seguridad'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Seguridad del Dispositivo'),
                    subtitle: const Text('Proteger la app con huella, rostro o PIN'),
                    value: _biometricEnabled,
                    onChanged: (value) {
                      setState(() {
                        _biometricEnabled = value;
                      });
                      _saveBiometricPreference(value);
                    },
                    secondary: Icon(Icons.fingerprint, color: Theme.of(context).primaryColor),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              await supabase.auth.signOut();
              if (context.mounted) {
                Navigator.of(context).pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              }
            },
            icon: const Icon(Icons.logout),
            label: const Text('Cerrar Sesión'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).primaryColor,
        ),
      ),
    );
  }

  void _showCurrencyPicker() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Seleccionar Moneda'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _currencyTile('ARS', 'Peso Argentino'),
              _currencyTile('USD', 'Dólar Estadounidense'),
              _currencyTile('EUR', 'Euro'),
            ],
          ),
        );
      },
    );
  }

  Widget _currencyTile(String code, String name) {
    return ListTile(
      title: Text(name),
      trailing: Text(code, style: const TextStyle(color: Colors.grey)),
      onTap: () {
        setState(() {
          _selectedCurrency = code;
        });
        _saveCurrencyPreference(code);
        Navigator.of(context).pop();
      },
    );
  }
}
