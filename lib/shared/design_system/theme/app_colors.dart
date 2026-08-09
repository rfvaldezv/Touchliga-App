import 'package:flutter/material.dart';

/// Paleta oficial de colores de Touchliga.
///
/// Todos los colores de la aplicación deben obtenerse desde esta clase.
/// Evita utilizar Colors.blue, Colors.red, etc., directamente.
class AppColors {
  AppColors._();

  // ==========================================================================
  // Identidad Touchliga
  // ==========================================================================

  static const Color primary = Color(0xFF0D47A1);
  static const Color secondary = Color(0xFFFBC02D);

  // ==========================================================================
  // Estados
  // ==========================================================================

  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF57C00);
  static const Color error = Color(0xFFD32F2F);

  // ==========================================================================
  // Fondos
  // ==========================================================================

  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Color(0xFFFFFFFF);

  // ==========================================================================
  // Texto
  // ==========================================================================

  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFF9E9E9E);

  // ==========================================================================
  // Bordes
  // ==========================================================================

  static const Color border = Color(0xFFE0E0E0);
  static const Color divider = Color(0xFFEEEEEE);

  // ==========================================================================
  // Utilitarios
  // ==========================================================================

  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color transparent = Colors.transparent;
}
