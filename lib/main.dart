import 'package:flutter/material.dart';
import 'package:mi_billetera_digital/app_theme.dart';
import 'package:mi_billetera_digital/pages/auth_gate_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/date_symbol_data_local.dart'; // <-- 1. Importa esta librería

import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inicializa el formato de fecha para español/Argentina
  await initializeDateFormatting('es_AR', null);

  await Supabase.initialize(
    url: 'https://llbpzfzywanuklhhitdi.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImxsYnB6Znp5d2FudWtsaGhpdGRpIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjAzNzE0MzUsImV4cCI6MjA3NTk0NzQzNX0.gquBGPGRq3PTnMhRN0kaSnde_iBXI6cDT6SNA65h4zI',
  );

  final prefs = await SharedPreferences.getInstance();
  final themeMode = prefs.getString('themeMode');
  if (themeMode == 'dark') {
    AppTheme.themeNotifier.value = ThemeMode.dark;
  } else {
    AppTheme.themeNotifier.value = ThemeMode.light;
  }

  runApp(const MyApp());
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: AppTheme.themeNotifier,
      builder: (context, currentMode, child) {
        return MaterialApp(
          title: 'Mi Billetera Digital',
          theme: AppTheme.theme,
          darkTheme: AppTheme.darkTheme,
          themeMode: currentMode,
          debugShowCheckedModeBanner: false,
          home: const AuthGatePage(),
        );
      },
    );
  }
}
