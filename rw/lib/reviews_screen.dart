import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'review_service.dart';
import 'write_review_screen.dart';

class ReviewsScreen extends StatefulWidget {
  final int movieId;
  final String movieTitle;
  final String posterPath;
  final List<String> genres;

  const ReviewsScreen({
    super.key, 
    required this.movieId,
    this.movieTitle = '',
    this.posterPath = '',
    this.genres = const [],
  });

  @override
  State<ReviewsScreen> createState() => _ReviewsScreenState();
}

class _ReviewsScreenState extends State<ReviewsScreen> {
  final ReviewService _reviewService = ReviewService();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late Stream<QuerySnapshot> _reviewsStream;

  @override
  void initState() {
    super.initState();
    _reviewsStream = _reviewService.getReviewsForMedia(widget.movieId.toString());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reseñas'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _auth.currentUser != null 
            ? () => _showWriteReview()
            : () => _showLoginRequired(),
        label: const Text('Escribir reseña'),
        icon: const Icon(Icons.rate_review),
      ),
      body: _buildFirestoreReviews(),
    );
  }

  Widget _buildFirestoreReviews() {
    return StreamBuilder<QuerySnapshot>(
      stream: _reviewsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingState();
        }
        
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error.toString());
        }
        
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildEmptyState();
        }
        
        final reviews = snapshot.data!.docs;
        
        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: reviews.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final reviewData = reviews[i].data() as Map<String, dynamic>;
            final reviewId = reviews[i].id;
            return _buildReviewCard(reviewData, reviewId, true);
          },
        );
      },
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                Theme.of(context).primaryColor,
              ),
            ),
          ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 20),
          const Text('Cargando reseñas...').animate().fadeIn(),
        ],
      ),
    );
  }
  
  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 60,
            color: Colors.red.shade400,
          ).animate().shake(),
          const SizedBox(height: 16),
          Text(
            'Error al cargar las reseñas',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            error,
            style: Theme.of(context).textTheme.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _reviewsStream = _reviewService.getReviewsForMedia(widget.movieId.toString());
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Intentar de nuevo'),
          ),
        ],
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
            color: Colors.grey.shade400,
          ).animate().fadeIn(),
          const SizedBox(height: 16),
          Text(
            'No hay reseñas aún',
            style: Theme.of(context).textTheme.titleMedium,
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 8),
          Text(
            '¡Sé el primero en escribir una reseña!',
            style: Theme.of(context).textTheme.bodyMedium,
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _auth.currentUser != null 
                ? () => _showWriteReview()
                : () => _showLoginRequired(),
            icon: const Icon(Icons.create),
            label: const Text('Escribir reseña'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ).animate().fadeIn(delay: 400.ms).scale(delay: 400.ms, duration: 400.ms),
        ],
      ),
    );
  }
  
  Widget _buildReviewCard(Map<String, dynamic> reviewData, String reviewId, bool isFirestore) {
    final String authorName = reviewData['authorName'] ?? 'Usuario anónimo';
    final String authorPhoto = reviewData['authorPhotoURL'] ?? '';
    final String content = reviewData['content'] ?? '';
    final String title = reviewData['title'] ?? 'Reseña de película';
    final double rating = ((reviewData['rating'] ?? 0) as num).toDouble();
    
    String formattedDate = '';
    if (reviewData['createdAt'] is Timestamp) {
      final timestamp = reviewData['createdAt'] as Timestamp;
      formattedDate = DateFormat.yMd().add_jm()
          .format(timestamp.toDate());
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (authorPhoto.isNotEmpty)
                  CircleAvatar(
                    radius: 20,
                    backgroundImage: NetworkImage(authorPhoto),
                    backgroundColor: Colors.grey.shade200,
                  )
                else
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey.shade200,
                    child: Text(
                      authorName.isNotEmpty ? authorName[0].toUpperCase() : '?',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    ),
                  ),
                  
                const SizedBox(width: 10),
                
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorName,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (formattedDate.isNotEmpty)
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                    ],
                  ),
                ),
                
                _buildRatingIndicator(rating),
              ],
            ),
            
            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 12),
            
            if (title.isNotEmpty && title != 'Reseña de película')
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            
            const SizedBox(height: 8),
            
            Text(
              content,
              style: const TextStyle(fontSize: 15),
            ),
            
            if (_auth.currentUser != null && reviewData['userId'] == _auth.currentUser!.uid)
              _buildReviewActions(reviewId),
          ],
        ),
      ),
    );
  }
  
  Widget _buildRatingIndicator(double rating) {
    final Color ratingColor = _getRatingColor(rating);
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: ratingColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: ratingColor,
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.star,
            size: 16,
            color: ratingColor,
          ),
          const SizedBox(width: 4),
          Text(
            rating.toStringAsFixed(1),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: ratingColor,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildReviewActions(String reviewId) {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          TextButton.icon(
            onPressed: () => _deleteReview(reviewId),
            icon: const Icon(Icons.delete_outline, size: 16),
            label: const Text('Eliminar'),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              minimumSize: Size.zero,
              foregroundColor: Colors.red,
            ),
          ),
        ],
      ),
    );
  }
  
  Color _getRatingColor(double rating) {
    if (rating >= 4) return Colors.green;
    if (rating >= 2.5) return Colors.orange;
    if (rating > 0) return Colors.red;
    return Colors.grey;
  }
  
  void _showWriteReview() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => WriteReviewScreen(
          movieId: widget.movieId,
          movieTitle: widget.movieTitle,
          posterPath: widget.posterPath,
          genres: widget.genres,
        ),
      ),
    );
  }
  
  void _showLoginRequired() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Debes iniciar sesión para escribir una reseña'),
        duration: Duration(seconds: 3),
      ),
    );
  }
  
  void _deleteReview(String reviewId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Eliminar reseña'),
          content: const Text('¿Estás seguro de que quieres eliminar esta reseña? Esta acción no se puede deshacer.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('CANCELAR'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Eliminando reseña...'),
                    duration: Duration(seconds: 1),
                  ),
                );
                
                FirebaseFirestore.instance
                  .collection('reviews')
                  .doc(reviewId)
                  .delete()
                  .then((_) {
                    if (mounted) {
                      setState(() {
                        _reviewsStream = _reviewService.getReviewsForMedia(widget.movieId.toString());
                      });
                    }
                  })
                  .catchError((error) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('No se pudo eliminar. Intenta de nuevo.'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    }
                  });
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('ELIMINAR'),
            ),
          ],
        );
      },
    );
  }
}
