import 'package:flutter/material.dart';
import 'api_service.dart';
import 'detail_screen.dart'; // Importar la clase DetailScreen correcta

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

  @override
  void initState() {
    super.initState();
    _fetchMoviesAndTVShows();
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
                    subtitle: Text(
                      movie['overview'] ?? 'No overview available',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
                    subtitle: Text(
                      tvShow['overview'] ?? 'No overview available',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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
