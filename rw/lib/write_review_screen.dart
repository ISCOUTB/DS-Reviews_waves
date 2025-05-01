import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:logging/logging.dart';
import 'review_service.dart';

// Logger para esta pantalla
final log = Logger('WriteReviewScreen');

class WriteReviewScreen extends StatefulWidget {
  final int movieId;
  final String movieTitle;
  final String posterPath;
  final List<String> genres;
  final String? existingReviewId;
  final Map<String, dynamic>? existingReviewData;

  const WriteReviewScreen({
    super.key,
    required this.movieId,
    required this.movieTitle,
    required this.posterPath,
    this.genres = const [],
    this.existingReviewId,
    this.existingReviewData,
  });

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final ReviewService _reviewService = ReviewService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  
  int _rating = 0;
  bool _isSubmitting = false;
  String _errorMessage = '';
  
  // Referencia al usuario actual
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    
    // Si estamos editando una reseña existente, prellenamos los campos
    if (widget.existingReviewData != null) {
      _titleController.text = widget.existingReviewData?['title'] ?? '';
      _contentController.text = widget.existingReviewData?['content'] ?? 
                               widget.existingReviewData?['texto'] ?? '';
      _rating = (widget.existingReviewData?['rating'] as num?)?.toInt() ?? 0;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingReviewId != null 
            ? 'Editar reseña' 
            : 'Escribir reseña'),
        actions: [
          // Botón de guardar
          if (!_isSubmitting)
            IconButton(
              icon: const Icon(Icons.save),
              tooltip: 'Guardar reseña',
              onPressed: _submitReview,
            ),
        ],
      ),
      body: _buildContent(),
    );
  }

  Widget _buildContent() {
    if (_currentUser == null) {
      return _buildLoginRequired();
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Información de la película
            _buildMovieInfo(),
            
            const SizedBox(height: 24),
            
            // Rating con estrellas
            _buildRatingSelector(),
            
            const SizedBox(height: 20),
            
            // Campo de título de la reseña
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Título de tu reseña (opcional)',
                hintText: 'Ej: Una película impresionante',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
              maxLength: 100,
              validator: (value) {
                if (value != null && value.length > 100) {
                  return 'El título debe tener menos de 100 caracteres';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 20),
            
            // Campo de contenido de la reseña
            TextFormField(
              controller: _contentController,
              decoration: const InputDecoration(
                labelText: 'Escribe tu reseña',
                hintText: 'Comparte tu opinión sobre esta película...',
                border: OutlineInputBorder(),
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.edit_note),
              ),
              maxLines: 8,
              maxLength: 1000,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Por favor escribe tu opinión';
                }
                if (value.length < 10) {
                  return 'Tu reseña debe tener al menos 10 caracteres';
                }
                return null;
              },
            ),
            
            const SizedBox(height: 16),
            
            // Mensaje de error si existe
            if (_errorMessage.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade300),
                ),
                child: Text(
                  _errorMessage,
                  style: TextStyle(color: Colors.red.shade700),
                ),
              ).animate().shake(),
            
            const SizedBox(height: 24),
            
            // Botón para enviar la reseña
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: _isSubmitting
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        widget.existingReviewId != null
                            ? 'Actualizar reseña'
                            : 'Publicar reseña',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoginRequired() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'Inicia sesión para escribir una reseña',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              // Aquí podrías navegar a la pantalla de login
              Navigator.of(context).pop();
            },
            child: const Text('Volver'),
          ),
        ],
      ),
    );
  }

  Widget _buildMovieInfo() {
    final String posterUrl = widget.posterPath.isNotEmpty
      ? (widget.posterPath.startsWith('http')
          ? widget.posterPath
          : 'https://image.tmdb.org/t/p/w185${widget.posterPath}')
      : 'https://via.placeholder.com/185x278?text=No+Poster';
    
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Póster de la película
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: CachedNetworkImage(
            imageUrl: posterUrl,
            width: 80,
            height: 120,
            fit: BoxFit.cover,
            placeholder: (context, url) => Container(
              color: Colors.grey[300],
              child: const Center(child: CircularProgressIndicator()),
            ),
            errorWidget: (context, url, error) => Container(
              color: Colors.grey[300],
              width: 80,
              height: 120,
              child: const Icon(Icons.error),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Información de la película
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.movieTitle,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              
              const SizedBox(height: 8),
              
              // Géneros
              if (widget.genres.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: widget.genres.map((genre) => Chip(
                    label: Text(
                      genre,
                      style: const TextStyle(fontSize: 12),
                    ),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  )).toList(),
                ),
              
              const SizedBox(height: 4),
              
              // Fecha actual
              Text(
                'Escribiendo el ${DateFormat.yMMMd().format(DateTime.now())}',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRatingSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tu calificación',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.grey[800],
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final int starValue = index + 1;
            return IconButton(
              icon: Icon(
                starValue <= _rating ? Icons.star : Icons.star_border,
                color: starValue <= _rating ? Colors.amber : Colors.grey,
                size: 32,
              ),
              onPressed: () => setState(() => _rating = starValue),
            );
          }),
        ),
        Center(
          child: Text(
            _getRatingText(),
            style: TextStyle(
              color: _rating > 0 ? _getRatingColor() : Colors.grey,
              fontStyle: _rating > 0 ? FontStyle.normal : FontStyle.italic,
            ),
          ),
        ),
      ],
    );
  }

  String _getRatingText() {
    if (_rating == 0) return 'Toca una estrella para calificar';
    if (_rating == 1) return 'Muy mala';
    if (_rating == 2) return 'Mala';
    if (_rating == 3) return 'Regular';
    if (_rating == 4) return 'Buena';
    return 'Excelente';
  }

  Color _getRatingColor() {
    if (_rating <= 2) return Colors.red;
    if (_rating == 3) return Colors.orange;
    return Colors.green;
  }

  void _submitReview() async {
    // Validar el formulario
    if (_formKey.currentState?.validate() != true) {
      return;
    }
    
    // Validar que haya una calificación
    if (_rating == 0) {
      setState(() {
        _errorMessage = 'Por favor, selecciona una calificación para la película';
      });
      return;
    }
    
    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });
    
    try {
      final Map<String, dynamic> reviewData = {
        'mediaId': widget.movieId.toString(),
        'mediaTitle': widget.movieTitle,
        'posterPath': widget.posterPath,
        'rating': _rating,
        'content': _contentController.text.trim(),
        'title': _titleController.text.trim(),
        // La fecha y el usuario se añaden automáticamente en el servicio
      };
      
      if (widget.existingReviewId != null) {
        // Actualizamos la reseña existente
        await _reviewService.updateReview(
          widget.existingReviewId!,
          reviewData,
        );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reseña actualizada correctamente')),
          );
          Navigator.pop(context, true); // true indica actualización exitosa
        }
      } else {
        // Creamos una nueva reseña
        await _reviewService.createReview(reviewData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reseña publicada correctamente')),
          );
          Navigator.pop(context, true); // true indica creación exitosa
        }
      }
    } catch (e) {
      log.severe('Error al ${widget.existingReviewId != null ? 'actualizar' : 'crear'} reseña: $e');
      setState(() {
        _isSubmitting = false;
        _errorMessage = 'Error: ${e.toString()}';
      });
    }
  }
}
