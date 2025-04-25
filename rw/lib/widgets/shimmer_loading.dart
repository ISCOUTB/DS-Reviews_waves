import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class ShimmerLoading extends StatelessWidget {
  final Widget child;
  final bool isLoading;
  final Color baseColor;
  final Color highlightColor;

  const ShimmerLoading({
    super.key,
    required this.child,
    required this.isLoading,
    this.baseColor = const Color(0xFFEEEEEE),
    this.highlightColor = const Color(0xFFFAFAFA),
  });

  @override
  Widget build(BuildContext context) {
    if (!isLoading) {
      return child;
    }
    
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    // Ajustar colores para modo oscuro si es necesario
    final effectiveBaseColor = isDarkMode ? const Color(0xFF3A3A3A) : baseColor;
    final effectiveHighlightColor = isDarkMode ? const Color(0xFF4A4A4A) : highlightColor;
    
    return Shimmer.fromColors(
      baseColor: effectiveBaseColor,
      highlightColor: effectiveHighlightColor,
      child: child,
    );
  }
}

// Widget para crear formas rectangulares con esquinas redondeadas para el shimmer
class ShimmerContainer extends StatelessWidget {
  final double width;
  final double height;
  final double borderRadius;

  const ShimmerContainer({
    super.key, 
    required this.width, 
    required this.height, 
    this.borderRadius = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(borderRadius),
      ),
    );
  }
}

// Widget para crear shimmers de tarjetas de películas
class MovieCardShimmer extends StatelessWidget {
  final double width;
  final double height;
  
  const MovieCardShimmer({
    super.key,
    this.width = 150,
    this.height = 200,
  });
  
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ShimmerContainer(
          width: width,
          height: height * 0.7,
          borderRadius: 10,
        ),
        const SizedBox(height: 8),
        ShimmerContainer(
          width: width * 0.8,
          height: 12,
          borderRadius: 4,
        ),
        const SizedBox(height: 4),
        ShimmerContainer(
          width: width * 0.5,
          height: 10,
          borderRadius: 4,
        ),
      ],
    );
  }
}

// Widget para crear shimmers de tarjetas de reseñas
class ReviewCardShimmer extends StatelessWidget {
  const ReviewCardShimmer({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 0),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.withOpacity(0.2), width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const ShimmerContainer(
                  width: 40,
                  height: 40,
                  borderRadius: 20,
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    ShimmerContainer(
                      width: 120,
                      height: 14,
                      borderRadius: 4,
                    ),
                    SizedBox(height: 4),
                    ShimmerContainer(
                      width: 80,
                      height: 10,
                      borderRadius: 4,
                    ),
                  ],
                ),
                const Spacer(),
                const ShimmerContainer(
                  width: 60,
                  height: 12,
                  borderRadius: 4,
                ),
              ],
            ),
            const SizedBox(height: 12),
            const ShimmerContainer(
              width: double.infinity,
              height: 70,
              borderRadius: 8,
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: const [
                ShimmerContainer(
                  width: 24,
                  height: 24,
                  borderRadius: 12,
                ),
                SizedBox(width: 8),
                ShimmerContainer(
                  width: 24,
                  height: 24,
                  borderRadius: 12,
                ),
                SizedBox(width: 8),
                ShimmerContainer(
                  width: 24,
                  height: 24,
                  borderRadius: 12,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Widget para crear shimmers de tarjetas de información de perfil
class ProfileInfoShimmer extends StatelessWidget {
  const ProfileInfoShimmer({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        children: [
          const ShimmerContainer(
            width: 120,
            height: 120,
            borderRadius: 60,
          ),
          const SizedBox(height: 16),
          const ShimmerContainer(
            width: 180,
            height: 20,
            borderRadius: 6,
          ),
          const SizedBox(height: 8),
          const ShimmerContainer(
            width: 240,
            height: 14,
            borderRadius: 6,
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(
              4,
              (index) => Column(
                children: [
                  const ShimmerContainer(
                    width: 40,
                    height: 40,
                    borderRadius: 20,
                  ),
                  const SizedBox(height: 8),
                  const ShimmerContainer(
                    width: 60,
                    height: 12,
                    borderRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}