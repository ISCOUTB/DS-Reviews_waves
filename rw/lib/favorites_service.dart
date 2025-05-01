import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Colección de favoritos
  CollectionReference get _favoritesCollection => _firestore.collection('favorites');
  
  // Usuario actual
  User? get currentUser => _auth.currentUser;
  
  // Añadir a favoritos
  Future<void> addToFavorites(String mediaId, String mediaType, String title, String posterPath) async {
    if (currentUser == null) {
      throw Exception('Usuario no autenticado');
    }
    
    await _favoritesCollection.doc('${currentUser!.uid}_$mediaId').set({
      'userId': currentUser!.uid,
      'mediaId': mediaId,
      'mediaType': mediaType, // 'movie' o 'tv'
      'title': title,
      'posterPath': posterPath,
      'addedAt': FieldValue.serverTimestamp(),
    });
  }
  
  // Eliminar de favoritos
  Future<void> removeFromFavorites(String mediaId) async {
    if (currentUser == null) {
      throw Exception('Usuario no autenticado');
    }
    
    await _favoritesCollection.doc('${currentUser!.uid}_$mediaId').delete();
  }
  
  // Verificar si un ítem está en favoritos
  Future<bool> isFavorite(String mediaId) async {
    if (currentUser == null) return false;
    
    final docSnap = await _favoritesCollection.doc('${currentUser!.uid}_$mediaId').get();
    return docSnap.exists;
  }
  
  // Obtener todos los favoritos del usuario
  Stream<QuerySnapshot> getUserFavorites() {
    if (currentUser == null) {
      throw Exception('Usuario no autenticado');
    }
    
    return _favoritesCollection
        .where('userId', isEqualTo: currentUser!.uid)
        .orderBy('addedAt', descending: true)
        .snapshots();
  }
}