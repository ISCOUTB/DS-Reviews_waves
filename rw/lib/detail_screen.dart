import 'package:flutter/material.dart';
import 'api_service.dart';

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
    final String overview = _details!['overview'] ?? 'No hay sinopsis disponible';
    final String? posterPath = _details!['poster_path'];
    final String posterUrl = posterPath != null ? 'https://image.tmdb.org/t/p/w185$posterPath' : '';
    final String? backdropPath = _details!['backdrop_path'];
    final String backdropUrl = _apiService.getBackdropUrl(backdropPath);
    final String genreNames = _details!['genres']?.map((g) => g['name']).join(', ') ?? 'Sin géneros';
    final double voteAverage = (_details!['vote_average'] ?? 0.0).toDouble();

    return Stack(
      children: [
        // Imagen de fondo
        Positioned.fill(
          child: Image.network(
            backdropUrl,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) =>
                const Center(child: Text('No image available')),
          ),
        ),
        // Efecto de difuminado
        Positioned.fill(
          child: Container(
            color: Color.fromRGBO(0, 0, 0, 0.6), // Más transparencia
          ),
        ),
        // Contenido principal
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Póster de la película o serie
                if (posterUrl.isNotEmpty)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      posterUrl,
                      width: 150,
                      height: 225,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.error, size: 50),
                    ),
                  ),
                const SizedBox(width: 16),
                // Información de la película o serie
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Géneros: $genreNames',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white,
                            ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.star, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            '${voteAverage.toStringAsFixed(1)}/10',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white,
                                ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Text(
                        overview,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                      ),
                      const SizedBox(height: 20),
                      // Botón destacado
                      ElevatedButton.icon(
                        icon: const Icon(Icons.rate_review),
                        label: const Text('Ver Reseñas'),
                        onPressed: () {
                          // Acción para ver reseñas
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
