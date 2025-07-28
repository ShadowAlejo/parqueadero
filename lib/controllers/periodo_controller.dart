import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parqueadero/models/periodo_model.dart';

class PeriodoController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Método para obtener el stream de periodos (en tiempo real)
  Stream<List<Periodo>> obtenerPeriodosStream() {
    return _db.collection('periodo').snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) =>
              Periodo.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    });
  }

  // Método para obtener todos los periodos (solo una vez)
  Future<List<Periodo>> obtenerPeriodos() async {
    var snapshot = await _db.collection('periodo').get();
    return snapshot.docs
        .map((doc) => Periodo.fromFirestore(doc.data() as Map<String, dynamic>))
        .toList();
  }

  // Método para agregar un nuevo periodo
  Future<void> agregarPeriodo(Periodo periodo) async {
    // Verificar si ya existe un periodo activo
    await desmarcarPeriodoActivo();

    // Crear el nuevo periodo
    await _db.collection('periodo').doc(periodo.idPeriodo).set(periodo.toMap());
  }

  // Método para actualizar un periodo
  Future<void> actualizarPeriodo(Periodo periodo) async {
    await _db
        .collection('periodo')
        .doc(periodo.idPeriodo)
        .update(periodo.toMap());
  }

  // Método para eliminar un periodo
  Future<void> eliminarPeriodo(String idPeriodo) async {
    await _db.collection('periodo').doc(idPeriodo).delete();
  }

  // Método para desmarcar el periodo activo (si existe)
  Future<void> desmarcarPeriodoActivo() async {
    var snapshot =
        await _db.collection('periodo').where('activo', isEqualTo: true).get();

    if (snapshot.docs.isNotEmpty) {
      for (var doc in snapshot.docs) {
        await _db.collection('periodo').doc(doc.id).update({'activo': false});
      }
    }
  }
}
