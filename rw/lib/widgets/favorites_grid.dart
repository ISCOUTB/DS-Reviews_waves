import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rw/widgets/shimmer_loading.dart';
import 'package:shimmer/shimmer.dart';

class FavoritesGrid extends StatelessWidget {
  final List<Map<String, dynamic>> favorites;
  final bool isLoading;
  final Function(String movieId)? onMovieTap;
  
  const FavoritesGrid({
    super.key,
    required this.favorites,
    this.isLoading = false,
    this.onMovieTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (favorites.isEmpty) {
      return _buildEmptyState();
    }

    // Aumentamos a 5 columnas para hacer las imágenes aún más pequeñas
    return AlignedGridView.count(
      padding: const EdgeInsets.all(4),
      crossAxisCount: 5, // Aumentado a 5 columnas
      mainAxisSpacing: 4, // Reducido el espaciado
      crossAxisSpacing: 4, // Reducido el espaciado
      itemCount: favorites.length,
      itemBuilder: (context, index) {
        final movie = favorites[index];
        return _buildMovieCard(context, movie, index);
      },
    );
  }

  Widget _buildLoadingState() {
    return ShimmerLoading(
      isLoading: true,
      child: MasonryGridView.count(
        padding: const EdgeInsets.all(4),
        crossAxisCount: 5, // También aumentamos las columnas en el estado de carga
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
        itemCount: 15, // Aumentamos el número para mostrar más elementos en carga
        itemBuilder: (context, index) {
          final height = index % 3 == 0 ? 110.0 : 90.0; // Reducción significativa de altura
          return MovieCardShimmer(height: height);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.favorite_border,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Sin películas favoritas',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Marca películas como favoritas para verlas aquí',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.grey[500],
            ),
          ),
        ],
      ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
    );
  }

  Widget _buildMovieCard(BuildContext context, Map<String, dynamic> movie, int index) {
    return GestureDetector(
      onTap: onMovieTap != null ? () => onMovieTap!(movie['id']) : null,
      child: Hero(
        tag: 'favorite-${movie['id']}',
        child: Card(
          elevation: 1, // Reducimos aún más la elevación
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4), // Bordes más pequeños
          ),
          clipBehavior: Clip.antiAlias,
          margin: EdgeInsets.zero, // Sin margen para aprovechar mejor el espacio
          child: Stack(
            children: [
              // Póster de la película con tamaño significativamente reducido
              AspectRatio(
                aspectRatio: 2/3,
                child: CachedNetworkImage(
                  imageUrl: movie['posterUrl'] ?? 'https://via.placeholder.com/300x450?text=Sin+Imagen',
                  fit: BoxFit.cover,
                  // Usamos una imagen más pequeña (w92 en vez de w185 o w300)
                  imageBuilder: (context, imageProvider) => Container(
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: imageProvider,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(color: Colors.grey[300]),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: Colors.grey[800],
                    child: const Icon(
                      Icons.broken_image,
                      color: Colors.white70,
                      size: 16, // Icono aún más pequeño
                    ),
                  ),
                  memCacheHeight: 120, // Limitar tamaño en caché para optimizar rendimiento
                ),
              ),
              
              // Overlay oscuro discreto para dar mejor contraste a los elementos
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,                      colors: [
                        Colors.transparent,
                        Colors.black.withAlpha(153), // 0.6 * 255 = 153
                      ],
                      stops: const [0.7, 1.0],
                    ),
                  ),
                ),
              ),
              
              // Banner más pequeño para el tipo (P/S)
              Positioned(
                top: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1), // Padding mínimo
                  decoration: BoxDecoration(
                    color: movie['tipo'] == 'pelicula' ? Colors.redAccent.withAlpha(204) : Colors.blueAccent.withAlpha(204), // 0.8 * 255 = 204
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(3),
                    ),
                  ),
                  child: Text(
                    movie['tipo'] == 'pelicula' ? 'P' : 'S', // Mantener la letra única
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 6, // Texto aún más pequeño
                    ),
                  ),
                ),
              ),
              
              // Título en la parte inferior, aún más compacto
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(2), // Padding mínimo
                  child: Text(
                    movie['titulo'] ?? 'Sin título',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      color: Colors.white,
                      fontWeight: FontWeight.w500,
                      fontSize: 6, // Texto aún más pequeño
                      shadows: [
                        const Shadow(
                          offset: Offset(0.5, 0.5),
                          blurRadius: 0.5,
                          color: Colors.black,
                        ),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              
              // Añadimos una pequeña estrella como indicador visual
              if (movie['rating'] != null && movie['rating'] > 0)
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(128), // 0.5 * 255 = 128
                      borderRadius: const BorderRadius.only(
                        bottomRight: Radius.circular(3),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.star,
                          size: 5,
                          color: _getRatingColor(movie['rating'].toDouble()),
                        ),
                        Text(
                          movie['rating'].toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 5,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ).animate()
       .fadeIn(duration: 180.ms, delay: (20 * index).ms)
       .slideY(begin: 0.05, end: 0, duration: 180.ms, delay: (20 * index).ms)
       .scale(
          begin: const Offset(0.97, 0.97),
          end: const Offset(1, 1),
          duration: 180.ms, 
          delay: (20 * index).ms,
       ),
    );
  }
  
  // Método para determinar el color según la puntuación
  Color _getRatingColor(double rating) {
    if (rating >= 7.5) {
      return Colors.green.shade400;
    } else if (rating >= 6) {
      return Colors.amber.shade400;
    } else {
      return Colors.redAccent;
    }
  }
}

// Widget para mostrar un shimmer en forma de tarjeta mientras se cargan los datos
class MovieCardShimmer extends StatelessWidget {
  final double height;
  
  const MovieCardShimmer({super.key, required this.height});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4), // Bordes más pequeños
      ),
    );
  }
}