import 'package:flutter/material.dart';
import 'api_service.dart';
import 'detail_screen.dart'; // Importar la clase DetailScreen correcta
import 'genre_screen.dart'; // Importar la pantalla para mostrar contenido por género

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _movies = [];
  List<dynamic> _tvShows = [];
  Map<int, String> _genreMap = {}; // Mapa para almacenar géneros

  @override
  void initState() {
    super.initState();
    _fetchGenres(); // Obtener géneros al iniciar
    _fetchMoviesAndTVShows();
  }

  Future<void> _fetchGenres() async {
    try {
      final movieGenres = await _apiService.fetchMovieGenres();
      final tvGenres = await _apiService.fetchTVGenres();
      setState(() {
        _genreMap = {...movieGenres, ...tvGenres}; // Combinar géneros de películas y series
      });
    } catch (e) {
      print('Error fetching genres: $e');
    }
  }

  Future<void> _fetchMoviesAndTVShows() async {
    try {
      final movies = await _apiService.fetchMovies();
      final tvShows = await _apiService.fetchTVShows();
      setState(() {
        _movies = movies;
        _tvShows = tvShows;
      });
    } catch (e) {
      print('Error fetching movies or TV shows: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const Text(
              'Popular Movies',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _movies.length,
              itemBuilder: (context, index) {
                final movie = _movies[index];
                final genreTags = (movie['genre_ids'] as List<dynamic>)
                    .map((id) => _genreMap[id] ?? 'Unknown')
                    .toList();
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    leading: movie['poster_path'] != null
                        ? Image.network(
                            'https://image.tmdb.org/t/p/w92${movie['poster_path']}',
                            width: 50,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.error),
                          )
                        : const Icon(Icons.movie),
                    title: Text(movie['title'] ?? 'Unknown'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          children: genreTags
                              .map((genre) => ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => GenreScreen(
                                            genre: genre,
                                            isMovie: true,
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple[100],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Text(
                                      genre,
                                      style: const TextStyle(color: Colors.black),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          movie['overview'] ?? 'No overview available',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailScreen(
                            id: movie['id'],
                            isMovie: true,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Popular TV Shows',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _tvShows.length,
              itemBuilder: (context, index) {
                final tvShow = _tvShows[index];
                final genreTags = (tvShow['genre_ids'] as List<dynamic>)
                    .map((id) => _genreMap[id] ?? 'Unknown')
                    .toList();
                return Card(
                  elevation: 4,
                  margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                  child: ListTile(
                    leading: tvShow['poster_path'] != null
                        ? Image.network(
                            'https://image.tmdb.org/t/p/w92${tvShow['poster_path']}',
                            width: 50,
                            errorBuilder: (context, error, stackTrace) =>
                                const Icon(Icons.error),
                          )
                        : const Icon(Icons.tv),
                    title: Text(tvShow['name'] ?? 'Unknown'),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 6,
                          children: genreTags
                              .map((genre) => ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => GenreScreen(
                                            genre: genre,
                                            isMovie: false,
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.purple[100],
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                    ),
                                    child: Text(
                                      genre,
                                      style: const TextStyle(color: Colors.black),
                                    ),
                                  ))
                              .toList(),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tvShow['overview'] ?? 'No overview available',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailScreen(
                            id: tvShow['id'],
                            isMovie: false,
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
