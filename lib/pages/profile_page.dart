import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/main.dart';
import 'package:mi_billetera_digital/pages/change_password_page.dart';
import 'package:mi_billetera_digital/pages/recurring_transactions_page.dart';
import 'package:mi_billetera_digital/pages/login_page.dart';
import 'package:mi_billetera_digital/pages/couple_settings_page.dart';
import 'package:mi_billetera_digital/pages/export_data_page.dart';
import 'package:mi_billetera_digital/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

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
  String? _currentUsername;
  final _usernameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    @override
    void dispose() {
      _usernameController.dispose();
      super.dispose();
    }
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

  Future<void> _loadUserProfile() async {
    debugPrint('[ProfilePage] _loadUserProfile: Starting...');
    final userId = supabase.auth.currentUser!.id;
    debugPrint('[ProfilePage] _loadUserProfile: Current User ID: $userId');
    final response = await supabase
        .from('profiles')
        .select('username')
        .eq('id', userId)
        .maybeSingle();

    debugPrint('[ProfilePage] _loadUserProfile: Supabase Response: $response');

    if (response != null) {
      setState(() {
        _currentUsername = response['username'];
        _usernameController.text = _currentUsername ?? '';
      });
      debugPrint('[ProfilePage] _loadUserProfile: State updated: _currentUsername=$_currentUsername');
    } else {
      debugPrint('[ProfilePage] _loadUserProfile: No profile found for user.');
      setState(() {
        _currentUsername = null;
        _usernameController.text = '';
      });
    }
  }

  Future<void> _saveUsername() async {
    final newUsername = _usernameController.text.trim();
    debugPrint('[ProfilePage] _saveUsername: newUsername=$newUsername');
    if (newUsername.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El nombre de usuario no puede estar vacío.'),
        ),
      );
      return;
    }

    final userId = supabase.auth.currentUser!.id;
    try {
      // Check if profile exists
      final existingProfile = await supabase
          .from('profiles')
          .select('id')
          .eq('id', userId)
          .maybeSingle();

      if (existingProfile == null) {
        debugPrint('[ProfilePage] _saveUsername: Inserting new profile for userId=$userId');
        // Insert new profile
        await supabase.from('profiles').insert({
          'id': userId,
          'username': newUsername,
        });
      } else {
        debugPrint('[ProfilePage] _saveUsername: Updating existing profile for userId=$userId');
        // Update existing profile
        await supabase
            .from('profiles')
            .update({'username': newUsername})
            .eq('id', userId);
      }
      debugPrint('[ProfilePage] _saveUsername: Profile operation completed.');

      setState(() {
        _currentUsername = newUsername;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nombre de usuario actualizado con éxito!'),
          ),
        );
        Navigator.of(context).pop(); // Close dialog or navigate back
      }
    } on PostgrestException catch (e) {
      debugPrint('[ProfilePage] _saveUsername PostgrestException: ${e.message}');
      if (e.code == '23505') {
        // Unique constraint violation
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ese nombre de usuario ya está en uso.'),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Error al actualizar nombre de usuario: ${e.message}',
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('[ProfilePage] _saveUsername Unexpected Error: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error inesperado: ${e.toString()}')),
      );
    }
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
                    leading: Icon(
                      Icons.email_outlined,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: const Text('Email'),
                    subtitle: Text(userEmail),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.person_outline,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: const Text('Nombre de Usuario'),
                    subtitle: Text(_currentUsername ?? 'No establecido'),
                    trailing: const Icon(Icons.edit),
                    onTap: () {
                      _usernameController.text =
                          _currentUsername ??
                          ''; // Pre-fill with current username
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Editar Nombre de Usuario'),
                          content: TextField(
                            controller: _usernameController,
                            decoration: const InputDecoration(
                              labelText: 'Nombre de Usuario',
                            ),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Cancelar'),
                            ),
                            ElevatedButton(
                              onPressed: _saveUsername,
                              child: const Text('Guardar'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.lock_outline,
                      color: Theme.of(context).primaryColor,
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
                    leading: Icon(
                      Icons.repeat,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: const Text('Transacciones Recurrentes'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) =>
                              const RecurringTransactionsPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.people_alt_outlined,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: const Text('Configuración de Pareja'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const CoupleSettingsPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.download_outlined,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: const Text('Exportar Datos'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const ExportDataPage(),
                        ),
                      );
                    },
                  ),
                  const Divider(),
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
                    leading: Icon(
                      Icons.brightness_6_outlined,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: const Text('Modo Oscuro'),
                    trailing: Switch(
                      value: isDarkMode,
                      onChanged: (value) {
                        setState(() {
                          isDarkMode = value;
                          AppTheme.setThemeMode(
                            isDarkMode ? ThemeMode.dark : ThemeMode.light,
                          );
                        });
                      },
                    ),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.attach_money,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: const Text('Moneda'),
                    subtitle: Text(_selectedCurrency),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () => _showCurrencyPicker(),
                  ),
                  const Divider(),
                  ListTile(
                    leading: Icon(
                      Icons.language,
                      color: Theme.of(context).primaryColor,
                    ),
                    title: const Text('Idioma'),
                    subtitle: const Text('Español'),
                    trailing: const Icon(Icons.arrow_forward_ios),
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text(
                            'Esta función estará disponible próximamente',
                          ),
                        ),
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
                    subtitle: const Text(
                      'Proteger la app con huella, rostro o PIN',
                    ),
                    value: _biometricEnabled,
                    onChanged: (value) {
                      setState(() {
                        _biometricEnabled = value;
                      });
                      _saveBiometricPreference(value);
                    },
                    secondary: Icon(
                      Icons.fingerprint,
                      color: Theme.of(context).primaryColor,
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
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
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
