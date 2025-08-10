import 'package:cloud_firestore/cloud_firestore.dart';

class Vehiculo {
  final String id;
  final String color;
  final String marca;
  final String modelo;
  final String urlImagen;
  final DocumentReference
      usuarioRef; // Aquí almacenamos la referencia al documento de usuario

  Vehiculo({
    required this.id,
    required this.color,
    required this.marca,
    required this.modelo,
    required this.urlImagen,
    required this.usuarioRef,
  });

  // Método para convertir un documento de Firestore en un objeto Vehiculo
  factory Vehiculo.fromMap(Map<String, dynamic> data, String documentId) {
    return Vehiculo(
      id: documentId,
      color: data['color'] ?? '',
      marca: data['marca'] ?? '',
      modelo: data['modelo'] ?? '',
      urlImagen: data['urlImagen'] ?? '',
      usuarioRef: data[
          'usuarioRef'], // La referencia al usuario debe ser de tipo DocumentReference
    );
  }

  get tipo => null;

  // Método para convertir un objeto Vehiculo en un mapa para Firestore
  Map<String, dynamic> toMap() {
    return {
      'color': color,
      'marca': marca,
      'modelo': modelo,
      'urlImagen': urlImagen,
      'usuarioRef': usuarioRef, // Guardamos la referencia al usuario
    };
  }
}
