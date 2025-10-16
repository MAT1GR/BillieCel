import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // --- PALETA DE COLORES ---
  static const Color primaryColor = Color(
    0xFF1A237E,
  ); // Un azul índigo profundo
  static const Color accentColor = Color(
    0xFF00E676,
  ); // Un verde vibrante para acentos
  static const Color backgroundColor = Color(
    0xFFF5F5F5,
  ); // Un gris muy claro para el fondo
  static const Color cardColor = Colors.white;
  static const Color textColor = Color(0xFF333333);
  static const Color subtextColor = Color(0xFF757575);

  static final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.light);

  // --- TEMA PRINCIPAL DE LA APP ---
  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,

      // Estilo de la AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: backgroundColor,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: textColor,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: primaryColor),
      ),

      // Estilo del texto
      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: textColor,
        displayColor: textColor,
      ),

      // Estilo de los botones
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),

      // Estilo de los campos de formulario
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
      ),

      // Estilo de la barra de navegación inferior
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: primaryColor,
        unselectedItemColor: Color(0xFF9E9E9E),
        elevation: 10,
      ),

      // Estilo de las tarjetas (CORREGIDO)
      cardTheme: CardThemeData(
        elevation: 2,
        color: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: accentColor, // Usamos el accentColor como primario en modo oscuro
      scaffoldBackgroundColor: const Color(0xFF121212),
      
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF121212),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.poppins(
          color: const Color(0xFFFFFFFF),
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: accentColor),
      ),

      textTheme: GoogleFonts.poppinsTextTheme().apply(
        bodyColor: const Color(0xB3FFFFFF),
        displayColor: const Color(0xFFFFFFFF),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: GoogleFonts.poppins(fontWeight: FontWeight.w600),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: accentColor, width: 2),
        ),
      ),

      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        selectedItemColor: accentColor,
        unselectedItemColor: Color(0xFF757575),
        elevation: 10,
      ),

      cardTheme: CardThemeData(
        elevation: 4,
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
      ),
    );
  }
}
