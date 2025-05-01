import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

class ReviewService {
  // Instancia de Firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Instancia de Realtime Database (para mantener compatibilidad con código existente)
  final DatabaseReference _rtdb = FirebaseDatabase.instanceFor(
    app: FirebaseDatabase.instance.app,
    databaseURL: 'https://reviews-waves-86c01-default-rtdb.firebaseio.com',
  ).ref().child('reseñas');
  
  // Obtener la colección de reviews
  CollectionReference get _reviewsCollection => _firestore.collection('reviews');

  // Obtener usuario actual
  User? get currentUser => _auth.currentUser;

  // ===== Métodos de compatibilidad con código existente =====
  
  // Mantener compatibilidad con fetchReviewsForMovie existente
  Future<List<Map<String, dynamic>>> fetchReviewsForMovie(int movieId) async {
    try {
      // Intentamos primero leer de Firestore si está disponible
      QuerySnapshot querySnapshot = await _reviewsCollection
          .where('mediaId', isEqualTo: movieId.toString())
          .orderBy('createdAt', descending: true)
          .get();
      
      if (querySnapshot.docs.isNotEmpty) {
        return querySnapshot.docs.map((doc) {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
          return {
            'userId': data['userId'],
            'texto': data['content'], // Mapeamos 'content' a 'texto' para mantener compatibilidad
            'rating': (data['rating'] as num).toDouble(),
            'timestamp': data['createdAt'] is Timestamp 
                ? (data['createdAt'] as Timestamp).millisecondsSinceEpoch 
                : DateTime.now().millisecondsSinceEpoch,
          };
        }).toList();
      }
      
      // Si no encontramos nada en Firestore, recurrimos a Realtime Database
      final DataSnapshot snap = await _rtdb.child(movieId.toString()).get();
      if (!snap.exists || snap.value == null) return [];
      final Map<dynamic, dynamic> map = snap.value as Map<dynamic, dynamic>;
      return map.entries.map((e) {
        final data = e.value as Map<dynamic, dynamic>;
        return {
          'userId': e.key.toString(),
          'texto': data['texto'],
          'rating': (data['rating'] as num).toDouble(),
          'timestamp': data['timestamp'],
        };
      }).toList();
    } catch (e) {
      print('Error obteniendo reseñas: $e');
      return [];
    }
  }

  // Mantener compatibilidad con submitReview existente
  Future<void> submitReview({
    required int movieId,
    required String userId,
    required String texto,
    required double rating,
  }) async {
    try {
      // Guardar en Firestore (la nueva implementación)
      await _reviewsCollection.add({
        'title': 'Reseña de película',
        'content': texto,
        'rating': rating,
        'genre': 'movie', // Valor por defecto
        'mediaId': movieId.toString(),
        'mediaTitle': 'Película $movieId', // Ideal sería obtener el título real
        'mediaPosterUrl': '', // Ideal sería obtener el poster real
        'userId': userId,
        'authorName': _auth.currentUser?.displayName ?? 'Usuario',
        'authorPhotoURL': _auth.currentUser?.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      
      // También guardar en Realtime Database para mantener compatibilidad
      await _rtdb.child(movieId.toString()).child(userId).set({
        'texto': texto,
        'rating': rating,
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error guardando reseña: $e');
      throw Exception('Error al guardar la reseña: $e');
    }
  }
  
  // ===== Nuevos métodos para Firestore =====

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

  // Obtener reseñas para un medio específico (película, libro, etc.)
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

    // Asegurarse de que tengamos todos los campos necesarios
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

    // También guardar en Realtime Database para mantener compatibilidad
    try {
      await _rtdb.child(completeData['mediaId'].toString()).child(currentUser!.uid).set({
        'texto': completeData['content'],
        'rating': completeData['rating'],
        'timestamp': ServerValue.timestamp,
      });
    } catch (e) {
      print('Error guardando en RTDB: $e');
      // Continuamos incluso si falla RTDB, priorizando Firestore
    }

    // Guardar en Firestore y retornar la referencia del documento
    return await _reviewsCollection.add(completeData);
  }

  // Actualizar una reseña existente
  Future<void> updateReview(String reviewId, Map<String, dynamic> reviewData) async {
    if (currentUser == null) {
      throw Exception('Usuario no autenticado');
    }

    // Construir datos de actualización
    final Map<String, dynamic> updateData = {
      'updatedAt': FieldValue.serverTimestamp(),
    };

    // Copiar solo los campos proporcionados
    if (reviewData.containsKey('title')) updateData['title'] = reviewData['title'];
    if (reviewData.containsKey('content')) updateData['content'] = reviewData['content'];
    if (reviewData.containsKey('rating')) updateData['rating'] = reviewData['rating'];
    if (reviewData.containsKey('genre')) updateData['genre'] = reviewData['genre'];

    // Actualizar en Firestore
    await _reviewsCollection.doc(reviewId).update(updateData);
    
    // Intentar actualizar también en RTDB si tenemos la mediaId
    try {
      // Obtener el documento actual para saber la mediaId
      final docSnap = await _reviewsCollection.doc(reviewId).get();
      if (docSnap.exists) {
        final data = docSnap.data() as Map<String, dynamic>;
        final mediaId = data['mediaId']?.toString();
        
        if (mediaId != null && mediaId.isNotEmpty) {
          final rtdbUpdateData = <String, dynamic>{};
          
          if (reviewData.containsKey('content')) {
            rtdbUpdateData['texto'] = reviewData['content'];
          }
          if (reviewData.containsKey('rating')) {
            rtdbUpdateData['rating'] = reviewData['rating'];
          }
            
          if (rtdbUpdateData.isNotEmpty) {
            rtdbUpdateData['timestamp'] = ServerValue.timestamp;
            await _rtdb.child(mediaId).child(currentUser!.uid).update(rtdbUpdateData);
          }
        }
      }
    } catch (e) {
      print('Error actualizando en RTDB: $e');
      // Continuamos incluso si falla RTDB
    }
  }

  // Eliminar una reseña
  Future<void> deleteReview(String reviewId) async {
    if (currentUser == null) {
      throw Exception('Usuario no autenticado');
    }
    
    try {
      // Primero obtener el documento para conocer mediaId
      final doc = await _reviewsCollection.doc(reviewId).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final mediaId = data['mediaId']?.toString();
        final userId = data['userId'];
        
        // Verificar que la reseña pertenezca al usuario actual
        if (userId == currentUser!.uid) {
          // Eliminar de Firestore primero
          await _reviewsCollection.doc(reviewId).delete();
          
          // Después intentar eliminar de RTDB con manejo de error específico
          if (mediaId != null && mediaId.isNotEmpty) {
            try {
              // Verificar si el nodo existe antes de intentar eliminarlo
              DataSnapshot snapshot = await _rtdb.child(mediaId).child(currentUser!.uid).get();
              if (snapshot.exists) {
                await _rtdb.child(mediaId).child(currentUser!.uid).remove();
              }
            } catch (rtdbError) {
              // Capturar y registrar el error pero no propagarlo
              print('Error al eliminar de RTDB (no crítico): $rtdbError');
              // No lanzamos excepción aquí, ya que la eliminación en Firestore fue exitosa
            }
          }
        } else {
          throw Exception('No tienes permiso para eliminar esta reseña');
        }
      } else {
        throw Exception('La reseña no existe');
      }
    } catch (e) {
      print('Error eliminando reseña: $e');
      throw Exception('Error al eliminar la reseña: $e');
    }
  }
}