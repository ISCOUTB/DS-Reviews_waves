import 'package:flutter/material.dart';
import 'api_service.dart';
import 'reviews_screen.dart'; // Si tienes una pantalla de reseñas

class DetailScreen extends StatefulWidget {
  final int id;
  final bool isMovie; // true si es película, false si es serie

  const DetailScreen({super.key, required this.id, required this.isMovie});

  @override
  DetailScreenState createState() => DetailScreenState();
}

class DetailScreenState extends State<DetailScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _details;
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  Future<void> _loadDetails() async {
    try {
      if (widget.isMovie) {
        _details = await _apiService.fetchMovieDetails(widget.id);
      } else {
        _details = await _apiService.fetchTVShowDetails(widget.id);
      }
      setState(() {
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
        title: Text(widget.isMovie ? 'Detalles de la Película' : 'Detalles de la Serie'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage.isNotEmpty
              ? Center(child: Text('Error: $_errorMessage'))
              : _buildDetailContent(),
    );
  }

  Widget _buildDetailContent() {
    if (_details == null) {
      return const Center(child: Text('No se encontraron detalles'));
    }

    final String title = widget.isMovie ? _details!['title'] ?? 'Sin título' : _details!['name'] ?? 'Sin título';
    final String? posterPath = _details!['poster_path'];
    final String overview = _details!['overview'] ?? 'No hay sinopsis disponible';
    final List<dynamic> genres = _details!['genres'] ?? [];
    final String genreNames = genres.isNotEmpty 
        ? genres.map((genre) => genre['name']).join(', ')
        : 'Sin géneros';
    final double voteAverage = (_details!['vote_average'] ?? 0.0).toDouble();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Imagen y detalles básicos
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Poster
              if (posterPath != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    'https://image.tmdb.org/t/p/w300$posterPath',
                    height: 200,
                    width: 133,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        Container(
                          height: 200,
                          width: 133,
                          color: Colors.grey.shade200,
                          child: const Icon(Icons.error, size: 50),
                        ),
                  ),
                )
              else
                Container(
                  height: 200,
                  width: 133,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.image_not_supported, size: 50),
                ),
              const SizedBox(width: 16),
              // Detalles a la derecha de la imagen
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.star, color: Colors.amber),
                        const SizedBox(width: 4),
                        Text('${voteAverage.toStringAsFixed(1)}/10'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Géneros: ',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(genreNames),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          
          // Sinopsis
          const Text(
            'Sinopsis',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              overview,
              style: const TextStyle(fontSize: 16),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Botón para ver reseñas
          Center(
            child: ElevatedButton.icon(
              icon: const Icon(Icons.rate_review),
              label: const Text('Ver Reseñas'),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ReviewsScreen(
                      id: widget.id,
                      isMovie: widget.isMovie,
                      title: title,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
