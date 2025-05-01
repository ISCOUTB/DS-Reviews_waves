import 'package:flutter/material.dart';
import 'api_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:logging/logging.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:lottie/lottie.dart';
import 'reviews_screen.dart';
import 'write_review_screen.dart';

// Inicializamos el logger para la pantalla de detalles
final log = Logger('DetailScreen');

class DetailScreen extends StatefulWidget {
  final int id;
  final bool isMovie; // true si es película, false si es serie

  const DetailScreen({super.key, required this.id, required this.isMovie});

  @override
  DetailScreenState createState() => DetailScreenState();
}

class DetailScreenState extends State<DetailScreen> with SingleTickerProviderStateMixin {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _details;
  bool _isLoading = true;
  String _errorMessage = '';
  bool _isFavorite = false;
  bool _isCheckingFavorite = true;
  
  // Animación para el botón de favorito
  late AnimationController _favoriteAnimController;
  bool _showFavoriteAnimation = false;
  
  // Referencia a la base de datos de Firebase
  final _database = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL: 'https://reviews-waves-86c01-default-rtdb.firebaseio.com',
  ).ref();
  
  // Usuario actual
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _loadDetails();
    _checkIfFavorite();
    _favoriteAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
  }

  @override
  void dispose() {
    _favoriteAnimController.dispose();
    super.dispose();
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
  
  // Verificar si la película/serie está en favoritos
  Future<void> _checkIfFavorite() async {
    if (_currentUser == null) {
      setState(() {
        _isCheckingFavorite = false;
      });
      return;
    }
    
    try {
      final String itemId = '${widget.id}';
      
      DataSnapshot snapshot = await _database
          .child('usuarios/${_currentUser.uid}/favoritos')
          .orderByChild('id')
          .equalTo(itemId)
          .get();
      
      setState(() {
        _isFavorite = snapshot.exists;
        _isCheckingFavorite = false;
      });
    } catch (e) {
      log.warning('Error al verificar favorito: $e');
      setState(() {
        _isCheckingFavorite = false;
      });
    }
  }
  
  // Cambiar el estado de favorito (añadir o eliminar)
  Future<void> _toggleFavorite() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Necesitas iniciar sesión para guardar favoritos')),
      );
      return;
    }
    
    if (_details == null) return;
    
    setState(() {
      _isCheckingFavorite = true;
    });
    
    try {
      final String itemType = widget.isMovie ? 'pelicula' : 'serie';
      final String itemId = '${widget.id}';
      
      // Comprobar si ya existe en favoritos
      DataSnapshot existingSnapshot = await _database
          .child('usuarios/${_currentUser.uid}/favoritos')
          .orderByChild('id')
          .equalTo(itemId)
          .get();
      
      if (existingSnapshot.exists) {
        // Si existe, lo eliminamos
        Map<dynamic, dynamic> favorites = existingSnapshot.value as Map;
        String key = favorites.keys.first;
        await _database.child('usuarios/${_currentUser.uid}/favoritos/$key').remove();
        
        setState(() {
          _isFavorite = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Eliminado de favoritos')),
        );
      } else {
        // Si no existe, lo añadimos
        // Preparamos los datos a guardar
        final String title = widget.isMovie ? _details!['title'] ?? 'Sin título' : _details!['name'] ?? 'Sin título';
        final String? posterPath = _details!['poster_path'];
        final String posterUrl = posterPath != null ? 'https://image.tmdb.org/t/p/w185$posterPath' : '';
        
        final Map<String, dynamic> favoriteData = {
          'id': itemId,
          'tipo': itemType,
          'titulo': title,
          'posterUrl': posterUrl,
          'fechaAgregado': DateTime.now().toIso8601String(),
        };
        
        // Guardamos en Firebase
        await _database.child('usuarios/${_currentUser.uid}/favoritos').push().set(favoriteData);
        
        setState(() {
          _isFavorite = true;
          _showFavoriteAnimation = true;
        });
        
        _favoriteAnimController.forward().then((_) {
          _favoriteAnimController.reset();
          setState(() {
            _showFavoriteAnimation = false;
          });
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Añadido a favoritos')),
        );
      }
    } catch (e) {
      log.severe('Error al cambiar estado de favorito: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        _isCheckingFavorite = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.isMovie ? 'Detalles de la Película' : 'Detalles de la Serie',
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Botón de favorito en la barra de navegación
          if (!_isLoading && _errorMessage.isEmpty)
            IconButton(
              icon: _isCheckingFavorite
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: _isFavorite ? Colors.red : Colors.white,
                    ),
              onPressed: _isCheckingFavorite ? null : _toggleFavorite,
              tooltip: _isFavorite ? 'Eliminar de favoritos' : 'Añadir a favoritos',
            ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingView()
          : _errorMessage.isNotEmpty
              ? Center(child: Text('Error: $_errorMessage'))
              : _buildDetailContent(),
    );
  }

  Widget _buildLoadingView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Cambiado de 'assets/lotties/movie-loading.json' a 'lotties/movie-loading.json'
          // para evitar que Flutter duplique el prefijo 'assets/'
          Lottie.asset(
            'lotties/movie-loading.json',
            width: 150,
            height: 150,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) => const CircularProgressIndicator(),
          ),
          const SizedBox(height: 20),
          Text(
            'Cargando detalles...',
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailContent() {
    if (_details == null) {
      return const Center(child: Text('No se encontraron detalles'));
    }

    final String title = widget.isMovie ? _details!['title'] ?? 'Sin título' : _details!['name'] ?? 'Sin título';
    final String overview = _details!['overview'] ?? 'No hay sinopsis disponible';
    final String? posterPath = _details!['poster_path'];
    final String posterUrl = posterPath != null ? 'https://image.tmdb.org/t/p/w342$posterPath' : '';
    final String? backdropPath = _details!['backdrop_path'];
    final String backdropUrl = backdropPath != null 
        ? 'https://image.tmdb.org/t/p/w1280$backdropPath' 
        : 'https://via.placeholder.com/1280x720';
    
    final String genreNames = _details!['genres'] != null
        ? _details!['genres'].map<String>((g) => g['name'].toString()).join(', ')
        : 'Sin géneros';
    
    final double voteAverage = (_details!['vote_average'] ?? 0.0).toDouble();
    final String releaseDate = widget.isMovie 
        ? (_details!['release_date'] ?? 'Desconocido')
        : (_details!['first_air_date'] ?? 'Desconocido');
    final List<dynamic> cast = _details!['credits']?['cast'] ?? [];
    final String director = widget.isMovie 
        ? _getDirector(_details!['credits']?['crew'] ?? [])
        : 'N/A';
        
    return Stack(
      children: [
        // Imagen de fondo con carga progresiva
        Positioned.fill(
          child: CachedNetworkImage(
            imageUrl: backdropUrl,
            fit: BoxFit.cover,
            placeholder: (context, url) => Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(color: Colors.grey),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[900],
              child: const Icon(Icons.broken_image, size: 50, color: Colors.white),
            ),
          ),
        ),
        
        // Efecto de difuminado con gradiente
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withAlpha(_opacityToAlpha(0.7)),
                  Colors.black.withAlpha(_opacityToAlpha(0.9)),
                  Colors.black,
                ],
              ),
            ),
          ),
        ),
        
        // Contenido principal
        Positioned.fill(
          child: SingleChildScrollView(
            padding: const EdgeInsets.only(top: 100, bottom: 20, left: 16, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Área superior con póster e info básica
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Póster con animación y sombras
                    if (posterUrl.isNotEmpty)
                      Hero(
                        tag: 'poster_${widget.id}',
                        child: Container(
                          width: 150,
                          height: 225,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withAlpha(_opacityToAlpha(0.5)),
                                spreadRadius: 1,
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: CachedNetworkImage(
                              imageUrl: posterUrl,
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Shimmer.fromColors(
                                baseColor: Colors.grey[800]!,
                                highlightColor: Colors.grey[600]!,
                                child: Container(color: Colors.grey[800]),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: Colors.grey[800],
                                child: const Icon(Icons.broken_image, color: Colors.white70),
                              ),
                            ),
                          ),
                        ),
                      ).animate().fadeIn(duration: 600.ms).slideY(begin: 0.2, end: 0, duration: 600.ms),
                    const SizedBox(width: 16),
                    
                    // Información básica
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Título con animación
                          Text(
                            title,
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ).animate().fadeIn(delay: 100.ms).slideX(begin: 0.2, end: 0, duration: 500.ms),
                          
                          const SizedBox(height: 8),
                          
                          // Fecha de lanzamiento
                          Row(
                            children: [
                              const Icon(Icons.calendar_today, size: 16, color: Colors.white70),
                              const SizedBox(width: 4),
                              Text(
                                releaseDate,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ).animate().fadeIn(delay: 200.ms),
                          
                          const SizedBox(height: 8),
                          
                          // Géneros
                          Text(
                            'Géneros: $genreNames',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white70,
                            ),
                          ).animate().fadeIn(delay: 300.ms),
                          
                          const SizedBox(height: 8),
                          
                          // Director (solo para películas)
                          if (widget.isMovie && director != 'N/A')
                            Text(
                              'Director: $director',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white70,
                              ),
                            ).animate().fadeIn(delay: 400.ms),
                          
                          const SizedBox(height: 16),
                          
                          // Calificación y botón de favorito
                          Row(
                            children: [
                              // Calificación con estrellas
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _getColorFromRating(voteAverage),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.star, color: Colors.white, size: 18),
                                    const SizedBox(width: 4),
                                    Text(
                                      voteAverage.toStringAsFixed(1),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ).animate().fadeIn(delay: 500.ms),
                              
                              const Spacer(),
                              
                              // Botón de favorito con animación
                              Stack(
                                alignment: Alignment.center,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      _isFavorite ? Icons.favorite : Icons.favorite_border,
                                      color: _isFavorite ? Colors.red : Colors.white,
                                      size: 30,
                                    ),
                                    onPressed: _isCheckingFavorite ? null : _toggleFavorite,
                                  ),
                                  if (_showFavoriteAnimation)
                                    Lottie.asset(
                                      'assets/lotties/heart-animation.json',
                                      controller: _favoriteAnimController,
                                      width: 80,
                                      height: 80,
                                    ),
                                ],
                              ).animate().fadeIn(delay: 500.ms),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Sección de sinopsis
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sinopsis',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(delay: 600.ms),
                    
                    const SizedBox(height: 8),
                    
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.black45,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        overview,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.white.withAlpha(_opacityToAlpha(0.9)),
                          height: 1.5,
                        ),
                      ),
                    ).animate().fadeIn(delay: 700.ms),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Sección de reparto
                if (cast.isNotEmpty) Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Reparto Principal',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(delay: 800.ms),
                    
                    const SizedBox(height: 12),
                    
                    SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: cast.length > 10 ? 10 : cast.length,
                        itemBuilder: (context, index) {
                          final actor = cast[index];
                          final String? profilePath = actor['profile_path'];
                          final String actorImageUrl = profilePath != null
                              ? 'https://image.tmdb.org/t/p/w185$profilePath'
                              : '';
                          
                          return Container(
                            width: 80,
                            margin: const EdgeInsets.only(right: 10),
                            child: Column(
                              children: [
                                Container(
                                  width: 70,
                                  height: 70,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(35),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withAlpha(_opacityToAlpha(0.3)),
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(35),
                                    child: actorImageUrl.isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: actorImageUrl,
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) => Container(
                                            color: Colors.grey[800],
                                            child: const Center(child: Icon(Icons.person, color: Colors.white54)),
                                          ),
                                          errorWidget: (context, url, error) => Container(
                                            color: Colors.grey[800],
                                            child: const Center(child: Icon(Icons.person, color: Colors.white54)),
                                          ),
                                        )
                                      : Container(
                                          color: Colors.grey[800],
                                          child: const Center(child: Icon(Icons.person, color: Colors.white54)),
                                        ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  actor['name'] ?? '',
                                  style: const TextStyle(color: Colors.white, fontSize: 12),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  actor['character'] ?? '',
                                  style: TextStyle(color: Colors.white.withAlpha(_opacityToAlpha(0.7)), fontSize: 10),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: Duration(milliseconds: 800 + (index * 50)));
                        },
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 32),
                
                // Botones de acción
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.rate_review),
                        label: const Text('Ver Reseñas'),
                        onPressed: () {
                          // Navegamos a la pantalla de reseñas
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ReviewsScreen(
                                movieId: widget.id,
                                movieTitle: title,
                                posterPath: posterPath ?? '',
                                genres: _details!['genres']?.map<String>((g) => g['name'].toString()).toList() ?? [],
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 900.ms).slideY(begin: 0.2, end: 0, duration: 500.ms),
                
                const SizedBox(height: 12),
                
                // Botón para escribir reseña
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.edit),
                        label: const Text('Escribir Reseña'),
                        onPressed: _currentUser != null 
                          ? () {
                              // Navegamos a la pantalla para escribir reseñas
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => WriteReviewScreen(
                                    movieId: widget.id,
                                    movieTitle: title,
                                    posterPath: posterPath ?? '',
                                    genres: _details!['genres']?.map<String>((g) => g['name'].toString()).toList() ?? [],
                                  ),
                                ),
                              );
                            }
                          : () {
                              // Mostrar mensaje para iniciar sesión
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Debes iniciar sesión para escribir una reseña'),
                                  duration: Duration(seconds: 3),
                                ),
                              );
                            },
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white54),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 1000.ms).slideY(begin: 0.2, end: 0, duration: 500.ms),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Método para obtener el color según la calificación
  Color _getColorFromRating(double rating) {
    if (rating >= 8) {
      return Colors.green;
    } else if (rating >= 5) {
      return Colors.orange;
    } else {
      return Colors.red;
    }
  }
  
  // Método para obtener el director de la película
  String _getDirector(List<dynamic> crew) {
    for (var member in crew) {
      if (member['job'] == 'Director') {
        return member['name'] ?? 'Desconocido';
      }
    }
    return 'Desconocido';
  }

  // Función auxiliar para convertir opacity (0.0-1.0) a alpha (0-255)
  int _opacityToAlpha(double opacity) {
    return (opacity * 255).round();
  }
}
