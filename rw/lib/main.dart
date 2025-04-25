import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:rw/firebase_options.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import 'package:logging/logging.dart';
import 'api_service.dart';
import 'detail_screen.dart';
import 'perfil_screen.dart'; // Importando la pantalla de perfil

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
      title: 'Flutter Demo',
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
  late Stream<User?> _authStateStream;
  final ApiService _apiService = ApiService();
  Map<int, String> _genreMap = {};
  bool _loadingGenres = true;

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

  void _showUserInfo() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Información de Usuario'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Email: ${_currentUser?.email ?? "No disponible"}'),
            Text('UID: ${_currentUser?.uid ?? "No disponible"}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
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
              icon: const Icon(Icons.filter_list),
              tooltip: 'Filtrar por género',
              onPressed: _showGenreFilterDialog,
              color: Colors.white,
            ),
            IconButton(
              icon: Icon(
                Theme.of(context).brightness == Brightness.dark
                    ? Icons.light_mode
                    : Icons.dark_mode,
              ),
              onPressed: widget.onToggleTheme,
            ),
            if (_currentUser == null)
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const LoginScreen()),
                  );
                },
                child: const Text(
                  'Iniciar Sesión',
                  style: TextStyle(color: Colors.white),
                ),
              )
            else
              PopupMenuButton<String>(
                icon: const CircleAvatar(
                  backgroundColor: Colors.white24,
                  child: Icon(Icons.person, color: Colors.white),
                ),
                onSelected: (value) {
                  if (value == 'Cerrar Sesión') {
                    _logout();
                  } else if (value == 'Ver Información') {
                    _showUserInfo();
                  } else if (value == 'Perfil') {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const PerfilScreen()),
                    );
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'Ver Información',
                    child: Text('Ver Información'),
                  ),
                  const PopupMenuItem(
                    value: 'Perfil',
                    child: Text('Perfil'),
                  ),
                  const PopupMenuItem(
                    value: 'Cerrar Sesión',
                    child: Text('Cerrar Sesión'),
                  ),
                ],
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
  final int? filteredGenreId;
  final bool? isMovie;

  const MyHomePage({super.key, this.searchQuery, this.filteredGenreId, this.isMovie});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _contentFuture;
  late Future<List<dynamic>> _moviesFuture;
  late Future<List<dynamic>> _tvShowsFuture;
  late Future<Map<int, String>> _genresFuture;
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
      _genreMap = await _genresFuture;
      _genresLoaded = true;
      if (mounted) {
        setState(() {});
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
  Widget build(BuildContext context) {
    if ((widget.searchQuery != null && widget.searchQuery!.isNotEmpty) || 
        widget.filteredGenreId != null) {
      return FutureBuilder<List<dynamic>>(
        future: _contentFuture,
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
                          isMovie: widget.filteredGenreId != null
                              ? widget.isMovie ?? true
                              : true,
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
      height: 280,
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
                  width: 180,
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
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
          color: Color.fromRGBO(0, 0, 0, 0.5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white),
      ),
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isPasswordVisible = false;
  bool _isLoading = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await _auth.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicio de sesión exitoso')),
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1B29),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 350,
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text(
                      'Iniciar Sesión',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF333333),
                      ),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.email),
                        hintText: 'Correo electrónico',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible ? Icons.visibility : Icons.visibility_off,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        hintText: 'Contraseña',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4A90E2),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'Iniciar Sesión',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (context) => const RegisterScreen()),
                        );
                      },
                      child: const Text('¿No tienes cuenta? Regístrate'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nombreCompletoController = TextEditingController();
  final TextEditingController _usuarioController = TextEditingController();
  final TextEditingController _descripcionController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final _database = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL: 'https://reviews-waves-86c01-default-rtdb.firebaseio.com',
  ).ref();
  
  DateTime? _fechaNacimiento;
  String? _generoSeleccionado;
  bool _isLoading = false;
  
  // Variable para almacenar el email temporal y el usuario no confirmado
  String? _unverifiedEmail;
  UserCredential? _unverifiedUser;
  bool _showVerificationCodeScreen = false;

  // Lista de géneros disponibles
  final List<String> _opcionesGenero = [
    'Masculino',
    'Femenino',
    'Otro'
  ];

  Future<void> _requestVerificationCode() async {
    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Las contraseñas no coinciden')),
      );
      return;
    }
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Almacenar el email para usarlo en la verificación
      _unverifiedEmail = _emailController.text.trim();
      
      // Iniciar el proceso de registro pero sin completarlo
      _unverifiedUser = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      
      // Enviar email de verificación
      await _unverifiedUser!.user!.sendEmailVerification();
      
      // Si tenemos datos de perfil, los guardamos en la base de datos
      if (_unverifiedUser != null && _unverifiedUser!.user != null) {
        _guardarPerfilUsuario(_unverifiedUser!.user!.uid);
      }
      
      if (!mounted) return;
      
      setState(() {
        _showVerificationCodeScreen = true;
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Se ha enviado un código de verificación a tu correo electrónico'),
        ),
      );
      
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
  
  // Guardar los datos de perfil en Firebase Realtime Database
  Future<void> _guardarPerfilUsuario(String uid) async {
    try {
      // Solo guardar los campos que tengan valor
      final Map<String, dynamic> perfilData = {};
      
      if (_nombreCompletoController.text.isNotEmpty) {
        perfilData['nombreCompleto'] = _nombreCompletoController.text.trim();
      }
      
      if (_usuarioController.text.isNotEmpty) {
        perfilData['usuario'] = _usuarioController.text.trim();
      }
      
      if (_descripcionController.text.isNotEmpty) {
        perfilData['descripcion'] = _descripcionController.text.trim();
      }
      
      if (_fechaNacimiento != null) {
        perfilData['fechaNacimiento'] = _fechaNacimiento!.toIso8601String().split('T')[0];
      }
      
      if (_generoSeleccionado != null) {
        perfilData['genero'] = _generoSeleccionado;
      }
      
      // Solo guardar si hay al menos un campo con valor
      if (perfilData.isNotEmpty) {
        await _database.child('usuarios/$uid/perfil').set(perfilData);
      }
    } catch (e) {
      log.info('Error al guardar el perfil: $e');
      // No mostramos el error al usuario para no interrumpir el flujo de registro
    }
  }
  
  // Seleccionar fecha de nacimiento
  Future<void> _seleccionarFecha() async {
    final DateTime fechaActual = DateTime.now();
    final DateTime fechaMinima = DateTime(fechaActual.year - 100, 1, 1);
    final DateTime fechaMaxima = DateTime(fechaActual.year, fechaActual.month, fechaActual.day);
    
    final DateTime? fechaSeleccionada = await showDatePicker(
      context: context,
      initialDate: DateTime(fechaActual.year - 18, fechaActual.month, fechaActual.day), // Default a 18 años
      firstDate: fechaMinima,
      lastDate: fechaMaxima,
      helpText: 'Selecciona tu fecha de nacimiento',
      cancelText: 'Cancelar',
      confirmText: 'Aceptar',
    );
    
    if (fechaSeleccionada != null) {
      setState(() => _fechaNacimiento = fechaSeleccionada);
    }
  }
  
  Future<void> _completeRegistration() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Actualizar el perfil del usuario con el nombre
      if (_nombreCompletoController.text.isNotEmpty) {
        await _auth.currentUser?.updateDisplayName(_nombreCompletoController.text.trim());
      }
      
      // Esperar a que el usuario actualice la verificación de email
      await _auth.currentUser?.reload();
      
      if (!mounted) return;
      
      if (_auth.currentUser?.emailVerified == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registro completado con éxito')),
        );
        
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Por favor, verifica tu correo electrónico')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  Widget _buildRegistrationForm() {
    return Form(
      key: _formKey,
      child: Column(
        children: [
          const Text(
            'Registrarse',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 20),
          
          // Nombre completo
          TextField(
            controller: _nombreCompletoController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.person),
              hintText: 'Nombre completo',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Nombre de usuario
          TextField(
            controller: _usuarioController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.alternate_email),
              hintText: 'Nombre de usuario',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Email - campo obligatorio
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.email),
              hintText: 'Correo electrónico *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Contraseña - campo obligatorio
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock),
              hintText: 'Contraseña *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Confirmar contraseña - campo obligatorio
          TextField(
            controller: _confirmPasswordController,
            obscureText: true,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.lock_outline),
              hintText: 'Confirmar contraseña *',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Fecha de nacimiento (opcional)
          GestureDetector(
            onTap: _seleccionarFecha,
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: 'Fecha de nacimiento',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.calendar_today),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _fechaNacimiento == null
                        ? 'Selecciona tu fecha de nacimiento'
                        : DateFormat('dd/MM/yyyy').format(_fechaNacimiento!),
                    style: TextStyle(
                      color: _fechaNacimiento == null
                          ? Colors.grey
                          : Colors.black,
                    ),
                  ),
                  Icon(
                    Icons.arrow_drop_down,
                    color: _fechaNacimiento == null ? Colors.grey : Colors.blue,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Género (opcional)
          DropdownButtonFormField<String>(
            value: _generoSeleccionado,
            decoration: InputDecoration(
              labelText: 'Género',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              prefixIcon: const Icon(Icons.people),
            ),
            hint: const Text('Selecciona tu género'),
            onChanged: (String? newValue) {
              setState(() {
                _generoSeleccionado = newValue;
              });
            },
            items: _opcionesGenero.map((String genero) {
              return DropdownMenuItem<String>(
                value: genero,
                child: Text(genero),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          
          // Descripción (opcional)
          TextField(
            controller: _descripcionController,
            maxLines: 3,
            maxLength: 150,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.description),
              hintText: 'Descripción (opcional)',
              helperText: 'Máximo 150 caracteres',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          
          // Botón para enviar verificación
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _requestVerificationCode,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4A90E2),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Enviar código de verificación',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Enlace para ir a inicio de sesión
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Ya tengo una cuenta. Iniciar sesión'),
          ),
        ],
      ),
    );
  }

  Widget _buildVerificationScreen() {
    return Column(
      children: [
        const Text(
          'Verificación de correo',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Por favor, verifica tu correo electrónico. Hemos enviado un enlace de verificación a tu correo. Haz clic en el enlace para verificar tu cuenta.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: Color(0xFF6D6D6D)),
        ),
        const SizedBox(height: 20),
        Text(
          'Correo: $_unverifiedEmail',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF333333),
          ),
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _completeRegistration,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4A90E2),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text(
                    'He verificado mi correo',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: _isLoading ? null : () {
              _auth.currentUser?.sendEmailVerification();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Se ha reenviado el correo de verificación')),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              side: const BorderSide(color: Color(0xFF4A90E2)),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Reenviar correo de verificación',
              style: TextStyle(fontSize: 16, color: Color(0xFF4A90E2)),
            ),
          ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: () {
            setState(() {
              _showVerificationCodeScreen = false;
            });
          },
          child: const Text('Volver'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C1B29),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 450, // Aumenté el ancho para acomodar más campos
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color.fromRGBO(0, 0, 0, 0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: _showVerificationCodeScreen
                    ? _buildVerificationScreen()
                    : _buildRegistrationForm(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
