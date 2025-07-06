import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';

class AuthController {
  final _auth = FirebaseAuth.instance;
  final _colUsuarios = FirebaseFirestore.instance.collection('usuarios');

  // Stream que emite cambios de estado de sesión
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Registro: crea credenciales y luego documento en Firestore
  Future<String?> register({
    required String email,
    required String password,
    required Usuario perfil,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      // usa el UID generado como id de tu perfil
      final uid = cred.user!.uid;
      // construye el perfil con el uid y escribe en Firestore
      final perfilConId = perfil.copyWith(id: uid);
      await _colUsuarios.doc(uid).set(perfilConId.toMap());
      await _colUsuarios
          .doc(uid)
          .set(perfil.copyWith(id: uid).toMap()); // toMap de tu modelo
      return null; // éxito
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // Login con email/password
  Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return null;
    } on FirebaseAuthException catch (e) {
      return e.message;
    }
  }

  // Logout
  Future<void> logout() => _auth.signOut();

  // Obtener perfil completo del usuario logueado
  Future<Usuario?> getCurrentUsuario() async {
    final user = _auth.currentUser;
    if (user == null) return null;
    final snap = await _colUsuarios.doc(user.uid).get();
    if (!snap.exists) return null;
    return Usuario.fromMap(snap.id, snap.data()!);
  }
}
