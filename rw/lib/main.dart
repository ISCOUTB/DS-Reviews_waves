import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rw/firebase_options.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
// Import para mostrar imágenes en caché
import 'package:cached_network_image/cached_network_image.dart';
// Importaciones que resuelven los errores
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import 'api_service.dart';
import 'detail_screen.dart';
import 'perfil_screen.dart'; // Importando la pantalla de perfil
import 'login_screen.dart'; // Importando la pantalla de inicio de sesión

// Inicializar logger global
final log = Logger('ReviewsWaves');

Future<void> main() async {
  // Configurando el logger
  Logger.root.level = Level.INFO;
  Logger.root.onRecord.listen((record) {
    // ignore: avoid_print
    print('${record.level.name}: ${record.time}: ${record.message}');
  });
  
  WidgetsFlutterBinding.ensureInitialized();
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
      title: 'Reviews Waves',
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFFD9C2F2),
        scaffoldBackgroundColor: const Color(0xFFF4F4F7),
        cardColor: Colors.white,
        textTheme: const TextTheme(
          titleMedium: TextStyle(color: Color(0xFF333333)),
          bodyMedium: TextStyle(color: Color(0xFF6D6D6D)),
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF2A2540),
        scaffoldBackgroundColor: const Color(0xFF1C1B29),
        cardColor: const Color(0xFF2F2A48),
        textTheme: const TextTheme(
          titleMedium: TextStyle(color: Color(0xFFF4F4F4)),
          bodyMedium: TextStyle(color: Color(0xFFC1B5E3)),
        ),
      ),
      themeMode: _themeMode,
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
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();
  final TextEditingController _searchController = TextEditingController();
  User? _currentUser;
  late Stream<User?> _authStateStream;  final ApiService _apiService = ApiService();
  Map<int, String> _genreMap = {};
  bool _loadingGenres = true;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  // Eliminamos la variable _isMobileView ya que no la necesitamos

  // Método para abrir el drawer derecho
  void _openEndDrawer() {
    _scaffoldKey.currentState?.openEndDrawer();
  }
  @override
  void initState() {
    super.initState();
    _currentUser = _auth.currentUser;
    _authStateStream = FirebaseAuth.instance.authStateChanges();
    _authStateStream.listen((User? user) {
      setState(() {
        _currentUser = user;
      });
    });
    _loadGenres();
  }

  Future<void> _loadGenres() async {
    try {
      final movieGenres = await _apiService.fetchMovieGenres();
      final tvGenres = await _apiService.fetchTVGenres();
      if (!mounted) return;
      setState(() {
        _genreMap = {...movieGenres, ...tvGenres};
        _loadingGenres = false;
      });
    } catch (e) {
      log.info('Error loading genres: $e');
      if (!mounted) return;
      setState(() {
        _loadingGenres = false;
      });
    }
  }

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

  void _showGenreFilterDialog() {
    if (_loadingGenres) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cargando géneros...')),
      );
      return;
    }

    if (_genreMap.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudieron cargar los géneros')),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Filtrar por Género'),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: _genreMap.length,
            itemBuilder: (context, index) {
              final entry = _genreMap.entries.elementAt(index);
              return ListTile(
                title: Text(entry.value),
                onTap: () {
                  Navigator.pop(context);
                  _navigateToFilteredResults(entry.key, entry.value);
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  void _navigateToFilteredResults(int genreId, String genreName) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: Text('Películas de $genreName'),
          ),
          body: MyHomePage(filteredGenreId: genreId, isMovie: true),
        ),
      ),
    );
  }

  void _logout() async {
    await _auth.signOut();
    if (!mounted) return;
    setState(() {
      _currentUser = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sesión cerrada exitosamente')),
    );
  }
  @override
  Widget build(BuildContext context) {
    // Ya no necesitamos detectar si estamos en un dispositivo móvil
    
    return Scaffold(
      key: _scaffoldKey,      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: TextButton(
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
        actions: [
          // Solo mantenemos la barra de búsqueda
          SizedBox(
            width: 200,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
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
          ),
          // Solo mostramos el botón del menú lateral
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: _openEndDrawer,
            color: Colors.white,
          ),
        ],
      ),
      endDrawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: Text(
                'Menú',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                ),
              ),
            ),
            // Opción para cambiar entre modo oscuro y claro
            ListTile(
              leading: Icon(
                Theme.of(context).brightness == Brightness.light
                  ? Icons.dark_mode
                  : Icons.light_mode
              ),
              title: Text(
                Theme.of(context).brightness == Brightness.light
                  ? 'Modo Oscuro'
                  : 'Modo Claro'
              ),
              onTap: () {
                Navigator.pop(context);
                widget.onToggleTheme();
              },
            ),
            // Opción para filtrar películas
            ListTile(
              leading: const Icon(Icons.filter_list),
              title: const Text('Filtrar por género'),
              onTap: () {
                Navigator.pop(context);
                _showGenreFilterDialog();
              },
            ),
            // Opción para iniciar sesión (solo cuando no hay usuario autenticado)
            if (_currentUser == null)
              ListTile(
                leading: const Icon(Icons.login),
                title: const Text('Iniciar Sesión'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
              ),
            // Opciones que solo se muestran cuando el usuario está autenticado
            if (_currentUser != null) ...[
              ListTile(
                leading: const Icon(Icons.person),
                title: const Text('Perfil'),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const PerfilScreen()),
                  );
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Cerrar Sesión'),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
            ],
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
        },      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final String? searchQuery;
  final int? filteredGenreId;
  final bool? isMovie;

  const MyHomePage({super.key, this.searchQuery, this.filteredGenreId, this.isMovie});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ApiService _apiService = ApiService();
  Future<List<dynamic>>? _contentFuture;  // Cambiado a nullable para evitar LateInitializationError
  Future<List<dynamic>>? _moviesFuture;
  Future<List<dynamic>>? _tvShowsFuture;
  Future<Map<int, String>>? _genresFuture;
  Map<int, String> _genreMap = {};
  bool _genresLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAllData();
  }
  Future<void> _loadAllData() async {
    _genresFuture = _fetchGenres();
    _moviesFuture = _apiService.fetchMovies();
    _tvShowsFuture = _apiService.fetchTVShows();

    // Precargar los géneros antes de mostrar cualquier contenido
    try {
      final genreResult = await _genresFuture;
      if (genreResult != null) {
        _genreMap = genreResult;
        _genresLoaded = true;
        if (mounted) {
          setState(() {});
        }
      }
    } catch (e) {
      log.info('Error precargando géneros: $e');
    }

    if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
      _contentFuture = _apiService.searchMovies(widget.searchQuery!);
    } else if (widget.filteredGenreId != null) {
      if (widget.isMovie == true) {
        _contentFuture = _apiService.fetchMoviesByGenre(widget.filteredGenreId!);
      } else {
        _contentFuture = _apiService.fetchTVShowsByGenre(widget.filteredGenreId!);
      }
    } else {
      _contentFuture = _apiService.fetchMovies();
    }

    // Asegurarse de inicializar _contentFuture dentro de un setState para reflejar cambios en la UI
    if (mounted) {
      setState(() {
        if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
          _contentFuture = _apiService.searchMovies(widget.searchQuery!);
        } else if (widget.filteredGenreId != null) {
          if (widget.isMovie == true) {
            _contentFuture = _apiService.fetchMoviesByGenre(widget.filteredGenreId!);
          } else {
            _contentFuture = _apiService.fetchTVShowsByGenre(widget.filteredGenreId!);
          }
        } else {
          _contentFuture = _apiService.fetchMovies();
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant MyHomePage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != oldWidget.searchQuery ||
        widget.filteredGenreId != oldWidget.filteredGenreId) {
      setState(() {
        if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
          _contentFuture = _apiService.searchMovies(widget.searchQuery!);
        } else if (widget.filteredGenreId != null) {
          if (widget.isMovie == true) {
            _contentFuture = _apiService.fetchMoviesByGenre(widget.filteredGenreId!);
          } else {
            _contentFuture = _apiService.fetchTVShowsByGenre(widget.filteredGenreId!);
          }
        } else {
          _contentFuture = _apiService.fetchMovies();
        }
      });
    }
  }

  Future<Map<int, String>> _fetchGenres() async {
    try {
      final movieGenres = await _apiService.fetchMovieGenres();
      final tvGenres = await _apiService.fetchTVGenres();
      
      if (mounted) {
        setState(() {
          _genreMap = {...movieGenres, ...tvGenres};
          _genresLoaded = true;
        });
      }
      return {...movieGenres, ...tvGenres};
    } catch (e) {
      log.info('Error fetching genres: $e');
      return {};
    }
  }

  String _getGenres(List<int> genreIds) {
    if (genreIds.isEmpty) return "Sin categoría";
    if (!_genresLoaded || _genreMap.isEmpty) return "Cargando...";
    return genreIds.map((id) => _genreMap[id] ?? "Sin categoría").join(", ");
  }

  @override
  Widget build(BuildContext context) {    if ((widget.searchQuery != null && widget.searchQuery!.isNotEmpty) || 
        widget.filteredGenreId != null) {
      // Si _contentFuture es null (no inicializado), mostramos un indicador de carga
      if (_contentFuture == null) {
        return const Center(child: CircularProgressIndicator());
      }
      return FutureBuilder<List<dynamic>>(
        future: _contentFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Theme.of(context).primaryColor,
                      ),
                      strokeWidth: 3,
                    ),
                  ).animate().scale(
                    duration: 800.ms,
                    curve: Curves.elasticOut,
                    delay: 200.ms,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Buscando contenido...',
                    style: TextStyle(
                      color: Theme.of(context).textTheme.titleMedium?.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ).animate().fadeIn(duration: 400.ms),
                ],
              ),
            );
          } else if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 60,
                    color: Colors.red.shade400,
                  ).animate().shake(duration: 400.ms),
                  const SizedBox(height: 16),
                  Text(
                    'Error al cargar los resultados',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton.icon(
                    onPressed: () {                      setState(() {
                        if (widget.searchQuery != null && widget.searchQuery!.isNotEmpty) {
                          _contentFuture = _apiService.searchMovies(widget.searchQuery!);
                        } else if (widget.filteredGenreId != null) {
                          if (widget.isMovie == true) {
                            _contentFuture = _apiService.fetchMoviesByGenre(widget.filteredGenreId!);
                          } else {
                            _contentFuture = _apiService.fetchTVShowsByGenre(widget.filteredGenreId!);
                          }
                        } else {
                          // Valor por defecto si no hay búsqueda o filtro
                          _contentFuture = _apiService.fetchMovies();
                        }
                      });
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Intentar de nuevo'),
                  ),
                ],
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.search_off,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No se encontraron resultados',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Intenta con otra búsqueda o filtro',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ).animate().fadeIn(duration: 400.ms),
            );
          } else {
            return ListView.builder(
              padding: const EdgeInsets.all(16.0),
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final item = snapshot.data![index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: 2,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DetailScreen(
                            id: item['id'],
                            isMovie: widget.filteredGenreId != null
                                ? widget.isMovie ?? true
                                : true,
                          ),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Imagen con esquinas redondeadas y efecto de sombra
                          Container(
                            width: 80,
                            height: 120,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withAlpha(_opacityToAlpha(0.2)),
                                  blurRadius: 5,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: CachedNetworkImage(
                                imageUrl: 'https://image.tmdb.org/t/p/w185${item['poster_path']}',
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Shimmer.fromColors(
                                  baseColor: Colors.grey[300]!,
                                  highlightColor: Colors.grey[100]!,
                                  child: Container(color: Colors.grey[300]),
                                ),
                                errorWidget: (context, url, error) => const Icon(Icons.person, color: Colors.white),
                                width: 30,
                                height: 30,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Información del contenido
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Título con calificación
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item['title'] ?? item['name'] ?? 'Sin título',
                                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                    if (item['vote_average'] != null)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getRatingColor(item['vote_average'].toDouble()).withAlpha(_opacityToAlpha(0.2)),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: _getRatingColor(item['vote_average'].toDouble()),
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.star,
                                              size: 14,
                                              color: _getRatingColor(item['vote_average'].toDouble()),
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              item['vote_average'].toStringAsFixed(1),
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                                color: _getRatingColor(item['vote_average'].toDouble()),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                // Fecha de lanzamiento
                                Text(
                                  _formatDate(item['release_date'] ?? item['first_air_date']),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                                const SizedBox(height: 8),
                                // Géneros
                                Text(
                                  _getGenres(List<int>.from(item['genre_ids'] ?? [])),
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontStyle: FontStyle.italic,
                                    fontSize: 13,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                // Descripción
                                Text(
                                  item['overview'] ?? 'Sin descripción disponible.',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate()
                 .fadeIn(duration: 350.ms, delay: (50 * index).ms)
                 .slideX(begin: 0.2, end: 0, duration: 350.ms, delay: 50.ms);
              },
            );
          }
        },
      );
    } else {
      return SingleChildScrollView(
        child: Column(
          children: [
            // Banner destacado con animación
            _buildFeaturedBanner(),
            
            const SizedBox(height: 20),
            _buildSectionHeader(context, 'Popular Movies'),
            _moviesFuture == null 
            ? _buildLoadingCarousel()
            : FutureBuilder<List<dynamic>>(
              future: _moviesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingCarousel();
                } else if (snapshot.hasError) {
                  return _buildErrorWidget('Error cargando películas');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildErrorWidget('No hay películas disponibles');
                } else {
                  return _buildCarousel(snapshot.data!, isMovie: true);
                }
              },
            ),
            const SizedBox(height: 20),            _buildSectionHeader(context, 'Popular TV Shows'),
            _tvShowsFuture == null 
            ? _buildLoadingCarousel()
            : FutureBuilder<List<dynamic>>(
              future: _tvShowsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingCarousel();
                } else if (snapshot.hasError) {
                  return _buildErrorWidget('Error cargando series');
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildErrorWidget('No hay series disponibles');
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
            // Footer con información de la app
            _buildFooter(),
          ],
        ),
      );
    }
  }
  
  // Widget para el banner destacado de contenido
  Widget _buildFeaturedBanner() {
    if (_moviesFuture == null) {
      return const SizedBox(height: 200);
    }
    return FutureBuilder<List<dynamic>>(
      future: _moviesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 200);
        } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox(height: 0);
        } else {
          // Elegir un contenido destacado (el primero de la lista)
          final featured = snapshot.data![0];
          
          return Container(
            height: 220,
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
            child: Stack(
              children: [
                // Imagen de fondo
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: 'https://image.tmdb.org/t/p/w500${featured['backdrop_path'] ?? featured['poster_path']}',
                    width: double.infinity,
                    height: 220,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => Container(
                      color: Theme.of(context).primaryColor.withAlpha(_opacityToAlpha(0.2)),
                    ),
                    errorWidget: (context, url, error) => Container(
                      color: Theme.of(context).primaryColor.withAlpha(_opacityToAlpha(0.2)),
                      child: const Icon(Icons.error),
                    ),
                  ),
                ),
                
                // Gradiente para mejorar legibilidad del texto
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withAlpha(_opacityToAlpha(0.7)),
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Información del contenido destacado
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Destacado',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            letterSpacing: 1.2,
                          ),
                        ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.5, end: 0, duration: 500.ms),
                        const SizedBox(height: 8),
                        Text(
                          featured['title'] ?? featured['name'] ?? 'Sin título',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                            shadows: [
                              Shadow(
                                color: Colors.black54,
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ).animate().fadeIn(duration: 500.ms, delay: 200.ms)
                          .slideY(begin: 0.3, end: 0, duration: 500.ms, delay: 200.ms),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => DetailScreen(
                                      id: featured['id'],
                                      isMovie: true,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Ver detalles'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).primaryColor,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                            ).animate().fadeIn(duration: 500.ms, delay: 400.ms)
                              .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 400.ms),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.bookmark_outline),
                              style: IconButton.styleFrom(
                                backgroundColor: Colors.black.withAlpha(_opacityToAlpha(0.6)),
                                foregroundColor: Colors.white,
                              ),
                            ).animate().fadeIn(duration: 500.ms, delay: 600.ms)
                              .slideY(begin: 0.2, end: 0, duration: 500.ms, delay: 600.ms),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                // Indicador de calificación
                Positioned(
                  top: 16,
                  right: 16,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withAlpha(_opacityToAlpha(0.7)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _getRatingColor(featured['vote_average'].toDouble()),
                        width: 2,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.star,
                          size: 16,
                          color: _getRatingColor(featured['vote_average'].toDouble()),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          featured['vote_average'].toStringAsFixed(1),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
              ],
            ),
          ).animate()
           .fadeIn(duration: 800.ms)
           .scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1), duration: 800.ms);
        }
      },
    );
  }

  // Widget para mostrar estado de carga de los carruseles
  Widget _buildLoadingCarousel() {
    return SizedBox(
      height: 280,
      child: Shimmer.fromColors(
        baseColor: Colors.grey[300]!,
        highlightColor: Colors.grey[100]!,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: 5,
          itemBuilder: (context, index) {
            return Container(
              width: 180,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
            );
          },
        ),
      ),
    );
  }
  
  // Widget para mostrar errores
  Widget _buildErrorWidget(String message) {
    return SizedBox(
      height: 220,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 40,
              color: Colors.red[400],
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: TextStyle(
                color: Theme.of(context).textTheme.bodyMedium?.color,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  // Widget para el pie de página
  Widget _buildFooter() {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Theme.of(context).brightness == Brightness.light 
          ? Colors.grey[100] 
          : Colors.grey[900],
      child: Column(
        children: [
          Text(
            'Reviews Waves',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).textTheme.titleMedium?.color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'La mejor app para descubrir películas y series',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
            ),
          ),
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 16),
          Text(
            '© ${DateTime.now().year} Reviews Waves. Todos los derechos reservados.',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).textTheme.bodyMedium?.color?.withAlpha(_opacityToAlpha(0.6)),
            ),
          ),
        ],
      ),
    );
  }

  // Widget para mostrar contenido filtrado por género
  Widget _buildGenreCarousels({required bool isMovie}) {
    if (!_genresLoaded || _genreMap.isEmpty) {
      return _buildLoadingCarousel();
    }
    
    // Seleccionar solo algunos géneros populares para mostrar (para no sobrecargar la UI)
    List<MapEntry<int, String>> genresToShow;
    if (isMovie) {
      genresToShow = _genreMap.entries.where((entry) => 
        [28, 12, 35, 18, 14, 27].contains(entry.key)).toList();
    } else {
      genresToShow = _genreMap.entries.where((entry) => 
        [10759, 18, 35, 10765, 10768, 9648].contains(entry.key)).toList();
    }
    
    if (genresToShow.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: genresToShow.map((genre) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                genre.value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).textTheme.titleMedium?.color,
                ),
              ).animate()
                .fadeIn(duration: 350.ms)
                .slideX(begin: -0.1, end: 0, duration: 350.ms, curve: Curves.easeOutQuad),
            ),
            FutureBuilder<List<dynamic>>(
              future: isMovie 
                ? _apiService.fetchMoviesByGenre(genre.key)
                : _apiService.fetchTVShowsByGenre(genre.key),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return _buildLoadingCarousel();
                } else if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return _buildErrorWidget('No se pudieron cargar ${isMovie ? 'películas' : 'series'} de este género');
                } else {
                  return _buildMiniCarousel(snapshot.data!, isMovie: isMovie, genreName: genre.value);
                }
              },
            ),
          ],
        );
      }).toList(),
    );
  }

  // Carrusel pequeño para los géneros
  Widget _buildMiniCarousel(List<dynamic> items, {required bool isMovie, required String genreName}) {
    final ScrollController scrollController = ScrollController();

    return SizedBox(
      height: 200, // Altura más compacta para el mini-carrusel
      child: Stack(
        children: [
          ListView.separated(
            controller: scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: items.length,
            separatorBuilder: (context, index) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final item = items[index];
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
                  width: 130, // Ancho menor para el mini-carrusel
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(_opacityToAlpha(0.08)),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
                        child: Stack(
                          children: [
                            // Imagen del póster
                            CachedNetworkImage(
                              imageUrl: 'https://image.tmdb.org/t/p/w185${item['poster_path']}',
                              width: 130,
                              height: 130,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(color: Colors.grey[300], height: 130),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[800],
                                height: 130,
                                child: const Icon(Icons.error, color: Colors.white),
                              ),
                            ),

                            // Puntuación
                            if (item['vote_average'] != null)
                              Positioned(
                                top: 5,
                                right: 5,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withAlpha(_opacityToAlpha(0.7)),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.star,
                                        size: 10,
                                        color: _getRatingColor(item['vote_average'].toDouble()),
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        item['vote_average'].toStringAsFixed(1),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(6.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item['title'] ?? item['name'] ?? 'Unknown',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatDate(item['release_date'] ?? item['first_air_date']),
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 10,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate()
                .fadeIn(duration: 300.ms, delay: (50 * index).ms)
                .slideY(begin: 0.1, end: 0, duration: 300.ms, delay: (50 * index).ms);
            },
          ),

          // Botones de navegación mejorados para mini-carruseles
          if (items.length > 4)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildNavigationButton(
                  Icons.chevron_left,
                  () {
                    scrollController.animateTo(
                      scrollController.offset - 250,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  isLeft: true,
                  isCompact: true,
                ),
              ),
            ),

          if (items.length > 4)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: Center(
                child: _buildNavigationButton(
                  Icons.chevron_right,
                  () {
                    scrollController.animateTo(
                      scrollController.offset + 250,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.easeOutCubic,
                    );
                  },
                  isLeft: false,
                  isCompact: true,
                ),
              ),
            ),

          // Botón para ver todos los resultados del género
          Positioned(
            bottom: 8,
            right: 16,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(
                        title: Text('${isMovie ? 'Películas' : 'Series'} de $genreName'),
                      ),
                      body: MyHomePage(
                        filteredGenreId: _genreMap.entries
                            .firstWhere((entry) => entry.value == genreName)
                            .key,
                        isMovie: isMovie,
                      ),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.arrow_forward, size: 14),
              label: const Text('Ver más', style: TextStyle(fontSize: 12)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor.withAlpha(_opacityToAlpha(0.8)),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                minimumSize: const Size(0, 28),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ).animate().fadeIn(duration: 500.ms, delay: 300.ms),
          ),
        ],
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
                  color: Theme.of(context).textTheme.titleLarge?.color,
                ),
          ).animate()
            .fadeIn(duration: 400.ms)
            .slideX(begin: -0.2, end: 0, duration: 400.ms, curve: Curves.easeOutQuad),
          IconButton(
            icon: const Icon(Icons.arrow_forward),
            onPressed: () {
              // Acción para ver más contenido
            },
          ).animate()
            .fadeIn(duration: 400.ms, delay: 100.ms)
            .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 400.ms),
        ],
      ),
    );
  }

  Widget _buildCarousel(List<dynamic> items, {required bool isMovie}) {
    final ScrollController scrollController = ScrollController();

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      height: 280,
      child: Stack(
        children: [
          // Efecto de fondo sutil
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Theme.of(context).primaryColor.withAlpha(_opacityToAlpha(0.05)),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                ),
              ),
            ).animate().fadeIn(duration: 600.ms),
          ),

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
                  width: 180,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(_opacityToAlpha(0.1)),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          // Imagen principal
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(12)),
                            child: CachedNetworkImage(
                              imageUrl: 'https://image.tmdb.org/t/p/w185${item['poster_path']}',
                              width: 180,
                              height: 150,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.grey[100]!,
                                child: Container(color: Colors.grey[300]),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[800],
                                height: 150,
                                width: 180,
                                child: const Icon(Icons.error, size: 40, color: Colors.white54),
                              ),
                            ),
                          ),

                          // Gradiente superior para mejorar contraste
                          Positioned(
                            top: 0,
                            left: 0,
                            right: 0,
                            height: 50,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withAlpha(_opacityToAlpha(0.5)),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),

                          // Indicador de tipo (película/serie)
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: isMovie ? Colors.redAccent : Colors.blueAccent,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black26,
                                    blurRadius: 3,
                                    offset: const Offset(0, 1),
                                  ),
                                ],
                              ),
                              child: Text(
                                isMovie ? 'Película' : 'Serie',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          // Puntuación
                          if (item['vote_average'] != null)
                            Positioned(
                              top: 8,
                              right: 8,
                              child: Container(
                                height: 36,
                                width: 36,
                                decoration: BoxDecoration(
                                  color: Colors.black.withAlpha(_opacityToAlpha(0.7)),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: _getRatingColor(item['vote_average'].toDouble()),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black26,
                                      blurRadius: 3,
                                      offset: const Offset(0, 1),
                                    ),
                                  ],
                                ),
                                child: Center(
                                  child: Text(
                                    (item['vote_average'] ?? 0).toStringAsFixed(1),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          item['title'] ?? item['name'] ?? 'Unknown',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          genreTags,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 11,
                          ),
                        ),
                      ),
                      const Spacer(),
                      // Fecha de lanzamiento
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 12,
                              color: Theme.of(context).textTheme.bodyMedium?.color,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              _formatDate(item['release_date'] ?? item['first_air_date']),
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ).animate()
                .fadeIn(duration: 350.ms, delay: (70 * index).ms)
                .slideY(begin: 0.2, end: 0, duration: 350.ms, delay: (70 * index).ms)
                .scale(
                  begin: const Offset(0.9, 0.9),
                  end: const Offset(1, 1),
                  duration: 350.ms,
                  delay: (70 * index).ms,
                  curve: Curves.easeOutQuad,
                );
            },
          ),

          // Botones de navegación mejorados
          if (items.length > 3)
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: _buildNavigationButton(
                Icons.chevron_left,
                () {
                  scrollController.animateTo(
                    scrollController.offset - 300,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                  );
                },
                isLeft: true,
              ),
            ),

          if (items.length > 3)
            Positioned(
              right: 0,
              top: 0,
              bottom: 0,
              child: _buildNavigationButton(
                Icons.chevron_right,
                () {
                  scrollController.animateTo(
                    scrollController.offset + 300,
                    duration: const Duration(milliseconds: 500),
                    curve: Curves.easeOutCubic,
                  );
                },
                isLeft: false,
              ),
            ),
        ],
      ),
    );
  }

  // Método para formatear fechas
  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) {
      return 'N/A';
    }
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('yyyy').format(date);
    } catch (e) {
      return 'N/A';
    }
  }

  // Método para determinar el color según la puntuación
  Color _getRatingColor(double rating) {
    if (rating >= 7.5) {
      return Colors.green.shade400;
    } else if (rating >= 6) {
      return Colors.amber.shade400;
    } else {
      return Colors.redAccent;
    }
  }

  // Botones de navegación mejorados
  Widget _buildNavigationButton(IconData icon, VoidCallback onPressed, {bool isLeft = true, bool isCompact = false}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        width: isCompact ? 30 : 40,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: isLeft ? Alignment.centerRight : Alignment.centerLeft,
            end: isLeft ? Alignment.centerLeft : Alignment.centerRight,
            colors: [
              Colors.transparent,
              Colors.black.withAlpha(_opacityToAlpha(0.5)),
            ],
          ),
        ),
        child: Center(
          child: Container(
            width: isCompact ? 28 : 36,
            height: isCompact ? 28 : 36,
            decoration: BoxDecoration(
              color: Colors.black38,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(_opacityToAlpha(0.2)),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              icon,
              color: Colors.white,
              size: isCompact ? 18 : 24,
            ),
          ).animate(onPlay: (controller) => controller.repeat(reverse: true))
           .shimmer(duration: 2000.ms),
        ),
      ).animate()
        .fadeIn(duration: 500.ms)
        .slideX(begin: isLeft ? -1 : 1, end: 0, duration: 500.ms),
    );
  }

  // Función auxiliar para convertir opacity (0.0-1.0) a alpha (0-255)
  int _opacityToAlpha(double opacity) {
    return (opacity * 255).round();
  }
}

