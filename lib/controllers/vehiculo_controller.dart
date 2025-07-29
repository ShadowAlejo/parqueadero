import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehiculo_model.dart'; // asegúrate de la ruta correcta

class VehiculoController {
  final col = FirebaseFirestore.instance
      .collection('vehiculos')
      // especificamos genéricos para que coincida con el modelo
      .withConverter<Vehiculo>(
        fromFirestore: (snap, _) => Vehiculo.fromSnapshot(snap),
        toFirestore: (veh, _) => veh.toMap(),
      );

  /// Crear o reemplazar
  Future<void> crearVehiculo(Vehiculo v) => col.doc(v.id).set(v);

  /// Stream de todos
  Stream<List<Vehiculo>> streamVehiculos() =>
      col.snapshots().map((snap) => snap.docs.map((e) => e.data()).toList());

  /// Obtener uno por ID
  Future<Vehiculo?> obtenerVehiculo(String id) async {
    final doc = await col.doc(id).get();
    return doc.exists ? doc.data() : null;
  }

  /// Actualizar (merge si quieres)
  Future<void> actualizarVehiculo(Vehiculo v) =>
      col.doc(v.id).update(v.toMap());

  /// Borrar
  Future<void> eliminarVehiculo(String id) => col.doc(id).delete();

  /// Filtrar por usuario
  Stream<List<Vehiculo>> streamPorUsuario(String usuarioId) => col
      .where('usuarioRef',
          isEqualTo: FirebaseFirestore.instance.doc('usuarios/$usuarioId'))
      .snapshots()
      .map((snap) => snap.docs.map((e) => e.data()).toList());
}
