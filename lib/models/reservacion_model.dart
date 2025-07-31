import 'package:cloud_firestore/cloud_firestore.dart';

class Reservacion {
  final String id;
  final DocumentReference usuarioRef;
  final DocumentReference espacioRef;
  final DocumentReference periodoRef;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final String horaInicio; // "HH:mm"
  final String horaFin; // "HH:mm"
  final String estado; // pendiente, confirmado, disponible, finalizado

  Reservacion({
    required this.id,
    required this.usuarioRef,
    required this.espacioRef,
    required this.periodoRef,
    required this.fechaInicio,
    required this.fechaFin,
    this.horaInicio = '',
    this.horaFin = '',
    this.estado = '',
  });

  /// Convierte un DocumentSnapshot de Firestore en un objeto Reservacion
  factory Reservacion.fromSnapshot(DocumentSnapshot snap) {
    final data = snap.data() as Map<String, dynamic>;
    return Reservacion(
      id: snap.id,
      usuarioRef: data['usuario'] as DocumentReference,
      espacioRef: data['espacio'] as DocumentReference,
      periodoRef: data['periodo'] as DocumentReference,
      fechaInicio: (data['fechaInicio'] as Timestamp).toDate(),
      fechaFin: (data['fechaFin'] as Timestamp).toDate(),
      horaInicio: data['horaInicio'] as String? ?? '',
      horaFin: data['horaFin'] as String? ?? '',
      estado: data['estado'] as String? ?? '',
    );
  }

  /// Prepara un Map para guardar o actualizar en Firestore
  Map<String, dynamic> toMap() {
    return {
      'usuario': usuarioRef,
      'espacio': espacioRef,
      'periodo': periodoRef,
      'fechaInicio': Timestamp.fromDate(fechaInicio),
      'fechaFin': Timestamp.fromDate(fechaFin),
      'horaInicio': horaInicio,
      'horaFin': horaFin,
      'estado': estado,
    };
  }
}
