import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

class ProfileStatsCard extends StatelessWidget {
  final int reviewsCount;
  final int favoritesCount;
  
  // Eliminamos los parámetros de seguidores y siguiendo
  const ProfileStatsCard({
    super.key,
    required this.reviewsCount,
    required this.favoritesCount,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildStatItem(context, 'Reseñas', reviewsCount, Icons.rate_review),
            _buildDivider(),
            _buildStatItem(context, 'Favoritos', favoritesCount, Icons.favorite),
          ],
        ),
      ),
    ).animate().slideY(
      begin: 0.3,
      end: 0,
      curve: Curves.easeOutQuad,
      duration: 500.ms,
    ).fadeIn(duration: 400.ms);
  }

  Widget _buildStatItem(BuildContext context, String label, int count, IconData icon) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).primaryColor),
          const SizedBox(height: 8),
          Text(
            count.toString(),
            style: GoogleFonts.poppins(
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDivider() {
    return SizedBox(
      height: 40,
      child: VerticalDivider(
        color: Colors.grey.withOpacity(0.3),
        thickness: 1,
        width: 20,
      ),
    );
  }
}