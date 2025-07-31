import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parqueadero/models/espacio_model.dart';

class EspacioController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Escucha todos los espacios en tiempo real
  Stream<List<Espacio>> obtenerEspaciosEnTiempoReal() {
    return _db.collection('espacios').snapshots().map((snapshot) => snapshot
        .docs
        .map((doc) =>
            Espacio.fromMap(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  /// Cuenta espacios por sección en tiempo real
  Stream<int> obtenerTotalDeEspaciosPorSeccionEnTiempoReal(String seccion) {
    return _db
        .collection('espacios')
        .where('seccion', isEqualTo: seccion)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  /// Verifica si un número de espacio ya existe en la misma sección
  Future<bool> numeroDeEspacioExiste(String seccion, int numero) async {
    try {
      final snapshot = await _db
          .collection('espacios')
          .where('seccion', isEqualTo: seccion)
          // El campo 'numero' se almacena como String
          .where('numero', isEqualTo: numero.toString())
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error al verificar número de espacio: $e');
    }
  }

  /// Agrega múltiples espacios nuevos a una sección
  Future<void> agregarMultiplesEspacios(String seccion, int cantidad) async {
    final batch = _db.batch();
    for (int i = 1; i <= cantidad; i++) {
      final existe = await numeroDeEspacioExiste(seccion, i);
      if (existe) {
        throw Exception('El número $i ya existe en la sección $seccion.');
      }

      final idEspacio = '${seccion}_$i';
      final espacio = Espacio(
        idEspacio: idEspacio,
        disponible: true,
        numero: i.toString(),
        seccion: seccion,
      );
      batch.set(
        _db.collection('espacios').doc(idEspacio),
        espacio.toMap(),
      );
    }
    await batch.commit();
  }

  // Función nueva para obtener los espacios disponibles organizados por sección
  Stream<Map<String, List<Espacio>>> obtenerEspaciosDisponiblesPorSeccion(
      String s) {
    return _db
        .collection('espacios')
        .where('disponible',
            isEqualTo: true) // Filtramos los espacios que están disponibles
        .snapshots() // Escuchamos los cambios en tiempo real
        .map((snapshot) {
      Map<String, List<Espacio>> espaciosPorSeccion = {};

      // Iteramos sobre los documentos obtenidos
      for (var doc in snapshot.docs) {
        // Convertimos el documento en un objeto Espacio
        Espacio espacio =
            Espacio.fromMap(doc.data() as Map<String, dynamic>, doc.id);

        // Si la sección ya está en el mapa, agregamos el espacio a la lista correspondiente
        if (espaciosPorSeccion.containsKey(espacio.seccion)) {
          espaciosPorSeccion[espacio.seccion]!.add(espacio);
        } else {
          // Si no existe la sección en el mapa, creamos una nueva lista con el espacio
          espaciosPorSeccion[espacio.seccion] = [espacio];
        }
      }

      // Retornamos el mapa con los espacios disponibles por sección
      return espaciosPorSeccion;
    });
  }

  /// Marca un espacio como ocupado
  Future<void> ocuparEspacio(String idEspacio) {
    return _db
        .collection('espacios')
        .doc(idEspacio)
        .update({'disponible': false});
  }

  /// Marca un espacio como disponible
  Future<void> liberarEspacio(String idEspacio) {
    return _db
        .collection('espacios')
        .doc(idEspacio)
        .update({'disponible': true});
  }
}
