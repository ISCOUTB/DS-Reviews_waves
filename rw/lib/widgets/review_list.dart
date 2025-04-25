import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:rw/widgets/shimmer_loading.dart';

class UserReviewList extends StatelessWidget {
  final List<Map<String, dynamic>> reviews;
  final bool isLoading;
  final Function(String reviewId)? onReviewTap;

  const UserReviewList({
    super.key,
    required this.reviews,
    this.isLoading = false,
    this.onReviewTap,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (reviews.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: reviews.length,
      itemBuilder: (context, index) {
        final review = reviews[index];
        return _buildReviewCard(context, review, index);
      },
    );
  }

  Widget _buildLoadingState() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: 4,
      itemBuilder: (context, index) => const Padding(
        padding: EdgeInsets.only(bottom: 16.0),
        child: ShimmerLoading(
          isLoading: true,
          child: ReviewCardShimmer(),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.rate_review_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aún no has publicado reseñas',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '¡Comienza a compartir tus opiniones!',
            textAlign: TextAlign.center,
            style: GoogleFonts.poppins(
              color: Colors.grey[500],
            ),
          ),
        ],
      ).animate().fadeIn(delay: 300.ms, duration: 600.ms),
    );
  }

  Widget _buildReviewCard(BuildContext context, Map<String, dynamic> review, int index) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onReviewTap != null ? () => onReviewTap!(review['id']) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Película y rating
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Poster de la película
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: review['moviePoster'] ?? 'https://via.placeholder.com/100x150?text=Sin+Imagen',
                      width: 70,
                      height: 100,
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
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Información de la película y rating
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          review['movieTitle'] ?? 'Título desconocido',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        
                        Text(
                          review['movieYear']?.toString() ?? '',
                          style: GoogleFonts.poppins(
                            color: Colors.grey[600],
                            fontSize: 12,
                          ),
                        ),
                        
                        const SizedBox(height: 8),
                        
                        // Estrellas de calificación
                        Row(
                          children: [
                            ...List.generate(5, (i) {
                              final rating = (review['rating'] as num?)?.toInt() ?? 0;
                              return Icon(
                                i < rating ? Icons.star : Icons.star_border,
                                color: i < rating ? Colors.amber : Colors.grey,
                                size: 18,
                              );
                            }),
                            const SizedBox(width: 6),
                            Text(
                              '${review['rating']?.toString() ?? '0'}/5',
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 4),
                        
                        // Fecha de la reseña
                        Text(
                          review['date'] ?? 'Fecha desconocida',
                          style: GoogleFonts.poppins(
                            fontSize: 11,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 10),
              
              // Línea divisoria
              Divider(color: Colors.grey[300]),
              
              const SizedBox(height: 6),
              
              // Contenido de la reseña
              Text(
                review['content'] ?? 'No hay contenido disponible',
                style: GoogleFonts.poppins(fontSize: 13),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              
              if (review['content']?.length > 100)
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: onReviewTap != null ? () => onReviewTap!(review['id']) : null,
                    style: TextButton.styleFrom(
                      minimumSize: Size.zero,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: Text(
                      'Ver más',
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    ).animate().fadeIn(delay: (100 * index).ms, duration: 300.ms).slideY(
      begin: 0.1,
      end: 0,
      duration: 300.ms,
      delay: (100 * index).ms,
      curve: Curves.easeOutQuad,
    );
  }
}