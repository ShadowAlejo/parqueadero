import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Colores principales
class AppColors {
  static const Color primary = Color(0xFF0A6E39);
  static const Color secondary = Color(0xFFF4B400);
  static const Color error = Color(0xFFD32F2F);
  static const Color scaffoldBackground = Color(0xFFF5F5F5);
  static const Color primarySoft = Color(0xFFE8F5E9); // Verde pastel muy suave
  static const Color secondarySoft = Color(0xFFFFF8E1); // Amarillo pastel suave
  static const Color textPrimary = Color(0xFF212121); // Gris oscuro para textos
  static const Color textOnPrimary = Colors.white;
}

// Tema global de la app
final ThemeData appTheme = ThemeData(
  primaryColor: AppColors.primary,
  scaffoldBackgroundColor: AppColors.scaffoldBackground,
  colorScheme: ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.textOnPrimary,
    secondary: AppColors.secondary,
    onSecondary: AppColors.textPrimary,
    error: AppColors.error,
    onError: Colors.white,
    background: AppColors.primarySoft,
    onBackground: AppColors.textPrimary,
    surface: Colors.white,
    onSurface: AppColors.textPrimary,
  ),
  textTheme: GoogleFonts.robotoTextTheme().apply(
    bodyColor: AppColors.textPrimary,
    displayColor: AppColors.textPrimary,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.textOnPrimary,
    titleTextStyle: GoogleFonts.roboto(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: AppColors.textOnPrimary,
    ),
    iconTheme: IconThemeData(color: AppColors.textOnPrimary),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textOnPrimary,
      textStyle: GoogleFonts.roboto(fontSize: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      textStyle: GoogleFonts.roboto(fontSize: 16),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.primary),
    ),
    labelStyle: GoogleFonts.roboto(color: AppColors.textPrimary),
  ),
  cardColor: AppColors.primarySoft,
);
