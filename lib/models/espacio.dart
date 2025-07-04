import 'package:cloud_firestore/cloud_firestore.dart';

class Espacio {
  final String id; // id del documento en Firestore
  final bool disponible;
  final int numero;
  final String seccion;

  Espacio({
    required this.id,
    required this.disponible,
    required this.numero,
    required this.seccion,
  });

  /// Construye un objeto Espacio a partir de un DocumentSnapshot de Firestore
  factory Espacio.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Espacio(
      id: doc.id,
      disponible: data['disponible'] as bool,
      numero: data['numero'] as int,
      seccion: data['seccion'] as String,
    );
  }

  /// Convierte el Espacio a un Map para subirlo/actualizarlo en Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'disponible': disponible,
      'numero': numero,
      'seccion': seccion,
    };
  }
}
