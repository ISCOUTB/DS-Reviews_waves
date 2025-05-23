import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logging/logging.dart';

// Inicializar logger para este servicio
final log = Logger('ReviewService');

class ReviewService {
  // Instancia de Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Obtener la colección de reviews
  CollectionReference get _reviewsCollection => _firestore.collection('reviews');

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  // Obtener todas las reseñas
  Stream<QuerySnapshot> getAllReviews() {
    return _reviewsCollection
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Obtener reseñas por género
  Stream<QuerySnapshot> getReviewsByGenre(String genre) {
    return _reviewsCollection
        .where('genre', isEqualTo: genre)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Obtener reseñas para un medio específico
  Stream<QuerySnapshot> getReviewsForMedia(String mediaId) {
    return _reviewsCollection
        .where('mediaId', isEqualTo: mediaId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Obtener reseñas de un usuario específico
  Stream<QuerySnapshot> getReviewsByUser(String userId) {
    return _reviewsCollection
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // Crear una nueva reseña
  Future<DocumentReference> createReview(Map<String, dynamic> reviewData) async {
    if (currentUser == null) {
      throw Exception('Usuario no autenticado');
    }

    final Map<String, dynamic> completeData = {
      'title': reviewData['title'] ?? '',
      'content': reviewData['content'] ?? '',
      'rating': reviewData['rating'] ?? 0,
      'genre': reviewData['genre'] ?? 'movie',
      'mediaId': reviewData['mediaId'] ?? '',
      'mediaTitle': reviewData['mediaTitle'] ?? '',
      'posterPath': reviewData['posterPath'] ?? '',
      'userId': currentUser!.uid,
      'authorName': currentUser!.displayName ?? 'Usuario anónimo',
      'authorPhotoURL': currentUser!.photoURL ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };

    return await _reviewsCollection.add(completeData);
  }

  // Actualizar una reseña existente
  Future<void> updateReview(String reviewId, Map<String, dynamic> reviewData) async {
    if (currentUser == null) {
      throw Exception('Usuario no autenticado');
    }

    final Map<String, dynamic> updateData = {
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (reviewData.containsKey('title')) updateData['title'] = reviewData['title'];
    if (reviewData.containsKey('content')) updateData['content'] = reviewData['content'];
    if (reviewData.containsKey('rating')) updateData['rating'] = reviewData['rating'];
    if (reviewData.containsKey('genre')) updateData['genre'] = reviewData['genre'];

    await _reviewsCollection.doc(reviewId).update(updateData);
  }

  // Eliminar una reseña
  Future<void> deleteReview(String reviewId) async {
    if (currentUser == null) {
      throw Exception('Usuario no autenticado');
    }
    
    try {
      final doc = await _reviewsCollection.doc(reviewId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final userId = data['userId'];
        
        if (userId == currentUser!.uid) {
          await _reviewsCollection.doc(reviewId).delete();
        } else {
          throw Exception('No tienes permiso para eliminar esta reseña');
        }
      } else {
        throw Exception('La reseña no existe');
      }
    } catch (e) {
      log.severe('Error eliminando reseña: $e');
      throw Exception('Error al eliminar la reseña: $e');
    }
  }
}