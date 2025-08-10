import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:parqueadero/models/vehiculo_model.dart';

class VehiculoController {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Obtener vehículos por usuario
  Stream<List<Vehiculo>> obtenerVehiculosPorUsuario(String usuarioId) {
    return _db
        .collection('vehiculos')
        .where('usuarioRef',
            isEqualTo:
                _db.doc('usuarios/$usuarioId')) // Utilizamos la referencia
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Vehiculo.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }).toList();
    });
  }

  // Agregar un nuevo vehículo
  Future<void> agregarVehiculo(Vehiculo vehiculo) async {
    try {
      await _db.collection('vehiculos').doc(vehiculo.id).set(vehiculo.toMap());
    } catch (e) {
      print('Error al agregar vehículo: $e');
    }
  }

  // Actualizar un vehículo existente
  Future<void> actualizarVehiculo(Vehiculo vehiculo) async {
    try {
      await _db
          .collection('vehiculos')
          .doc(vehiculo.id)
          .update(vehiculo.toMap());
    } catch (e) {
      print('Error al actualizar vehículo: $e');
    }
  }

  // Eliminar un vehículo
  Future<void> eliminarVehiculo(String id) async {
    try {
      await _db.collection('vehiculos').doc(id).delete();
    } catch (e) {
      print('Error al eliminar vehículo: $e');
    }
  }
}
