import 'package:flutter/material.dart';

// Estos son métodos auxiliares por si se necesitan en el futuro
// Para usar con la nueva implementación simplificada de avatares

// Variable para guardar referencia a un índice de categoría (ya no se usa)
// Removed unused variable
// ignore: unused_element
int _selectedCategoryIndex = 0; // Definida para evitar errores en el código obsoleto

// Cambiar de categoría de avatares - Ya no se usa en la implementación simplificada
// ignore: unused_element
void changeCategory(int index, Function(void Function()) setState) {
  setState(() {
    _selectedCategoryIndex = index;
  });
}

// Obtener el icono adecuado para cada categoría - Ya no se usa
// ignore: unused_element
IconData getCategoryIcon(String category) {
  return Icons.image;
}
