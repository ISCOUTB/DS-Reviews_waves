import 'package:flutter/material.dart';

/// Utilidades para el manejo seguro de colores
class ColorUtils {
  /// Convierte una opacidad (0.0-1.0) a un valor alpha seguro (0-255)
  static int opacityToAlpha(double opacity) {
    final safeOpacity = opacity.clamp(0.0, 1.0);
    return (safeOpacity * 255).round();
  }

  /// Crea un color con opacidad segura
  static Color withSafeOpacity(Color color, double opacity) {
    final safeOpacity = opacity.clamp(0.0, 1.0);
    return color.withOpacity(safeOpacity);
  }

  /// Versión segura de withAlpha que maneja valores fuera de rango
  static Color withSafeAlpha(Color color, int alpha) {
    final safeAlpha = alpha.clamp(0, 255);
    return color.withAlpha(safeAlpha);
  }
}