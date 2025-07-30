import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/reservacion_model.dart';

class ReservacionController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _col = 'reservaciones';

  /// Crea una nueva reservación (ID autogenerado)
  Future<void> crearReservacion(Reservacion r) {
    return _db
        .collection(_col)
        .doc() // Firestore genera el ID
        .set(r.toMap());
  }

  /// Obtiene un stream de todas las reservaciones en tiempo real
  Stream<List<Reservacion>> getReservacionesStream() {
    return _db.collection(_col).snapshots().map((snap) =>
        snap.docs.map((doc) => Reservacion.fromSnapshot(doc)).toList());
  }

  /// Actualiza el estado de una reservación (por ejemplo "pendiente", "confirmado", "cancelado")
  Future<void> actualizarEstado(String reservaId, String nuevoEstado) {
    return _db.collection(_col).doc(reservaId).update({'estado': nuevoEstado});
  }

  /// Elimina una reservación por ID
  Future<void> eliminarReservacion(String reservaId) {
    return _db.collection(_col).doc(reservaId).delete();
  }

  /// Obtiene solo las reservaciones de un estado concreto
  Stream<List<Reservacion>> getReservacionesPorEstado(String estado) {
    return _db
        .collection(_col)
        .where('estado', isEqualTo: estado)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Reservacion.fromSnapshot(doc)).toList());
  }

  /// (Opcional) Filtrar reservaciones por usuario
  Stream<List<Reservacion>> getReservacionesPorUsuario(
      DocumentReference usuarioRef) {
    return _db
        .collection(_col)
        .where('usuario', isEqualTo: usuarioRef)
        .snapshots()
        .map((snap) =>
            snap.docs.map((doc) => Reservacion.fromSnapshot(doc)).toList());
  }

  /// Crea tantas reservaciones como días haya entre fechaInicio y fechaFin (ambos incluidos)
  Future<void> crearReservacionesPorRango(Reservacion r) async {
    final inicio =
        DateTime(r.fechaInicio.year, r.fechaInicio.month, r.fechaInicio.day);
    final fin = DateTime(r.fechaFin.year, r.fechaFin.month, r.fechaFin.day);

    final totalDias = fin.difference(inicio).inDays + 1;
    if (totalDias <= 0) {
      throw Exception(
          'La fecha fin debe ser igual o posterior a la fecha inicio.');
    }

    final batch = _db.batch();

    for (int i = 0; i < totalDias; i++) {
      final diaActual = inicio.add(Duration(days: i));
      final fechaIniConHora = DateTime(
        diaActual.year,
        diaActual.month,
        diaActual.day,
        r.fechaInicio.hour,
        r.fechaInicio.minute,
      );
      final fechaFinConHora = DateTime(
        diaActual.year,
        diaActual.month,
        diaActual.day,
        r.fechaFin.hour,
        r.fechaFin.minute,
      );

      final rDia = Reservacion(
        id: '',
        usuarioRef: r.usuarioRef,
        espacioRef: r.espacioRef,
        periodoRef: r.periodoRef,
        fechaInicio: fechaIniConHora,
        fechaFin: fechaFinConHora,
        horaInicio: r.horaInicio,
        horaFin: r.horaFin,
        estado: r.estado,
      );

      // Agregar la reservación al batch
      batch.set(_db.collection(_col).doc(), rDia.toMap());

      // Agregar la actualización del espacio al batch
      batch.update(_db.collection('espacios').doc(r.espacioRef.id), {
        'disponible': false,
      });
    }

    await batch.commit();
  }
}
