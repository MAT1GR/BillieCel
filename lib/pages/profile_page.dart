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

  @override
  void initState() {
    super.initState();
    _loadBiometricPreference();
  }

  Future<void> _loadBiometricPreference() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _biometricEnabled = prefs.getBool('biometric_enabled') ?? true;
    });
  }

  Future<void> _saveBiometricPreference(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('biometric_enabled', value);
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
      appBar: AppBar(title: const Text('Mi Perfil')),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(
                      Icons.email_outlined,
                      color: AppTheme.primaryColor,
                    ),
                    title: const Text('Email'),
                    subtitle: Text(userEmail),
                  ),
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.lock_outline,
                      color: AppTheme.primaryColor,
                    ),
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
                    leading: const Icon(
                      Icons.category_outlined,
                      color: AppTheme.primaryColor,
                    ),
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
                  const Divider(),
                  ListTile(
                    leading: const Icon(
                      Icons.brightness_6_outlined,
                      color: AppTheme.primaryColor,
                    ),
                    title: const Text('Modo Oscuro'),
                    trailing: Switch(
                      value: isDarkMode,
                      onChanged: (value) {
                        setState(() {
                          isDarkMode = value;
                          AppTheme.themeNotifier.value =
                              isDarkMode ? ThemeMode.dark : ThemeMode.light;
                        });
                      },
                    ),
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Seguridad Biométrica'),
                    subtitle: const Text('Proteger la app con huella o rostro'),
                    value: _biometricEnabled,
                    onChanged: (value) {
                      setState(() {
                        _biometricEnabled = value;
                      });
                      _saveBiometricPreference(value);
                    },
                    secondary: const Icon(
                      Icons.fingerprint,
                      color: AppTheme.primaryColor,
                    ),
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
              backgroundColor:
                  Colors.redAccent, // Un color distintivo para la acción
            ),
          ),
        ],
      ),
    );
  }
}
