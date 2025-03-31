import 'package:flutter/material.dart';
import 'api_service.dart';

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
                return ListTile(
                  title: Text(movie['title'] ?? 'Unknown'),
                  subtitle: Text('Rating: ${movie['vote_average'] ?? 'N/A'}'),
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
                return ListTile(
                  title: Text(tvShow['name'] ?? 'Unknown'),
                  subtitle: Text('Rating: ${tvShow['vote_average'] ?? 'N/A'}'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
