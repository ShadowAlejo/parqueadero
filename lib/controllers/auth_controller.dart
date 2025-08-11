import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/usuario.dart';

class AuthController {
  final _auth = FirebaseAuth.instance;
  final _colUsuarios = FirebaseFirestore.instance.collection('usuarios');
  final FirebaseFirestore _db = FirebaseFirestore.instance;

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

  // Obtener rol del usuario logueado
  Future<String?> getUsuarioRol() async {
    final usuario = await getCurrentUsuario();
    if (usuario != null) {
      return usuario.rol; // Devuelve el rol del usuario
    }
    return null; // Si no se encuentra al usuario, retorna null
  }

  // Verificar si el usuario es administrador
  Future<bool> isAdmin() async {
    final rol = await getUsuarioRol();
    if (rol != null && rol == 'admin') {
      return true; // El usuario es administrador
    }
    return false; // El usuario no es administrador
  }

  // Verificar si el usuario es regular
  Future<bool> isRegularUser() async {
    final rol = await getUsuarioRol();
    if (rol != null && rol == 'usuario') {
      return true; // El usuario es regular
    }
    return false; // El usuario no es regular
  }

  /// Devuelve el UID del usuario actualmente autenticado,
  /// o `null` si no hay sesión iniciada.
  String? get currentUserId => _auth.currentUser?.uid;
  Future<int> obtenerNumeroDeUsuarios() async {
    try {
      // Obtiene la colección de usuarios
      final usuariosSnapshot = await _db.collection('usuarios').get();

      // Retorna el número de documentos (usuarios) en la colección
      return usuariosSnapshot.size;
    } catch (e) {
      // Si ocurre un error, imprime el mensaje y retorna 0
      print('Error al obtener el número de usuarios: $e');
      return 0;
    }
  }
}
