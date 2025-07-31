import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parqueadero/controllers/espacios_controller.dart';
import 'package:parqueadero/models/espacio_model.dart';
import 'package:parqueadero/models/periodo_model.dart';
import '../models/reservacion_model.dart';

class ReservacionController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final String _col = 'reservaciones';
  final FirebaseAuth _auth = FirebaseAuth.instance; // Instancia de FirebaseAuth
  final String _colReservaciones = 'reservaciones';
  final String _colEspacios = 'espacios';
  final String _colPeriodos = 'periodos';
  final EspacioController _espacioController = EspacioController();

  /// Crea una nueva reservación (ID autogenerado)
  Future<void> crearReservacion(Reservacion r) {
    return _db
        .collection(_col)
        .doc() // Firestore genera el ID
        .set(r.toMap());
  }

  /// Obtiene un stream de todas las reservaciones en tiempo real para el usuario logeado
  Stream<List<Reservacion>> getReservacionesStream() {
    // Obtener el usuario autenticado
    User? user = _auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado.');
    }

    // Filtrar las reservaciones para el usuario logeado
    return _db
        .collection(_col)
        .where('usuario',
            isEqualTo: _db
                .collection('usuarios')
                .doc(user.uid)) // Filtrar por usuarioRef
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => Reservacion.fromSnapshot(
                doc)) // Convertir los documentos a objetos Reservacion
            .toList());
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
      ).toUtc(); // Convertir a UTC

      final fechaFinConHora = DateTime(
        diaActual.year,
        diaActual.month,
        diaActual.day,
        r.fechaFin.hour,
        r.fechaFin.minute,
      ).toUtc(); // Convertir a UTC

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

  // Obtiene la información del espacio y periodo relacionados con una reservación
  Future<Map<String, dynamic>> obtenerEspacioYPeriodoDeReservacion(
      String reservacionId) async {
    try {
      // Obtener el usuario autenticado
      User? user = _auth.currentUser;
      if (user == null) {
        throw Exception('No hay usuario autenticado.');
      }

      // Obtener la reservación
      DocumentSnapshot reservacionSnapshot =
          await _db.collection(_colReservaciones).doc(reservacionId).get();
      if (!reservacionSnapshot.exists) {
        throw Exception('La reservación no existe.');
      }

      // Convertir el documento de la reservación en un objeto Reservacion
      Reservacion reservacion = Reservacion.fromSnapshot(reservacionSnapshot);

      // Verificar si el usuario autenticado coincide con el usuario de la reservación
      if (reservacion.usuarioRef.id != user.uid) {
        throw Exception('El usuario no tiene acceso a esta reservación.');
      }

      // Obtener el espacio utilizando la referencia del espacio en la reservación
      DocumentSnapshot espacioSnapshot = await reservacion.espacioRef.get();
      if (!espacioSnapshot.exists) {
        throw Exception('El espacio relacionado no existe.');
      }

      // Convertir el documento del espacio en un objeto Espacio
      Espacio espacio = Espacio.fromMap(
          espacioSnapshot.data() as Map<String, dynamic>, espacioSnapshot.id);

      // Obtener el periodo utilizando la referencia del periodo en la reservación
      DocumentSnapshot periodoSnapshot = await reservacion.periodoRef.get();
      if (!periodoSnapshot.exists) {
        throw Exception('El periodo relacionado no existe.');
      }

      // Convertir el documento del periodo en un objeto Periodo
      Periodo periodo =
          Periodo.fromFirestore(periodoSnapshot.data() as Map<String, dynamic>);

      // Retornar un mapa con la información del espacio y el periodo
      return {
        'espacio': espacio,
        'periodo': periodo,
      };
    } catch (e) {
      // Manejo de errores
      print('Error al obtener la información: $e');
      throw Exception('Error al obtener la información del espacio y periodo.');
    }
  }

  /// Cancela una reserva (solo el día indicado) y gestiona la disponibilidad del espacio:
  /// - Si es reserva de un solo día, la marca “cancelado” y deja el espacio libre.
  /// - Si es multi-día, ajusta/divide la reserva para quitar solo ese día, marca el espacio libre
  ///   y programa (en el cliente) una re-ocupación al día siguiente si hay tramos posteriores.
  Future<void> cancelarReservacionYActualizarEspacio(String reservaId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado.');
    }

    // 1) Transacción: cancelar el día y liberar espacio hoy
    late final DateTime diaCancelar;
    late final DocumentReference espacioRef;
    await _db.runTransaction((tx) async {
      final reservRef = _db.collection(_colReservaciones).doc(reservaId);
      final snap = await tx.get(reservRef);
      if (!snap.exists) throw Exception('La reservación no existe.');
      final reserv = Reservacion.fromSnapshot(snap);

      if (reserv.usuarioRef.id != user.uid) {
        throw Exception('No tienes permiso sobre esta reservación.');
      }

      diaCancelar = DateTime(
        reserv.fechaInicio.year,
        reserv.fechaInicio.month,
        reserv.fechaInicio.day,
      );
      final hoy = DateTime.now();
      final hoySoloFecha = DateTime(hoy.year, hoy.month, hoy.day);
      if (hoySoloFecha.isAfter(diaCancelar)) {
        throw Exception('No puedes cancelar: la fecha de la reserva ya pasó.');
      }

      // Determinar si es sola un día
      final esUnDia = reserv.fechaInicio.isAtSameMomentAs(reserv.fechaFin) &&
          reserv.fechaInicio.isAtSameMomentAs(diaCancelar);

      if (esUnDia) {
        tx.update(reservRef, {'estado': 'cancelado'});
      } else {
        // Multi-día: ajustar o dividir
        final inicioOriginal = DateTime(
          reserv.fechaInicio.year,
          reserv.fechaInicio.month,
          reserv.fechaInicio.day,
        );
        final finOriginal = DateTime(
          reserv.fechaFin.year,
          reserv.fechaFin.month,
          reserv.fechaFin.day,
        );

        if (diaCancelar.isAtSameMomentAs(inicioOriginal)) {
          // Primer día: desplazar inicio +1
          tx.update(reservRef, {
            'fechaInicio':
                Timestamp.fromDate(diaCancelar.add(Duration(days: 1)))
          });
        } else if (diaCancelar.isAtSameMomentAs(finOriginal)) {
          // Último día: acortar fin -1
          tx.update(reservRef, {
            'fechaFin':
                Timestamp.fromDate(diaCancelar.subtract(Duration(days: 1)))
          });
        } else {
          // Día intermedio: dividimos en dos
          tx.update(reservRef, {
            'fechaFin':
                Timestamp.fromDate(diaCancelar.subtract(Duration(days: 1)))
          });
          final nuevoRef = _db.collection(_colReservaciones).doc();
          final nueva = Reservacion(
            id: nuevoRef.id,
            usuarioRef: reserv.usuarioRef,
            espacioRef: reserv.espacioRef,
            periodoRef: reserv.periodoRef,
            fechaInicio: diaCancelar.add(Duration(days: 1)),
            fechaFin: reserv.fechaFin,
            horaInicio: reserv.horaInicio,
            horaFin: reserv.horaFin,
            estado: reserv.estado,
          );
          tx.set(nuevoRef, nueva.toMap());
        }
      }

      // Liberar el espacio **hoy**
      espacioRef = _db.collection(_colEspacios).doc(reserv.espacioRef.id);
      tx.update(espacioRef, {'disponible': true});
    });
  }
}
