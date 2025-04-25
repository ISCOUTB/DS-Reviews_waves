import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rw/widgets/shimmer_loading.dart';

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

    return MasonryGridView.count(
      padding: const EdgeInsets.all(16),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
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
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        itemCount: 6,
        itemBuilder: (context, index) {
          final height = index % 3 == 0 ? 280.0 : 230.0;
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
    // Variación de altura para crear un efecto visual más interesante
    final heightMultiplier = index % 3 == 0 ? 1.2 : 1.0;
    
    return GestureDetector(
      onTap: onMovieTap != null ? () => onMovieTap!(movie['id']) : null,
      child: Hero(
        tag: 'favorite-${movie['id']}',
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                // Póster de la película
                AspectRatio(
                  aspectRatio: 2/3 * heightMultiplier,
                  child: CachedNetworkImage(
                    imageUrl: movie['posterUrl'] ?? 'https://via.placeholder.com/300x450?text=Sin+Imagen',
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Colors.grey[300],
                      child: const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image),
                    ),
                  ),
                ),
                
                // Gradiente para mejorar la visibilidad del título
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.6),
                        ],
                        stops: const [0.7, 1.0],
                      ),
                    ),
                  ),
                ),
                
                // Información de la película
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          movie['title'] ?? 'Título desconocido',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            shadows: [
                              const Shadow(
                                offset: Offset(1, 1),
                                blurRadius: 2,
                                color: Colors.black,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (movie['year'] != null)
                          Text(
                            movie['year'].toString(),
                            style: GoogleFonts.poppins(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12,
                              shadows: [
                                const Shadow(
                                  offset: Offset(1, 1),
                                  blurRadius: 2,
                                  color: Colors.black,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Icono de favorito
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.redAccent,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.favorite,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(delay: (100 * index).ms, duration: 400.ms).scale(
      begin: const Offset(0.9, 0.9),
      end: const Offset(1, 1),
      duration: 400.ms,
      delay: (100 * index).ms,
      curve: Curves.easeOutQuad,
    );
  }
}