import 'package:flutter/material.dart';
import 'api_service.dart';

class GenreScreen extends StatefulWidget {
  final String genre;
  final bool isMovie;

  const GenreScreen({super.key, required this.genre, required this.isMovie}); // Usar super.key

  @override
  State<GenreScreen> createState() => _GenreScreenState();
}

class _GenreScreenState extends State<GenreScreen> {
  final ApiService _apiService = ApiService();
  List<dynamic> _items = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchItemsByGenre();
  }

  Future<void> _fetchItemsByGenre() async {
    try {
      final items = widget.isMovie
          ? await _apiService.fetchMoviesWithGenres()
          : await _apiService.fetchTVShowsWithGenres();

      setState(() {
        _items = items.where((item) => item['genre_names'].contains(widget.genre)).toList();
        _isLoading = false;
      });
    } catch (e) {
      print('Error fetching items by genre: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Genre: ${widget.genre}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _items.isEmpty
              ? const Center(child: Text('No items found for this genre.'))
              : ListView.builder(
                  itemCount: _items.length,
                  itemBuilder: (context, index) {
                    final item = _items[index];
                    return Card(
                      elevation: 4,
                      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                      child: ListTile(
                        leading: item['poster_path'] != null
                            ? Image.network(
                                'https://image.tmdb.org/t/p/w92${item['poster_path']}',
                                width: 50,
                                errorBuilder: (context, error, stackTrace) =>
                                    const Icon(Icons.error),
                              )
                            : Icon(widget.isMovie ? Icons.movie : Icons.tv),
                        title: Text(item['title'] ?? item['name'] ?? 'Unknown'),
                        subtitle: Text(
                          item['overview'] ?? 'No overview available',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        onTap: () {
                          // Navegar a la pantalla de detalles
                        },
                      ),
                    );
                  },
                ),
    );
  }
}
