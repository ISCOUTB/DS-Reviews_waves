import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:confetti/confetti.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:logging/logging.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'widgets/profile_stats_card.dart';
import 'widgets/profile_edit_form.dart';
import 'widgets/review_list.dart';
import 'widgets/favorites_grid.dart';
import 'widgets/shimmer_loading.dart';

// Inicializamos el logger específico para la pantalla de perfil
final log = Logger('PerfilScreen');

class PerfilScreen extends StatefulWidget {
  const PerfilScreen({super.key});

  @override
  State<PerfilScreen> createState() => _PerfilScreenState();
}

class _PerfilScreenState extends State<PerfilScreen> with TickerProviderStateMixin {
  // Controlador para las pestañas
  late TabController _tabController;
  
  // Información del usuario actual
  User? _currentUser;
  Map<String, dynamic> _userData = {};
  
  // Estados de carga
  bool _isLoading = true;
  bool _isSaving = false;
  
  // Avatar seleccionado actualmente
  String _selectedAvatar = '';
  
  // Lista de reseñas y favoritos del usuario
  List<Map<String, dynamic>> _userReviews = [];
  List<Map<String, dynamic>> _userFavorites = [];
  bool _isLoadingReviews = false;
  bool _isLoadingFavorites = false;
  
  // Categorías de avatares y avatares actuales
  final List<String> _avatarCategories = [
    'Profesionales', 
    'Caricaturas', 
    'Videojuegos',
    'Anime',
    'Películas',
    'Mascotas',
    'Retro',
    'Abstractos'
  ];
  int _selectedCategoryIndex = 0;
  
  // Controlador de confetti
  late ConfettiController _confettiController;
  
  // Referencias a APIs externas de avatares
  final Map<String, String> _apiBaseUrls = {
    'Profesionales': 'https://api.dicebear.com/7.x/personas/svg',
    'Caricaturas': 'https://api.dicebear.com/7.x/adventurer/svg',
    'Videojuegos': 'https://api.dicebear.com/7.x/pixel-art/svg',
    'Anime': 'https://api.dicebear.com/7.x/micah/svg',
    'Películas': 'https://api.dicebear.com/7.x/bottts/svg',
    'Mascotas': 'https://api.dicebear.com/7.x/notionists/svg',
    'Retro': 'https://api.dicebear.com/7.x/8bit/svg',
    'Abstractos': 'https://api.dicebear.com/7.x/shapes/svg',
  };
  
  // Descripciones de categorías de avatares
  final Map<String, String> _categoryDescriptions = {
    'Profesionales': 'Avatares de estilo profesional y moderno',
    'Caricaturas': 'Personajes divertidos y expresivos',
    'Videojuegos': 'Inspirados en personajes de videojuegos retro',
    'Anime': 'Estilo manga japonés',
    'Películas': 'Inspirados en personajes de cine y series',
    'Mascotas': 'Avatares de animales y criaturas adorables',
    'Retro': 'Estilo pixelado de 8-bit',
    'Abstractos': 'Formas y patrones geométricos',
  };
  
  // Lista de avatares por categoría
  final Map<String, List<String>> _avatarsByCategory = {};
  
  // Animación de categorías
  late AnimationController _categoryAnimController;
  
  // Referencia a la base de datos de Firebase
  final _database = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL: 'https://reviews-waves-86c01-default-rtdb.firebaseio.com',
  ).ref();

  // Variables para controlar el shimmer en el avatar
  bool _isAvatarShimmering = false;
  bool _isProfileShimmering = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _currentUser = FirebaseAuth.instance.currentUser;
    _confettiController = ConfettiController(duration: const Duration(seconds: 2));
    _categoryAnimController = AnimationController(vsync: this, duration: const Duration(milliseconds: 300));
    
    // Generamos las listas de avatares por categoría
    _generateAvatarsForCategories();
    
    // Cargamos los datos del perfil del usuario desde Firebase
    _loadUserData();
    
    // Escuchamos los cambios de pestaña para cargar los datos correspondientes
    _tabController.addListener(_handleTabChange);
  }

  // Convertir valores de opacidad (0.0-1.0) a valores alpha (0-255)
  int _opacityToAlpha(double opacity) {
    return (opacity * 255).round();
  }

  // Generamos listas de avatares para todas las categorías
  void _generateAvatarsForCategories() {
    final random = Random();
    
    for (final category in _avatarCategories) {
      final List<String> avatars = [];
      final baseUrl = _apiBaseUrls[category]!;
      
      // Generamos 24 avatares diferentes para cada categoría
      for (int i = 0; i < 24; i++) {
        // Generamos un seed diferente para cada avatar
        final seed = '${category}_${random.nextInt(10000)}';
        
        // Agregamos algunos parámetros específicos para cada API para personalizarlos
        String avatarUrl = '$baseUrl?seed=$seed';
        
        switch (category) {
          case 'Profesionales':
            avatarUrl += '&backgroundColor=b6e3f4,c0aede,d1d4f9,ffd5dc,ffdfbf';
            break;
          case 'Caricaturas':
            avatarUrl += '&backgroundColor=transparent&skinColor=ecad80,f0c6a0,d8a162,ae8e70';
            break;
          case 'Videojuegos':
            avatarUrl += '&backgroundColor=transparent&scale=80';
            break;
          case 'Anime':
            avatarUrl += '&earrings=variant01,variant02,variant03&eyes=variant26,variant10,variant23';
            break;
          case 'Películas':
            avatarUrl += '&backgroundColor=172026,2f3136,1a1d21&scale=90';
            break;
          case 'Mascotas':
            avatarUrl += '&backgroundColor=transparent&scale=80&mouth=variant03,variant02,variant07';
            break;
          case 'Retro':
            avatarUrl += '&backgroundColor=0da2ff,0c7bb3,2596be&scale=75';
            break;
          case 'Abstractos':
            avatarUrl += '&backgroundColor=b6e3f4,c0aede,d1d4f9&colors=2&colorLevel=600';
            break;
        }
        
        avatars.add(avatarUrl);
      }
      
      _avatarsByCategory[category] = avatars;
    }
  }

  // Manejamos el cambio de pestaña para cargar los datos correspondientes
  void _handleTabChange() {
    if (_tabController.index == 1 && _userReviews.isEmpty && !_isLoadingReviews) {
      _loadUserReviews();
    } else if (_tabController.index == 2 && _userFavorites.isEmpty && !_isLoadingFavorites) {
      _loadUserFavorites();
    }
  }

  // Cargar los datos del perfil del usuario desde Firebase
  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      if (_currentUser != null) {
        DataSnapshot snapshot = await _database.child('usuarios/${_currentUser!.uid}/perfil').get();
        
        if (!mounted) return;
        
        if (snapshot.exists) {
          Map<String, dynamic> data = Map<String, dynamic>.from(snapshot.value as Map);
          setState(() {
            _userData = data;
            
            // Si ya tiene un avatar guardado, lo utilizamos
            if (data.containsKey('avatarUrl')) {
              _selectedAvatar = data['avatarUrl'];
              
              // Intentamos determinar la categoría del avatar seleccionado
              for (var i = 0; i < _avatarCategories.length; i++) {
                final category = _avatarCategories[i];
                if (_selectedAvatar.contains(_apiBaseUrls[category]!.split('/').last)) {
                  _selectedCategoryIndex = i;
                  break;
                }
              }
            } else {
              // De lo contrario, asignamos uno por defecto
              _selectedAvatar = _avatarsByCategory['Profesionales']![0];
            }
            
            _isLoading = false;
          });
        } else {
          // No hay datos del usuario, usamos valores por defecto
          setState(() {
            _userData = {};
            _selectedAvatar = _avatarsByCategory['Profesionales']![0];
            _isLoading = false;
          });
        }
        
        // Cargamos las estadísticas del usuario
        _loadUserStats();
      } else {
        // Usuario no autenticado
        setState(() {
          _userData = {};
          _selectedAvatar = _avatarsByCategory['Profesionales']![0];
          _isLoading = false;
        });
      }
    } catch (e) {
      log.severe('Error al cargar datos del usuario: $e');
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _userData = {};
        _selectedAvatar = _avatarsByCategory['Profesionales']![0];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    }
  }
  
  // Cargar las estadísticas del usuario (contadores)
  Future<void> _loadUserStats() async {
    if (_currentUser == null) return;
    
    try {
      // Conteo de reseñas
      DataSnapshot reviewsSnapshot = await _database.child('usuarios/${_currentUser!.uid}/resenas').get();
      final int reviewsCount = reviewsSnapshot.exists ? (reviewsSnapshot.value as Map).length : 0;
      
      // Conteo de favoritos
      DataSnapshot favoritesSnapshot = await _database.child('usuarios/${_currentUser!.uid}/favoritos').get();
      final int favoritesCount = favoritesSnapshot.exists ? (favoritesSnapshot.value as Map).length : 0;
      
      if (!mounted) return;
      
      // Guardamos los conteos en userData
      setState(() {
        _userData = {
          ..._userData,
          'reviewsCount': reviewsCount,
          'favoritesCount': favoritesCount,
        };
      });
    } catch (e) {
      log.warning('Error al cargar estadísticas del usuario: $e');
    }
  }
  
  // Cargar las reseñas del usuario
  Future<void> _loadUserReviews() async {
    if (_currentUser == null) return;
    
    setState(() {
      _isLoadingReviews = true;
    });
    
    try {
      DataSnapshot snapshot = await _database.child('usuarios/${_currentUser!.uid}/resenas').get();
      
      if (!mounted) return;
      
      List<Map<String, dynamic>> reviews = [];
      
      if (snapshot.exists) {
        Map<dynamic, dynamic> reviewsData = snapshot.value as Map;
        
        // Convertimos los datos de Firebase a una lista de Maps
        reviewsData.forEach((key, value) {
          final Map<String, dynamic> review = Map<String, dynamic>.from(value as Map);
          review['id'] = key;
          reviews.add(review);
        });
        
        // Ordenamos por fecha (más reciente primero)
        reviews.sort((a, b) {
          DateTime dateA = DateTime.tryParse(a['fecha'] ?? '') ?? DateTime(1900);
          DateTime dateB = DateTime.tryParse(b['fecha'] ?? '') ?? DateTime(1900);
          return dateB.compareTo(dateA);
        });
      }
      
      setState(() {
        _userReviews = reviews;
        _isLoadingReviews = false;
      });
    } catch (e) {
      log.warning('Error al cargar reseñas del usuario: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingReviews = false;
      });
    }
  }
  
  // Cargar las películas favoritas del usuario
  Future<void> _loadUserFavorites() async {
    if (_currentUser == null) return;
    
    setState(() {
      _isLoadingFavorites = true;
    });
    
    try {
      DataSnapshot snapshot = await _database.child('usuarios/${_currentUser!.uid}/favoritos').get();
      
      if (!mounted) return;
      
      List<Map<String, dynamic>> favorites = [];
      
      if (snapshot.exists) {
        Map<dynamic, dynamic> favoritesData = snapshot.value as Map;
        
        // Convertimos los datos de Firebase a una lista de Maps
        favoritesData.forEach((key, value) {
          final Map<String, dynamic> favorite = Map<String, dynamic>.from(value as Map);
          favorite['id'] = key;
          favorites.add(favorite);
        });
      }
      
      setState(() {
        _userFavorites = favorites;
        _isLoadingFavorites = false;
      });
    } catch (e) {
      log.warning('Error al cargar favoritos del usuario: $e');
      if (!mounted) return;
      setState(() {
        _isLoadingFavorites = false;
      });
    }
  }
  
  // Guardar la información del perfil del usuario en Firebase
  Future<void> _saveUserData(Map<String, dynamic> updatedData) async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Necesitas iniciar sesión para guardar tu perfil')),
      );
      return;
    }
    
    setState(() {
      _isSaving = true;
      _isProfileShimmering = true; // Activamos el shimmer
    });
    
    try {
      await _database.child('usuarios/${_currentUser!.uid}/perfil').update(updatedData);
      
      // Simulamos un pequeño delay para que se aprecie el efecto shimmer
      await Future.delayed(const Duration(milliseconds: 800));
      
      if (!mounted) return;
      
      setState(() {
        _userData = {..._userData, ...updatedData};
        _isSaving = false;
      });
      
      // Mostramos el efecto de confetti
      _confettiController.play();
      
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          setState(() {
            _isProfileShimmering = false; // Desactivamos el shimmer
          });
        }
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Perfil actualizado correctamente')),
      );
    } catch (e) {
      log.severe('Error al guardar datos del usuario: $e');
      if (!mounted) return;
      setState(() {
        _isSaving = false;
        _isProfileShimmering = false; // Desactivamos el shimmer en caso de error
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar perfil: $e')),
      );
    }
  }

  // Guardar el avatar seleccionado en Firebase
  Future<void> _saveSelectedAvatar() async {
    if (_currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Necesitas iniciar sesión para guardar tu avatar')),
      );
      return;
    }
    
    setState(() {
      _isAvatarShimmering = true; // Activamos el efecto shimmer
    });
    
    try {
      // Guardamos el avatar en Firebase
      await _database.child('usuarios/${_currentUser!.uid}/perfil/avatarUrl').set(_selectedAvatar);
      
      // Simulamos una pequeña espera para apreciar el efecto shimmer
      await Future.delayed(const Duration(milliseconds: 600));
      
      if (!mounted) return;
      
      setState(() {
        _userData = {..._userData, 'avatarUrl': _selectedAvatar};
        _isAvatarShimmering = false; // Desactivamos el efecto shimmer
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar guardado correctamente')),
      );
    } catch (e) {
      log.severe('Error al guardar avatar: $e');
      if (!mounted) return;
      setState(() {
        _isAvatarShimmering = false; // Desactivamos el shimmer en caso de error
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    }
  }

  // Cambiar de categoría de avatares
  void _changeCategory(int index) {
    setState(() {
      _selectedCategoryIndex = index;
      _categoryAnimController.reset();
      _categoryAnimController.forward();
    });
  }
  
  // Seleccionar un avatar
  void _selectAvatar(String avatarUrl) {
    setState(() {
      _selectedAvatar = avatarUrl;
    });
  }
  
  // Abrir el selector de avatares
  void _openAvatarSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildAvatarSelectorSheet(),
    );
  }

  // Construir el selector de avatares como bottom sheet
  Widget _buildAvatarSelectorSheet() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabecera del selector
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).primaryColor,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Selecciona tu avatar',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          
          // Previsualización del avatar seleccionado
          Container(
            padding: const EdgeInsets.all(20),
            alignment: Alignment.center,
            child: Column(
              children: [
                Text(
                  'Vista previa',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 10),
                Hero(
                  tag: 'avatar_preview',
                  child: Material(
                    elevation: 8,
                    shape: const CircleBorder(),
                    shadowColor: Theme.of(context).primaryColor.withAlpha(_opacityToAlpha(0.4)),
                    child: CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      child: ClipOval(
                        child: _selectedAvatar.endsWith('.svg')
                            ? SvgPicture.network(
                                _selectedAvatar,
                                placeholderBuilder: (context) => const CircularProgressIndicator(),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              )
                            : CachedNetworkImage(
                                imageUrl: _selectedAvatar,
                                placeholder: (context, url) => const CircularProgressIndicator(),
                                errorWidget: (context, url, error) => const Icon(Icons.error),
                                width: 120,
                                height: 120,
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
                ).animate().scale(duration: 300.ms, curve: Curves.easeOut),
              ],
            ),
          ),
          
          // Descripción de la categoría actual
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: AnimatedBuilder(
              animation: _categoryAnimController,
              builder: (context, child) {
                return AnimatedOpacity(
                  opacity: _categoryAnimController.value,
                  duration: const Duration(milliseconds: 200),
                  child: Text(
                    _categoryDescriptions[_avatarCategories[_selectedCategoryIndex]] ?? '',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      color: Colors.grey[600],
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Tabs de categorías
          SizedBox(
            height: 50,
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: _avatarCategories.length,
              itemBuilder: (context, index) {
                final bool isSelected = _selectedCategoryIndex == index;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      _avatarCategories[index],
                      style: GoogleFonts.poppins(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    selected: isSelected,
                    selectedColor: Theme.of(context).primaryColor.withAlpha(_opacityToAlpha(0.2)),
                    backgroundColor: Theme.of(context).brightness == Brightness.dark
                        ? Colors.grey[800]
                        : Colors.grey[200],
                    onSelected: (selected) {
                      if (selected) {
                        _changeCategory(index);
                      }
                    },
                    avatar: isSelected ? Icon(
                      _getCategoryIcon(_avatarCategories[index]),
                      size: 16,
                      color: Theme.of(context).primaryColor,
                    ) : null,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                      side: isSelected
                          ? BorderSide(color: Theme.of(context).primaryColor, width: 1.5)
                          : BorderSide.none,
                    ),
                  ).animate(target: isSelected ? 1 : 0).scaleXY(end: 1.05, curve: Curves.easeOut, duration: 200.ms),
                );
              },
            ),
          ),
          
          const SizedBox(height: 10),
          
          // Grid de avatares
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation, 
                  child: child,
                );
              },
              child: GridView.builder(
                key: ValueKey<int>(_selectedCategoryIndex),
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _avatarsByCategory[_avatarCategories[_selectedCategoryIndex]]!.length,
                itemBuilder: (context, index) {
                  final avatarUrl = _avatarsByCategory[_avatarCategories[_selectedCategoryIndex]]![index];
                  bool isSelected = _selectedAvatar == avatarUrl;
                  
                  return GestureDetector(
                    onTap: () => _selectAvatar(avatarUrl),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                          width: 3,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.grey[200],
                        boxShadow: isSelected 
                            ? [
                                BoxShadow(
                                  color: Theme.of(context).primaryColor.withAlpha(_opacityToAlpha(0.3)),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ]
                            : [],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Stack(
                          children: [
                            // Avatar
                            Positioned.fill(
                              child: avatarUrl.endsWith('.svg')
                                ? SvgPicture.network(
                                    avatarUrl,
                                    placeholderBuilder: (context) => const Center(child: CircularProgressIndicator()),
                                    width: double.infinity,
                                    height: double.infinity,
                                    fit: BoxFit.cover,
                                  )
                                : CachedNetworkImage(
                                    imageUrl: avatarUrl,
                                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                                    errorWidget: (context, url, error) => const Icon(Icons.error),
                                    fit: BoxFit.cover,
                                  ),
                            ),
                            
                            // Indicador de selección
                            if (isSelected)
                              Positioned(
                                top: 5,
                                right: 5,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).primaryColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ).animate().fade(duration: 200.ms, delay: (50 * index).ms)
                   .scaleXY(begin: 0.9, end: 1, duration: 300.ms, delay: (50 * index).ms, curve: Curves.easeOutBack);
                },
              ),
            ),
          ),
          
          // Botón de guardar
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  _saveSelectedAvatar();
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  elevation: 4,
                  shadowColor: Theme.of(context).primaryColor.withAlpha(_opacityToAlpha(0.5)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Guardar avatar',
                  style: GoogleFonts.poppins(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ).animate()
               .fadeIn(duration: 300.ms)
               .shimmer(duration: 1200.ms, color: Colors.white.withAlpha(_opacityToAlpha(0.4))),
            ),
          ),
        ],
      ),
    );
  }

  // Obtener el icono adecuado para cada categoría
  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Profesionales':
        return Icons.business;
      case 'Caricaturas':
        return Icons.face;
      case 'Videojuegos':
        return Icons.sports_esports;
      case 'Anime':
        return Icons.emoji_emotions;
      case 'Películas':
        return Icons.movie;
      case 'Mascotas':
        return Icons.pets;
      case 'Retro':
        return Icons.videogame_asset;
      case 'Abstractos':
        return Icons.palette;
      default:
        return Icons.image;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Contenido principal
          _isLoading
              ? _buildLoadingState()
              : NestedScrollView(
                  headerSliverBuilder: (context, innerBoxIsScrolled) {
                    return [
                      SliverAppBar(
                        expandedHeight: 200.0,
                        floating: false,
                        pinned: true,
                        flexibleSpace: FlexibleSpaceBar(
                          title: Text(
                            _userData['usuario'] ?? _currentUser?.displayName ?? 'Usuario',
                            style: GoogleFonts.poppins(
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(
                                  offset: const Offset(1, 1),
                                  blurRadius: 3.0,
                                  color: Colors.black.withAlpha(_opacityToAlpha(0.5)),
                                ),
                              ],
                            ),
                          ),
                          background: Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Theme.of(context).primaryColor,
                                  Theme.of(context).primaryColor.withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Column(
                            children: [
                              Stack(
                                alignment: Alignment.bottomRight,
                                children: [
                                  Center(
                                    child: Hero(
                                      tag: 'avatar',
                                      child: ShimmerLoading(
                                        isLoading: _isAvatarShimmering,
                                        child: CircleAvatar(
                                          radius: 60,
                                          backgroundColor: Colors.grey[300],
                                          child: ClipOval(
                                            child: _selectedAvatar.endsWith('.svg')
                                                ? SvgPicture.network(
                                                    _selectedAvatar,
                                                    placeholderBuilder: (context) => const CircularProgressIndicator(),
                                                    width: 120,
                                                    height: 120,
                                                    fit: BoxFit.cover,
                                                  )
                                                : CachedNetworkImage(
                                                    imageUrl: _selectedAvatar,
                                                    placeholder: (context, url) => const CircularProgressIndicator(),
                                                    errorWidget: (context, url, error) => const Icon(Icons.person, size: 60),
                                                    width: 120,
                                                    height: 120,
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                        ),
                                      ),
                                    ).animate().scale(duration: 300.ms, curve: Curves.easeOut),
                                  ),
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Theme.of(context).primaryColor,
                                    child: IconButton(
                                      icon: const Icon(Icons.edit, size: 18, color: Colors.white),
                                      onPressed: _openAvatarSelector,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              ShimmerLoading(
                                isLoading: _isProfileShimmering,
                                child: Column(
                                  children: [
                                    Text(
                                      _userData['nombreCompleto'] ?? 'Sin nombre',
                                      style: GoogleFonts.poppins(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (_userData['descripcion'] != null)
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
                                        child: Text(
                                          _userData['descripcion'],
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.poppins(
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              
                              // Tarjeta de estadísticas
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                child: ShimmerLoading(
                                  isLoading: _isProfileShimmering,
                                  child: ProfileStatsCard(
                                    reviewsCount: _userData['reviewsCount'] ?? 0,
                                    favoritesCount: _userData['favoritesCount'] ?? 0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      SliverPersistentHeader(
                        delegate: _SliverAppBarDelegate(
                          TabBar(
                            controller: _tabController,
                            tabs: const [
                              Tab(text: 'Información'),
                              Tab(text: 'Reseñas'),
                              Tab(text: 'Favoritos'),
                            ],
                            labelStyle: GoogleFonts.poppins(fontWeight: FontWeight.bold),
                            unselectedLabelStyle: GoogleFonts.poppins(),
                            indicatorColor: Theme.of(context).primaryColor,
                            labelColor: Theme.of(context).textTheme.bodyLarge?.color,
                          ),
                        ),
                        pinned: true,
                      ),
                    ];
                  },
                  body: TabBarView(
                    controller: _tabController,
                    children: [
                      // Pestaña de información personal
                      _buildInformacionPersonalTab(),
                      
                      // Pestaña de reseñas publicadas
                      _buildResenasTab(),
                      
                      // Pestaña de películas favoritas
                      _buildFavoritosTab(),
                    ],
                  ),
                ),
          
          // Indicador de carga al guardar
          if (_isSaving)
            Container(
              color: Colors.black.withAlpha(_opacityToAlpha(0.3)),
              child: const Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }
  
  // Widget para el estado de carga de la pantalla
  Widget _buildLoadingState() {
    return ShimmerLoading(
      isLoading: true,
      child: SingleChildScrollView(
        child: Column(
          children: const [
            SizedBox(height: 100),
            ProfileInfoShimmer(),
          ],
        ),
      ),
    );
  }
  
  // Contenido de la pestaña de información personal
  Widget _buildInformacionPersonalTab() {
    return _currentUser == null
        ? const Center(child: Text('Inicia sesión para ver tu información'))
        : ProfileEditForm(
            userData: _userData,
            onSave: _saveUserData,
          );
  }
  
  // Contenido de la pestaña de reseñas publicadas
  Widget _buildResenasTab() {
    return UserReviewList(
      reviews: _userReviews,
      isLoading: _isLoadingReviews,
      onReviewTap: (reviewId) {
        // Aquí se navegaría al detalle de la reseña
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ver reseña: $reviewId')),
        );
      },
    );
  }
  
  // Contenido de la pestaña de películas favoritas
  Widget _buildFavoritosTab() {
    return FavoritesGrid(
      favorites: _userFavorites,
      isLoading: _isLoadingFavorites,
      onMovieTap: (movieId) {
        // Aquí se navegaría al detalle de la película
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ver película: $movieId')),
        );
      },
    );
  }
  
  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _confettiController.dispose();
    _categoryAnimController.dispose();
    super.dispose();
  }
}

// Delegado para el header persistente de las pestañas
class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;

  _SliverAppBarDelegate(this.tabBar);

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _SliverAppBarDelegate oldDelegate) {
    return false;
  }
}