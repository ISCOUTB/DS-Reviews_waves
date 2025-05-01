import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  CollectionReference get _usersCollection => _firestore.collection('users');
  
  User? get currentUser => _auth.currentUser;
  
  // Crear o actualizar perfil de usuario
  Future<void> updateUserProfile({
    String? displayName,
    String? bio,
    String? photoURL,
  }) async {
    if (currentUser == null) {
      throw Exception('Usuario no autenticado');
    }
    
    final userDoc = _usersCollection.doc(currentUser!.uid);
    
    // Verificar si el perfil ya existe
    final docSnapshot = await userDoc.get();
    
    if (docSnapshot.exists) {
      // Actualizar perfil existente
      Map<String, dynamic> updateData = {
        'lastUpdated': FieldValue.serverTimestamp(),
      };
      
      if (displayName != null) updateData['displayName'] = displayName;
      if (bio != null) updateData['bio'] = bio;
      if (photoURL != null) updateData['photoURL'] = photoURL;
      
      await userDoc.update(updateData);
    } else {
      // Crear nuevo perfil
      await userDoc.set({
        'userId': currentUser!.uid,
        'email': currentUser!.email,
        'displayName': displayName ?? currentUser!.displayName ?? 'Usuario',
        'photoURL': photoURL ?? currentUser!.photoURL ?? '',
        'bio': bio ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    }
  }
  
  // Obtener perfil de usuario
  Stream<DocumentSnapshot> getUserProfile(String userId) {
    return _usersCollection.doc(userId).snapshots();
  }
  
  // Obtener perfil del usuario actual
  Stream<DocumentSnapshot> getCurrentUserProfile() {
    if (currentUser == null) {
      throw Exception('Usuario no autenticado');
    }
    
    return _usersCollection.doc(currentUser!.uid).snapshots();
  }
  
  // Guardar perfil al iniciar sesión
  Future<void> saveUserOnLogin() async {
    if (currentUser == null) return;
    
    final userDoc = _usersCollection.doc(currentUser!.uid);
    final docSnapshot = await userDoc.get();
    
    if (!docSnapshot.exists) {
      // Perfil no existe, crearlo
      await userDoc.set({
        'userId': currentUser!.uid,
        'email': currentUser!.email,
        'displayName': currentUser!.displayName ?? 'Usuario',
        'photoURL': currentUser!.photoURL ?? '',
        'bio': '',
        'createdAt': FieldValue.serverTimestamp(),
        'lastUpdated': FieldValue.serverTimestamp(),
        'reviewCount': 0,
        'favoriteCount': 0
      });
    } else {
      // El perfil ya existe, sólo actualizar la última fecha de login
      await userDoc.update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    }
  }
}