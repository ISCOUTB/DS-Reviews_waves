import 'package:flutter/material.dart';

// Estos son métodos auxiliares por si se necesitan en el futuro
// Para usar con la nueva implementación simplificada de avatares

// Variable para guardar referencia a un índice de categoría (ya no se usa)
int _selectedCategoryIndex = 0;

// Cambiar de categoría de avatares - Ya no se usa en la implementación simplificada
void changeCategory(int index, Function(void Function()) setState) {
  setState(() {
    _selectedCategoryIndex = index;
  });
}

// Obtener el icono adecuado para cada categoría - Ya no se usa
IconData getCategoryIcon(String category) {
  return Icons.image;
}
