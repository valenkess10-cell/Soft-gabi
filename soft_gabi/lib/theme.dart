import 'package:flutter/material.dart';

/// Colores tomados de la web (style.css) para que la app se vea igual.
class AppColors {
  static const rojo = Color(0xFFDA291C);
  static const rojoOscuro = Color(0xFFB81D13);
  static const amarillo = Color(0xFFFFBC0D);
  static const fondo = Color(0xFFF4F5F7);
  static const texto = Color(0xFF18181B);
  static const gris = Color(0xFF71717A);
  static const verde = Color(0xFF059669);
  static const verdeClaro = Color(0xFFECFDF5);
}

ThemeData buildTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: AppColors.rojo,
    primary: AppColors.rojo,
    secondary: AppColors.amarillo,
    surface: Colors.white,
  );
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: AppColors.fondo,
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      foregroundColor: AppColors.texto,
      elevation: 0,
      scrolledUnderElevation: 1,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: AppColors.rojo.withValues(alpha: 0.12),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: AppColors.rojo,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
  );
}
