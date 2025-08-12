import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:parqueadero/controllers/espacios_controller.dart';
import 'package:parqueadero/models/espacio_model.dart';
import 'package:parqueadero/models/periodo_model.dart';
import '../models/reservacion_model.dart';
import 'periodo_controller.dart';

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

    // Retry mechanism with exponential backoff
    int attempts = 0;
    const maxAttempts = 3;

    for (int i = 0; i < totalDias; i++) {
      // 1. Espera 1 segundo antes de cada creación (retraso controlado)
      await Future.delayed(Duration(seconds: 1));

      // 2. Calcula fechaInicio/fechaFin para el día i
      final diaActual = inicio.add(Duration(days: i));
      final fechaIniConHora = DateTime(
        diaActual.year,
        diaActual.month,
        diaActual.day,
        r.fechaInicio.hour,
        r.fechaInicio.minute,
      ).toUtc();
      final fechaFinConHora = DateTime(
        diaActual.year,
        diaActual.month,
        diaActual.day,
        r.fechaFin.hour,
        r.fechaFin.minute,
      ).toUtc();

      // 3. Prepara la reservación del día
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

      // Intento de escribir en Firestore con reintentos
      while (attempts < maxAttempts) {
        try {
          // 4. Inserta la reservación (operación de escritura)
          final docRef = _db.collection(_col).doc();
          await docRef.set(rDia.toMap());

          // 5. Usa una transacción para actualizar la disponibilidad del espacio
          await _db.runTransaction((transaction) async {
            final espacioRef = _db.collection('espacios').doc(r.espacioRef.id);
            final espacioDoc = await transaction.get(espacioRef);

            if (!espacioDoc.exists) {
              throw Exception('El espacio no existe.');
            }

            // Verificar si el espacio está disponible antes de actualizarlo
            transaction.update(espacioRef, {'disponible': false});
          });

          break; // Salir del ciclo de reintento si todo fue exitoso
        } catch (e) {
          attempts++;
          print("Error al procesar el día ${i + 1}: $e");

          if (attempts >= maxAttempts) {
            throw Exception("Error tras $maxAttempts intentos: $e");
          }

          // Exponential backoff para reintentos
          await Future.delayed(Duration(seconds: 2 ^ attempts));
        }
      }
    }
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

  /// Cancela solo el tramo correspondiente al día actual de una reservación
  /// y libera el espacio para ese día (marca disponible = true).
  Future<void> cancelarReservacionYActualizarEspacio(String reservaId) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado.');
    }

    await _db.runTransaction((tx) async {
      final reservRef = _db.collection(_colReservaciones).doc(reservaId);
      final snap = await tx.get(reservRef);
      if (!snap.exists) {
        throw Exception('La reservación no existe.');
      }

      final reserv = Reservacion.fromSnapshot(snap);

      if (reserv.usuarioRef.id != user.uid) {
        throw Exception('No tienes permiso sobre esta reservación.');
      }

      // Fecha de hoy (solo Y/M/D)
      final ahora = DateTime.now();
      final hoy = DateTime(ahora.year, ahora.month, ahora.day);

      // Periodo original (solo Y/M/D)
      final inicio = DateTime(
        reserv.fechaInicio.year,
        reserv.fechaInicio.month,
        reserv.fechaInicio.day,
      );
      final fin = DateTime(
        reserv.fechaFin.year,
        reserv.fechaFin.month,
        reserv.fechaFin.day,
      );

      // Verificar que hoy esté dentro de la reserva
      if (hoy.isBefore(inicio)) {
        // Caso para reservaciones futuras: solo se cancelan si son posteriores a hoy
        tx.update(reservRef, {'estado': 'cancelado'});
        // Liberar el espacio para los días posteriores
        final espacioRef =
            _db.collection(_colEspacios).doc(reserv.espacioRef.id);
        tx.update(espacioRef, {'disponible': true});
      } else if (hoy.isBefore(fin) || hoy.isAtSameMomentAs(fin)) {
        // Caso para reservas que están activas hoy
        // Caso 1: reserva de un solo día (hoy es inicio y fin)
        final esUnDia = inicio.isAtSameMomentAs(fin);
        if (esUnDia) {
          // Marcamos la reserva completa como cancelada
          tx.update(reservRef, {'estado': 'cancelado'});
        } else {
          // Multi-día: solo ajustamos el rango para quitar hoy
          if (hoy.isAtSameMomentAs(inicio)) {
            // Hoy es primer día: desplazamos fechaInicio +1
            final nuevoInicio = hoy.add(Duration(days: 1));
            tx.update(reservRef, {
              'fechaInicio': Timestamp.fromDate(nuevoInicio),
            });
          } else {
            // Hoy es último o día intermedio: acortamos fechaFin a ayer
            final finAnterior = hoy.subtract(Duration(days: 1));
            tx.update(reservRef, {
              'fechaFin': Timestamp.fromDate(finAnterior),
            });
          }
        }

        // Liberar el espacio para hoy
        final espacioRef =
            _db.collection(_colEspacios).doc(reserv.espacioRef.id);
        tx.update(espacioRef, {'disponible': true});
      } else {
        throw Exception('La reservación ya ha finalizado.');
      }
    });
  }

  /// Recupera todas las reservaciones del usuario logeado
  /// que estén dentro del periodo activo.
  Future<List<Reservacion>> obtenerReservacionesUsuarioPeriodoActivo() async {
    // 1) Verificar usuario autenticado
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado.');
    }

    // 2) Obtener el ID del periodo activo
    final periodoCtrl = PeriodoController();
    final idPeriodoActivo = await periodoCtrl.obtenerIdPeriodoActivo();
    if (idPeriodoActivo == null) {
      // Si no hay periodo activo, devolvemos lista vacía
      return [];
    }
    final periodoRef = _db.collection('periodo').doc(idPeriodoActivo);

    // 3) Preparar la referencia al documento de usuario
    final usuarioRef = _db.collection('usuarios').doc(user.uid);

    // 4) Hacer la consulta con dos filtros de igualdad
    final querySnap = await _db
        .collection('reservaciones')
        .where('usuario', isEqualTo: usuarioRef)
        .where('periodo', isEqualTo: periodoRef)
        .get();

    // 5) Mapear cada documento a Reservacion y devolver la lista
    return querySnap.docs.map((doc) => Reservacion.fromSnapshot(doc)).toList();
  }

  /// Cuenta las reservaciones **pendientes** y **confirmadas** del usuario logeado
  /// que estén dentro del periodo activo.
  /// Devuelve un Map con las claves:
  Future<Map<String, int>> contarReservasPendientesYConfirmadas() async {
    // 1) Usuario autenticado
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('No hay usuario autenticado.');
    }

    // 2) Obtener el ID del periodo activo
    final periodoCtrl = PeriodoController();
    final idPeriodoActivo = await periodoCtrl.obtenerIdPeriodoActivo();
    if (idPeriodoActivo == null) {
      // Sin periodo activo, no hay reservas que contar
      return {
        'pendientes': 0,
        'confirmadas': 0,
      };
    }

    // Referencias comunes
    final periodoRef = _db.collection('periodo').doc(idPeriodoActivo);
    final usuarioRef = _db.collection('usuarios').doc(user.uid);

    // 3) Consulta para pendientes
    final snapPendientes = await _db
        .collection('reservaciones')
        .where('usuario', isEqualTo: usuarioRef)
        .where('periodo', isEqualTo: periodoRef)
        .where('estado', isEqualTo: 'pendiente')
        .get();

    // 4) Consulta para confirmadas
    final snapConfirmadas = await _db
        .collection('reservaciones')
        .where('usuario', isEqualTo: usuarioRef)
        .where('periodo', isEqualTo: periodoRef)
        .where('estado', isEqualTo: 'confirmado')
        .get();

    return {
      'pendientes': snapPendientes.size,
      'confirmadas': snapConfirmadas.size,
    };
  }

  /// Verifica si existen reservaciones en días posteriores al actual
  /// para el espacio cuyo ID es [idEspacio].
  /// Devuelve `true` si hay al menos una reserva cuyo
  /// campo `fechaInicio` sea ≥ mañana (en la zona UTC de tu servidor),
  /// y `false` en caso contrario.
  Future<bool> hayReservasFuturasParaEspacio(String idEspacio) async {
    // 1) Verificar si hay un periodo activo
    final periodoRef = FirebaseFirestore.instance
        .collection('periodos')
        .where('activo', isEqualTo: true)
        .limit(1);
    final periodoSnap = await periodoRef.get();

    // Si no hay periodo activo, no realizamos ninguna operación
    if (periodoSnap.docs.isEmpty) {
      return false; // No hay periodo activo
    }

    // 2) Referencia al espacio
    final espacioRef =
        FirebaseFirestore.instance.collection('espacios').doc(idEspacio);

    // 3) Calcular mañana (solo fecha, sin hora)
    final hoy = DateTime.now();
    final inicioDeManana =
        DateTime(hoy.year, hoy.month, hoy.day).add(const Duration(days: 1));

    // 4) Query: solo filtramos por 'espacio' (índice simple)
    final snap = await FirebaseFirestore.instance
        .collection('reservaciones')
        .where('espacio', isEqualTo: espacioRef) // solo filtro por espacio
        .get();

    // 5) Filtrado en cliente: buscar la primera reserva con fecha >= inicioDeManana
    for (var doc in snap.docs) {
      final fechaInicio = (doc.get('fechaInicio') as Timestamp).toDate();
      if (fechaInicio.isAfter(inicioDeManana) ||
          fechaInicio.isAtSameMomentAs(inicioDeManana)) {
        return true; // Hay una reserva futura
      }
    }

    return false; // No hay reservas futuras
  }

  /// Retorna el número de reservaciones existentes en un periodo específico.
  /// Usa aggregate `count()` (si está disponible) y, si falla, hace un get() normal.
  /// `periodo` es una instancia completa de tu modelo (p.ej. _selectedPeriodo).
  Future<int> contarReservacionesDePeriodo(Periodo? periodo) async {
    if (periodo == null || periodo.idPeriodo.isEmpty) return 0;

    // Ajusta el nombre de la colección si en tu proyecto es 'periodo' en singular.
    final periodoRef = _db.collection('periodo').doc(periodo.idPeriodo);

    final col =
        _db.collection('reservaciones').where('periodo', isEqualTo: periodoRef);

    // 1) Intento eficiente con aggregate count()
    try {
      final agg = await col.count().get();
      return agg.count ?? 0; // <- aquí
    } catch (_) {
      final snap = await col.get();
      return snap.size;
    }
  }

  Future<Map<String, int>> obtenerNumeroDeReservacionesPorEstado(
      Periodo? periodo) async {
    // Estados soportados
    const estados = ['pendiente', 'confirmado', 'cancelado', 'finalizado'];

    // Mapa base con ceros
    final conteo = {for (final e in estados) e: 0};

    // Validaciones básicas
    if (periodo == null || periodo.idPeriodo.isEmpty) return conteo;

    // Referencia al periodo (ajusta el nombre si tu colección es 'periodo' en singular)
    final periodoRef = _db.collection('periodo').doc(periodo.idPeriodo);

    // Consulta base a 'reservaciones' filtrando por el periodo (ajusta si tu colección se llama distinto)
    final base =
        _db.collection('reservaciones').where('periodo', isEqualTo: periodoRef);

    // 1) Intento eficiente con aggregate count() por cada estado
    try {
      final futures = estados
          .map(
              (estado) => base.where('estado', isEqualTo: estado).count().get())
          .toList();

      final snaps = await Future.wait(futures);
      for (int i = 0; i < estados.length; i++) {
        final c = snaps[i].count; // en plugins recientes es int no-nulo
        conteo[estados[i]] = (c is int) ? c : (c ?? 0);
      }
      return conteo;
    } catch (_) {
      // 2) Fallback: leer documentos y contar en memoria
      final snap = await base.get();
      for (final doc in snap.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final estado = data['estado'];
        if (estado is String && conteo.containsKey(estado)) {
          conteo[estado] = conteo[estado]! + 1;
        }
      }
      return conteo;
    }
  }

  // Cuenta reservas por sección (A, B, C, D) para el periodo seleccionado.
  // _col debe apuntar a la colección de 'reservaciones'.
  Stream<Map<String, int>> obtenerReservacionesPorSeccion(Periodo? periodo) {
    // Si no hay periodo seleccionado, devolvemos ceros.
    if (periodo == null || periodo.idPeriodo.isEmpty) {
      return Stream.value({'A': 0, 'B': 0, 'C': 0, 'D': 0});
    }

    // Referencia al documento del periodo (colección 'periodos').
    final periodoRef = _db.collection('periodo').doc(periodo.idPeriodo);

    return _db
        .collection(_col /* 'reservaciones' */)
        .where('periodo', isEqualTo: periodoRef)
        .snapshots()
        .asyncMap((snapshot) async {
      // Mapa de conteo por sección
      final Map<String, int> seccionCount = {'A': 0, 'B': 0, 'C': 0, 'D': 0};

      if (snapshot.docs.isEmpty) return seccionCount;

      // 1) Reunimos referencias únicas de espacios presentes en las reservaciones
      final Set<String> espacioPaths = {};
      final List<DocumentReference> espacioRefs = [];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final dynamic ref = data['espacio'];
        if (ref is DocumentReference && espacioPaths.add(ref.path)) {
          espacioRefs.add(ref);
        }
      }

      if (espacioRefs.isEmpty) return seccionCount;

      // 2) Leemos todos los espacios en paralelo y armamos un mapa path -> seccion
      final espacioSnaps = await Future.wait(espacioRefs.map((r) => r.get()));
      final Map<String, String?> pathToSeccion = {};
      for (final snap in espacioSnaps) {
        final m = snap.data() as Map<String, dynamic>?;
        pathToSeccion[snap.reference.path] = m?['seccion'] as String?;
      }

      // 3) Recorremos las reservaciones y sumamos por la sección del espacio
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final dynamic ref = data['espacio'];
        if (ref is DocumentReference) {
          final sec = pathToSeccion[ref.path];
          if (sec != null && seccionCount.containsKey(sec)) {
            seccionCount[sec] = seccionCount[sec]! + 1;
          }
        }
      }

      return seccionCount;
    });
  }
}
