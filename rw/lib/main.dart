import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:rw/firebase_options.dart';
import 'api_service.dart';
import 'detail_screen.dart'; // Importar la clase DetailScreen correcta

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inicializar Firebase antes de ejecutar la aplicación
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
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
      home: GlobalScaffold(
        onToggleTheme: _toggleTheme,
        child: const MyHomePage(),
      ),
    );
  }
}

class GlobalScaffold extends StatefulWidget {
  final Widget child;
  final VoidCallback onToggleTheme;

  const GlobalScaffold({super.key, required this.child, required this.onToggleTheme});

  @override
  State<GlobalScaffold> createState() => _GlobalScaffoldState();
}

class _GlobalScaffoldState extends State<GlobalScaffold> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final TextEditingController _searchController = TextEditingController();

  void _onSearchSubmitted(String query) {
    if (query.isNotEmpty) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(
              title: const Text('Resultados de Búsqueda'),
            ),
            body: MyHomePage(searchQuery: query),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Row(
          children: [
            TextButton(
              onPressed: () {
                _navigatorKey.currentState?.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (context) => const MyHomePage()),
                  (route) => false,
                );
              },
              child: const Text(
                'Reviews Waves',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const Spacer(),
            SizedBox(
              width: 200,
              child: TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  hintText: 'Buscar...',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(20)),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white24,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16),
                ),
                style: const TextStyle(color: Colors.white),
                onSubmitted: _onSearchSubmitted,
              ),
            ),
            IconButton(
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              onPressed: widget.onToggleTheme,
            ),
          ],
        ),
      ),
      body: Navigator(
        key: _navigatorKey,
        onGenerateRoute: (settings) {
          Widget page = widget.child;
          if (settings.name == '/detail') {
            final args = settings.arguments as Map<String, dynamic>;
            page = DetailScreen(id: args['id'], isMovie: args['isMovie']);
          }
          return MaterialPageRoute(builder: (_) => page);
        },
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String? searchQuery;

  const MyHomePage({super.key, this.searchQuery});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _searchResults;
  late Future<List<dynamic>> _moviesFuture;
  late Future<List<dynamic>> _tvShowsFuture;
  late Future<Map<int, String>> _genresFuture;
  Map<int, String> _genreMap = {}; // Mapa para almacenar géneros

  @override
  void initState() {
    super.initState();
    _genresFuture = _fetchGenres();
    _moviesFuture = _apiService.fetchMovies();
    _tvShowsFuture = _apiService.fetchTVShows();

    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      _searchResults = _apiService.searchMovies(widget.searchQuery!);
    } else {
      _searchResults = _apiService.fetchMovies();
    }
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
    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      return FutureBuilder<List<dynamic>>(
        future: _searchResults,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar los resultados.'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No se encontraron resultados.'));
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final item = snapshot.data![index];
                return ListTile(
                  leading: Image.network(
                    'https://image.tmdb.org/t/p/w185${item['poster_path']}',
                    width: 50,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) =>
                        const Icon(Icons.error),
                  ),
                  title: Text(item['title'] ?? item['name'] ?? 'Sin título'),
                  subtitle: Text(item['overview'] ?? 'Sin descripción.'),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => DetailScreen(
                          id: item['id'],
                          isMovie: true,
                        ),
                      ),
                    );
                  },
                );
              },
            );
          }
        },
      );
    } else {
      return SingleChildScrollView(
        child: Column(
          children: [
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
      );
    }
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
                  color: Theme.of(context).textTheme.titleLarge?.color,
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
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).textTheme.titleMedium?.color,
                        ),
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
    final ScrollController scrollController = ScrollController();

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      height: 280, // Altura fija para las tarjetas
      child: Stack(
        children: [
          ListView.separated(
            controller: scrollController,
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
              scrollController.animateTo(
                scrollController.offset - 300,
                duration: const Duration(milliseconds: 500),
                curve: Curves.ease,
              );
            }),
          ),
          Positioned(
            right: 0,
            top: 100,
            child: _buildNavigationButton(Icons.arrow_forward, () {
              scrollController.animateTo(
                scrollController.offset + 300,
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
