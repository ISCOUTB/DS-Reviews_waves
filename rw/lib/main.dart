import 'package:flutter/material.dart';
import 'api_service.dart';
import 'detail_screen.dart'; // Importar la clase DetailScreen correcta

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  ThemeMode _themeMode = ThemeMode.system;

  void _toggleTheme() {
    setState(() {
      _themeMode = _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFD9C2F2),
        scaffoldBackgroundColor: const Color(0xFFF4F4F7),
        cardColor: Colors.white,
        textTheme: const TextTheme(
          titleMedium: TextStyle(color: Color(0xFF333333)), // Reemplaza bodyText1
          bodyMedium: TextStyle(color: Color(0xFF6D6D6D)), // Reemplaza bodyText2
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF2A2540),
        scaffoldBackgroundColor: const Color(0xFF1C1B29),
        cardColor: const Color(0xFF2F2A48),
        textTheme: const TextTheme(
          titleMedium: TextStyle(color: Color(0xFFF4F4F4)), // Reemplaza bodyText1
          bodyMedium: TextStyle(color: Color(0xFFC1B5E3)), // Reemplaza bodyText2
        ),
      ),
      themeMode: _themeMode, // Cambia automáticamente entre claro y oscuro
      home: MyHomePage(title: 'Flutter Demo Home Page', onToggleTheme: _toggleTheme),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title, required this.onToggleTheme});

  final String title;
  final VoidCallback onToggleTheme;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _moviesFuture;
  late Future<List<dynamic>> _tvShowsFuture;
  late Future<Map<int, String>> _genresFuture;
  Map<int, String> _genreMap = {}; // Mapa para almacenar géneros
  String _searchQuery = ''; // Consulta de búsqueda

  @override
  void initState() {
    super.initState();
    _genresFuture = _fetchGenres();
    _moviesFuture = _apiService.fetchMovies();
    _tvShowsFuture = _apiService.fetchTVShows();
  }

  Future<Map<int, String>> _fetchGenres() async {
    try {
      final movieGenres = await _apiService.fetchMovieGenres();
      final tvGenres = await _apiService.fetchTVGenres();
      _genreMap = {...movieGenres, ...tvGenres}; // Combinar géneros
      return _genreMap;
    } catch (e) {
      print('Error fetching genres: $e');
      return {};
    }
  }

  String _getGenres(List<int> genreIds) {
    if (genreIds.isEmpty) return "Sin categoría";
    return genreIds.map((id) => _genreMap[id] ?? "Desconocido").join(", ");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: TextField(
          decoration: const InputDecoration(
            hintText: 'Buscar películas o series...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: const TextStyle(color: Colors.white),
          onSubmitted: (query) {
            setState(() {
              _searchQuery = query;
              _moviesFuture = _apiService.searchMovies(query);
              _tvShowsFuture = _apiService.searchTVShows(query);
            });
          },
        ),
        actions: [
          IconButton(
            icon: Icon(
              Theme.of(context).brightness == Brightness.dark
                  ? Icons.light_mode
                  : Icons.dark_mode,
            ),
            onPressed: widget.onToggleTheme,
          ),
          FutureBuilder<Map<int, String>>(
            future: _genresFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CircularProgressIndicator();
              } else if (snapshot.hasError) {
                return const Icon(Icons.error);
              } else {
                return PopupMenuButton<int>(
                  icon: const Icon(Icons.filter_list),
                  onSelected: (genreId) {
                    setState(() {
                      _moviesFuture = _apiService.fetchMoviesByGenre(genreId);
                      _tvShowsFuture = _apiService.fetchTVShowsByGenre(genreId);
                    });
                  },
                  itemBuilder: (context) {
                    return snapshot.data!.entries
                        .map((entry) => PopupMenuItem<int>(
                              value: entry.key,
                              child: Text(entry.value),
                            ))
                        .toList();
                  },
                );
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            if (_searchQuery.isNotEmpty)
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Resultados para "$_searchQuery"',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
            const SizedBox(height: 20),
            _buildSectionHeader(context, 'Popular Movies'),
            FutureBuilder<List<dynamic>>(
              future: _moviesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Text('Error loading movies.');
                } else {
                  return _buildCarousel(snapshot.data!, isMovie: true);
                }
              },
            ),
            const SizedBox(height: 20),
            _buildSectionHeader(context, 'Popular TV Shows'),
            FutureBuilder<List<dynamic>>(
              future: _tvShowsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return const Text('Error loading TV shows.');
                } else {
                  return _buildCarousel(snapshot.data!, isMovie: false);
                }
              },
            ),
            const SizedBox(height: 20),
            _buildSectionHeader(context, 'Movies by Genre'),
            _buildGenreCarousels(isMovie: true),
            const SizedBox(height: 20),
            _buildSectionHeader(context, 'TV Shows by Genre'),
            _buildGenreCarousels(isMovie: false),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () {
              // Acción para ver más contenido
            },
          ),
        ],
      ),
    );
  }

  Widget _buildGenreCarousels({required bool isMovie}) {
    return FutureBuilder<Map<int, String>>(
      future: _genresFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return const Text('Error loading genres.');
        } else {
          final genres = snapshot.data!;
          return Column(
            children: genres.entries.map((entry) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.value,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  FutureBuilder<List<dynamic>>(
                    future: isMovie
                        ? _apiService.fetchMoviesByGenre(entry.key)
                        : _apiService.fetchTVShowsByGenre(entry.key),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      } else if (snapshot.hasError) {
                        return const Text('Error loading content.');
                      } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const Text('No content available.');
                      } else {
                        return _buildCarousel(snapshot.data!, isMovie: isMovie);
                      }
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              );
            }).toList(),
          );
        }
      },
    );
  }

  Widget _buildCarousel(List<dynamic> items, {required bool isMovie}) {
    final ScrollController _scrollController = ScrollController();

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      height: 280, // Altura fija para las tarjetas
      child: Stack(
        children: [
          ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final item = items[index];
              final genreTags = _getGenres(List<int>.from(item['genre_ids'] ?? []));
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => DetailScreen(
                        id: item['id'],
                        isMovie: isMovie,
                      ),
                    ),
                  );
                },
                child: Container(
                  width: 180, // Ancho fijo para las tarjetas
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 5,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(10)),
                        child: Image.network(
                          'https://image.tmdb.org/t/p/w185${item['poster_path']}',
                          width: 180,
                          height: 150,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.error, size: 50),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          item['title'] ?? item['name'] ?? 'Unknown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          genreTags,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const Spacer(),
                    ],
                  ),
                ),
              );
            },
          ),
          Positioned(
            left: 0,
            top: 100,
            child: _buildNavigationButton(Icons.arrow_back, () {
              _scrollController.animateTo(
                _scrollController.offset - 300,
                duration: const Duration(milliseconds: 500),
                curve: Curves.ease,
              );
            }),
          ),
          Positioned(
            right: 0,
            top: 100,
            child: _buildNavigationButton(Icons.arrow_forward, () {
              _scrollController.animateTo(
                _scrollController.offset + 300,
                duration: const Duration(milliseconds: 500),
                curve: Curves.ease,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButton(IconData icon, VoidCallback onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}
