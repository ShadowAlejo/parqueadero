import 'package:cloud_firestore/cloud_firestore.dart';

class Vehiculo {
  final String id;
  final String color;
  final String marca;
  final String modelo;
  final String urlImagen;
  final DocumentReference<Map<String, dynamic>> usuarioRef;

  Vehiculo({
    required this.id,
    required this.color,
    required this.marca,
    required this.modelo,
    required this.urlImagen,
    required this.usuarioRef,
  });

  // ← Fíjate en el cambio: DocumentSnapshot<Map<String, dynamic>>
  factory Vehiculo.fromSnapshot(DocumentSnapshot<Map<String, dynamic>> snap) {
    final data = snap.data()!;
    return Vehiculo(
      id: snap.id,
      color: data['color'] ?? '',
      marca: data['marca'] ?? '',
      modelo: data['modelo'] ?? '',
      urlImagen: data['urlImagen'] ?? '',
      usuarioRef: data['usuarioRef'] as DocumentReference<Map<String, dynamic>>,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'color': color,
      'marca': marca,
      'modelo': modelo,
      'urlImagen': urlImagen,
      'usuarioRef': usuarioRef,
    };
  }
}
