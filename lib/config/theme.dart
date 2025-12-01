import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart'; // <--- 1. IMPORTAR

class CoritaTheme {
  // Colores (Los mismos que tenías)
  static const Color primaryColor = Color(0xFF880E4F); // Magenta
  static const Color secondaryColor = Color(0xFF00897B); // Teal
  static const Color backgroundColor =
      Color(0xFFF5F7FA); // Gris azulado suave (Mejorado)
  static const Color errorColor = Color(0xFFD32F2F);

  static ThemeData get lightTheme {
    // Base del tema
    final baseTheme = ThemeData(
      useMaterial3: true,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        primary: primaryColor,
        secondary: secondaryColor,
        background: backgroundColor,
      ),

      // Estilos de botones y campos (Igual que antes)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
          textStyle: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide.none), // Más redondo
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20),
            borderSide: BorderSide(color: primaryColor, width: 2)),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
            color: primaryColor, fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );

    // --- 2. APLICAR LA TIPOGRAFÍA ---
    // Esto toma el tema base y le inyecta la fuente Nunito a todo
    return baseTheme.copyWith(
      textTheme: GoogleFonts.poppinsTextTheme(baseTheme.textTheme),
    );
  }
}
