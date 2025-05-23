// Archivo temporal para avatar_service corregido
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Servicio para proporcionar avatares simplificados con imágenes reconocibles
class SimpleAvatarService {
  // URL base para avatares usando DiceBear API
  static const String baseUrl = 'https://api.dicebear.com/7.x/';
  
  // Información de los avatares disponibles con nombres descriptivos
  static const List<Map<String, String>> avatarInfo = [
    // Avatares originales
    {
      'url': 'bottts/svg?seed=Felix&backgroundColor=b6e3f4',
      'name': 'Robot Azul'
    },
    {
      'url': 'lorelei/svg?seed=Tiger&backgroundColor=ffd700',
      'name': 'Tigre'
    },
    {
      'url': 'lorelei/svg?seed=Lion&backgroundColor=ffa500',
      'name': 'León'
    },
    {
      'url': 'notionists/svg?seed=Kitty&backgroundColor=ffb6c1',
      'name': 'Gato Rosa'
    },
    {
      'url': 'notionists/svg?seed=Foxy&backgroundColor=ff6347',
      'name': 'Zorro Naranja'
    },
    
    // Nuevos avatares de animales y personajes
    {
      'url': 'lorelei/svg?seed=Elephant&backgroundColor=a4c2f4',
      'name': 'Elefante Azul'
    },
    {
      'url': 'lorelei/svg?seed=Panda&backgroundColor=d5f5e3',
      'name': 'Panda Verde'
    },
    {
      'url': 'notionists/svg?seed=Bunny&backgroundColor=fadbd8',
      'name': 'Conejo Rosa'
    },
    {
      'url': 'bottts/svg?seed=Roboto&backgroundColor=aed6f1',
      'name': 'Robot Celeste'
    },
    {
      'url': 'lorelei/svg?seed=Koala&backgroundColor=d7bde2',
      'name': 'Koala Lila'
    },
    {
      'url': 'lorelei/svg?seed=Monkey&backgroundColor=f9e79f',
      'name': 'Mono Amarillo'
    },
    {
      'url': 'notionists/svg?seed=Penguin&backgroundColor=d6eaf8',
      'name': 'Pingüino Azul'
    },
    {
      'url': 'bottts/svg?seed=TechBot&backgroundColor=f5cba7',
      'name': 'Robot Naranja'
    },
    {
      'url': 'lorelei/svg?seed=Owl&backgroundColor=d2b4de',
      'name': 'Búho Morado'
    },
    {
      'url': 'lorelei/svg?seed=Giraffe&backgroundColor=fdebd0',
      'name': 'Jirafa Amarilla'
    },
    {
      'url': 'notionists/svg?seed=Duck&backgroundColor=abebc6',
      'name': 'Pato Verde'
    },
    {
      'url': 'lorelei/svg?seed=Shark&backgroundColor=85c1e9',
      'name': 'Tiburón Azul'
    },
    {
      'url': 'bottts/svg?seed=CyberBuddy&backgroundColor=f9ebea',
      'name': 'Robot Rosa'
    },
    {
      'url': 'lorelei/svg?seed=Wolf&backgroundColor=a9cce3',
      'name': 'Lobo Azul'
    },
    {
      'url': 'notionists/svg?seed=Raccoon&backgroundColor=e8daef',
      'name': 'Mapache Lila'
    },
    {
      'url': 'bottts/svg?seed=FriendlyBot&backgroundColor=f2d7d5',
      'name': 'Robot Rosado'
    },
    {
      'url': 'lorelei/svg?seed=Bear&backgroundColor=d5f5e3',
      'name': 'Oso Verde'
    },
    {
      'url': 'notionists/svg?seed=Squirrel&backgroundColor=fad7a0',
      'name': 'Ardilla Naranja'
    },
    {
      'url': 'lorelei/svg?seed=Frog&backgroundColor=abebc6',
      'name': 'Rana Verde'
    },
    {
      'url': 'notionists/svg?seed=Octopus&backgroundColor=d6eaf8',
      'name': 'Pulpo Azul'
    }
  ];
  
  // Obtiene una lista de URLs para todos los avatares de animales/caricaturas
  static List<String> getAvatarOptions() {
    List<String> avatarUrls = [];
    for (final avatar in avatarInfo) {
      avatarUrls.add('$baseUrl${avatar['url']}');
    }
    return avatarUrls;
  }
  
  // Obtiene el nombre descriptivo de un avatar dado su URL
  static String getAvatarName(String avatarUrl) {
    for (final avatar in avatarInfo) {
      if (avatarUrl.contains(avatar['url']!)) {
        return avatar['name']!;
      }
    }
    return 'Avatar';
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
      height: MediaQuery.of(context).size.height * 0.8, // Aumentamos la altura para mostrar más avatares
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51), // 0.2 * 255 = 51
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
              'Elige uno de estos 25 avatares de animales o personajes para tu perfil:',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          
          const SizedBox(height: 20),
          
          // Grid de avatares - Configurado para mostrar 25 avatares
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GridView.builder(
                padding: const EdgeInsets.only(bottom: 10),
                // Hacemos el grid scrollable para mostrar todos los avatares
                physics: const BouncingScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4, // Cambiamos a 4 columnas para mejor visualización
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16, // Aumentamos un poco el espacio vertical
                  childAspectRatio: 0.8, // Ajustamos para que quepa el nombre
                ),
                itemCount: avatarOptions.length,
                itemBuilder: (context, index) {
                  final avatarUrl = avatarOptions[index];
                  bool isSelected = selectedAvatar == avatarUrl;
                  
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Expanded(
                        child: GestureDetector(
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
                        ),
                      ),
                      
                      // Nombre del avatar
                      const SizedBox(height: 4),
                      Text(
                        getAvatarName(avatarUrl),
                        style: GoogleFonts.poppins(
                          fontSize: 10,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected 
                              ? Theme.of(context).primaryColor 
                              : Theme.of(context).textTheme.bodyMedium?.color,
                        ),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
          
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
