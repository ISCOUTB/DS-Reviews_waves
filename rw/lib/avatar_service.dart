import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Servicio para proporcionar avatares simplificados
class SimpleAvatarService {
  // URL base para avatares de GitHub (una alternativa a DiceBear)
  static const String baseUrl = 'https://avatars.githubusercontent.com/u/';
  
  // IDs de usuarios de GitHub para crear avatares consistentes
  static const List<int> defaultAvatarIds = [1, 90, 175, 250, 300];
  
  // Obtiene una lista de 5 URLs para avatares 
  static List<String> getAvatarOptions() {
    List<String> avatarUrls = [];
    for (final userId in defaultAvatarIds) {
      avatarUrls.add('$baseUrl$userId?s=150');
    }
    return avatarUrls;
  }
  
  // Convierte un valor de opacidad (0.0-1.0) a valor alpha (0-255)
  static int opacityToAlpha(double opacity) {
    return (opacity * 255).round();
  }
  
  // Construye un selector de avatares como un BottomSheet
  static Widget buildAvatarSelector({
    required BuildContext context,
    required String selectedAvatar,
    required List<String> avatarOptions,
    required Function(String) onAvatarSelected,
    required VoidCallback onSave,
  }) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera del selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selecciona tu avatar',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Vista previa del avatar seleccionado
          Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Hero(
                tag: 'avatar_preview',
                child: Material(
                  elevation: 6,
                  shape: const CircleBorder(),
                  shadowColor: Theme.of(context).primaryColor.withAlpha(opacityToAlpha(0.4)),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    child: ClipOval(
                      child: CachedNetworkImage(
                        imageUrl: selectedAvatar,
                        placeholder: (context, url) => const SizedBox(
                          width: 30, 
                          height: 30, 
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                        width: 120,
                        height: 120,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          
          // Texto explicativo
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'Elige uno de estos avatares para tu perfil:',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Grid de avatares - Simplificado a solo 5 opciones
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1,
              ),
              itemCount: avatarOptions.length,
              itemBuilder: (context, index) {
                final avatarUrl = avatarOptions[index];
                bool isSelected = selectedAvatar == avatarUrl;
                
                return GestureDetector(
                  onTap: () => onAvatarSelected(avatarUrl),
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[200],
                      boxShadow: isSelected 
                          ? [
                              BoxShadow(
                                color: Theme.of(context).primaryColor.withAlpha(opacityToAlpha(0.2)),
                                blurRadius: 4,
                                spreadRadius: 1,
                              ),
                            ]
                          : [],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Stack(
                        children: [
                          // Avatar previamente cargado
                          Positioned.fill(
                            child: CachedNetworkImage(
                              imageUrl: avatarUrl,
                              placeholder: (context, url) => Container(
                                color: Colors.grey[300],
                                child: const Center(
                                  child: SizedBox(
                                    width: 20, 
                                    height: 20, 
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.error, size: 20),
                              ),
                              fit: BoxFit.cover,
                            ),
                          ),
                          
                          // Indicador de selección
                          if (isSelected)
                            Positioned(
                              top: 4,
                              right: 4,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).primaryColor,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  color: Colors.white,
                                  size: 12,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          const Spacer(),
          
          // Botón de guardar
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(
                  'Guardar avatar',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}