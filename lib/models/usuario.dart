// lib/models/usuario.dart

import 'package:flutter/foundation.dart';

/// Representa el perfil de un usuario en Firestore
class Usuario {
  final String id;
  final String nombre;
  final String email;
  final String telefono;
  final String rol;

  Usuario({
    required this.id,
    required this.nombre,
    required this.email,
    required this.telefono,
    required this.rol,
  });

  /// Convierte el objeto a un Map para subirlo a Firestore
  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'email': email,
      'telefono': telefono,
      'rol': rol,
    };
  }

  /// Reconstruye un Usuario a partir de un documento de Firestore
  factory Usuario.fromMap(String id, Map<String, dynamic> map) {
    return Usuario(
      id: id,
      nombre: map['nombre'] as String? ?? '',
      email: map['email'] as String? ?? '',
      telefono: map['telefono'] as String? ?? '',
      rol: map['rol'] as String? ?? '',
    );
  }

  /// Permite crear una copia modificando sólo algunos campos
  Usuario copyWith({
    String? id,
    String? nombre,
    String? email,
    String? telefono,
    String? rol,
  }) {
    return Usuario(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      telefono: telefono ?? this.telefono,
      rol: rol ?? this.rol,
    );
  }
}
