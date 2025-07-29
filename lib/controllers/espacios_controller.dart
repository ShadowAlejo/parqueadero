import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parqueadero/models/espacio_model.dart';

class EspacioController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Escuchar los espacios en tiempo real (usando Stream)
  Stream<List<Espacio>> obtenerEspaciosEnTiempoReal() {
    return _db.collection('espacios').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        return Espacio.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Obtener el número total de espacios por sección en tiempo real
  Stream<int> obtenerTotalDeEspaciosPorSeccionEnTiempoReal(String seccion) {
    return _db
        .collection('espacios')
        .where('seccion', isEqualTo: seccion)
        .snapshots()
        .map((snapshot) => snapshot.docs.length);
  }

  // Verificar si el número de espacio ya existe en la misma sección
  Future<bool> numeroDeEspacioExiste(String seccion, int numero) async {
    try {
      QuerySnapshot snapshot = await _db
          .collection('espacios')
          .where('seccion', isEqualTo: seccion)
          .where('numero', isEqualTo: numero)
          .get();
      return snapshot.docs.isNotEmpty;
    } catch (e) {
      throw Exception('Error al verificar el número del espacio: $e');
    }
  }

  // Agregar múltiples espacios a la misma sección
  Future<void> agregarMultiplesEspacios(String seccion, int cantidad) async {
    WriteBatch batch = _db.batch();

    // Verificar que los números de espacio no se repitan
    for (int i = 1; i <= cantidad; i++) {
      bool existe = await numeroDeEspacioExiste(seccion, i);
      if (existe) {
        throw Exception('El número $i ya existe en la sección $seccion.');
      }

      String idEspacio = '${seccion}_$i';
      Espacio espacio = Espacio(
        idEspacio: idEspacio,
        disponible: true,
        numero: i.toString(),
        seccion: seccion,
      );
      batch.set(_db.collection('espacios').doc(idEspacio), espacio.toMap());
    }

    // Ejecutar el batch
    await batch.commit();
  }
}
