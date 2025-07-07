import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Colores principales
class AppColors {
  static const Color primary = Color(0xFFA5BFA6); // Verde grisáceo opaco
  static const Color secondary =
      Color(0xFFFFF9C4); // Amarillo muy pálido, casi crema
  static const Color error = Color(0xFFEF9A9A); // Rojo pastel opaco
  static const Color scaffoldBackground =
      Color(0xFFF4F6F7); // Gris muy claro, casi blanco
  static const Color primarySoft = Color(0xFFD7E3D8); // Verde muy pálido, opaco
  static const Color secondarySoft = Color(0xFFFFFDE7); // Amarillo muy pálido
  static const Color textPrimary =
      Color(0xFF495057); // Gris oscuro opaco para textos
  static const Color textOnPrimary =
      Color(0xFF495057); // Gris oscuro opaco sobre botones claros
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
    onError: AppColors.textOnPrimary,
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
    foregroundColor: AppColors.textPrimary,
    titleTextStyle: GoogleFonts.roboto(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: AppColors.textPrimary,
    ),
    iconTheme: IconThemeData(color: AppColors.textPrimary),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.textPrimary,
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
    fillColor: AppColors.primarySoft,
    filled: true,
  ),
  cardColor: AppColors.primarySoft,
);

// Estilo para botones secundarios (informativos)
final ButtonStyle infoButtonStyle = ElevatedButton.styleFrom(
  backgroundColor: AppColors.secondarySoft,
  foregroundColor: AppColors.textPrimary,
  textStyle: GoogleFonts.roboto(fontSize: 16),
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(12),
    side: BorderSide(color: AppColors.secondary, width: 1),
  ),
  elevation: 6, // Sombra visible y suave
  shadowColor: Colors.black.withOpacity(0.25),
);

// Tema oscuro de la app
final ThemeData darkAppTheme = ThemeData(
  brightness: Brightness.dark,
  primaryColor: Color(0xFF181A20), // Fondo AppBar y botones
  scaffoldBackgroundColor: Color(0xFF121212),
  colorScheme: ColorScheme(
    brightness: Brightness.dark,
    primary: Color(0xFF181A20),
    onPrimary: Colors.white,
    secondary: Color(0xFF23272A),
    onSecondary: Colors.white,
    error: Color(0xFFEF9A9A),
    onError: Colors.black,
    background: Color(0xFF121212),
    onBackground: Colors.white,
    surface: Color(0xFF23272A),
    onSurface: Colors.white,
  ),
  textTheme: GoogleFonts.robotoTextTheme(ThemeData.dark().textTheme).apply(
    bodyColor: Colors.white,
    displayColor: Colors.white,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: Color(0xFF181A20),
    foregroundColor: Colors.white,
    titleTextStyle: GoogleFonts.roboto(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: Colors.white,
    ),
    iconTheme: IconThemeData(color: Colors.white),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Color(0xFF23272A),
      foregroundColor: Colors.white,
      textStyle: GoogleFonts.roboto(fontSize: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      elevation: 4,
      shadowColor: Colors.black.withOpacity(0.4),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Color(0xFF90CAF9),
      textStyle: GoogleFonts.roboto(fontSize: 16),
    ),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Color(0xFF90CAF9)),
    ),
    labelStyle: GoogleFonts.roboto(color: Colors.white),
    fillColor: Color(0xFF23272A),
    filled: true,
  ),
  cardColor: Color(0xFF23272A),
  iconTheme: IconThemeData(color: Colors.white),
  dividerColor: Colors.white24,
);
