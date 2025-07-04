import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Colores principales
class AppColors {
  static const Color primary = Color(0xFF0A6E39);
  static const Color secondary = Color(0xFFF4B400);
  static const Color error = Color(0xFFD32F2F);
  static const Color scaffoldBackground = Color(0xFFF5F5F5);
}

// Tema global de la app
final ThemeData appTheme = ThemeData(
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.scaffoldBackground,
  colorScheme: ColorScheme.fromSwatch().copyWith(
    primary: AppColors.primary,
    secondary: AppColors.secondary,
    error: AppColors.error,
  ),
  textTheme: GoogleFonts.robotoTextTheme(),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: Colors.white,
    titleTextStyle: GoogleFonts.roboto(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: Colors.white,
      textStyle: GoogleFonts.roboto(fontSize: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.primary),
    ),
    labelStyle: GoogleFonts.roboto(color: Colors.black87),
  ),
);
