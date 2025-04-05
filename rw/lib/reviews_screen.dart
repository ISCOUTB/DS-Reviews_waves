import 'package:flutter/material.dart';
import 'api_service.dart';

class ReviewsScreen extends StatefulWidget {
  final int id;
  final bool isMovie;
  final String title;

  const ReviewsScreen({
    super.key,
    required this.id,
    required this.isMovie,
    required this.title,
  });

  @override
  ReviewsScreenState createState() => ReviewsScreenState(); // Cambiado de _ReviewsScreenState a ReviewsScreenState
}

class ReviewsScreenState extends State<ReviewsScreen> { // Cambiado de _ReviewsScreenState a ReviewsScreenState
  final ApiService _apiService = ApiService();
  List<dynamic>? _reviews;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadReviews();
  }

  Future<void> _loadReviews() async {
    try {
      final reviews = await _apiService.fetchMovieReviews(widget.id);
      setState(() {
        _reviews = reviews;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Reseñas de ${widget.title}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text('Error: $_errorMessage'))
              : _buildReviewsList(),
    );
  }

  Widget _buildReviewsList() {
    if (_reviews == null || _reviews!.isEmpty) {
      return const Center(
        child: Text('No hay reseñas disponibles'),
      );
    }

    return ListView.builder(
      itemCount: _reviews!.length,
      itemBuilder: (context, index) {
        final review = _reviews![index];
        final author = review['author'] ?? 'Anónimo';
        final content = review['content'] ?? 'Sin contenido';
        final rating = review['author_details']?['rating'];

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      author,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    if (rating != null)
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          Text(' $rating/10'),
                        ],
                      ),
                  ],
                ),
                const Divider(),
                Text(content),
              ],
            ),
          ),
        );
      },
    );
  }
}
