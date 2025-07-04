// lib/controllers/espacios_controller.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/espacio.dart';

class EspaciosController {
  final CollectionReference<Map<String, dynamic>> _colEspacios =
      FirebaseFirestore.instance.collection('espacios');

  /// Lee todos los espacios
  Future<List<Espacio>> fetchAll() async {
    final snapshot = await _colEspacios.get();
    return snapshot.docs.map((doc) => Espacio.fromFirestore(doc)).toList();
  }

  /// Lee un espacio por su ID
  Future<Espacio?> fetchById(String id) async {
    final doc = await _colEspacios.doc(id).get();
    if (!doc.exists) return null;
    return Espacio.fromFirestore(doc);
  }

  /// Crea un nuevo espacio
  Future<void> create(Espacio espacio) async {
    await _colEspacios.add(espacio.toFirestore());
  }

  /// Actualiza un espacio existente
  Future<void> update(Espacio espacio) async {
    await _colEspacios.doc(espacio.id).update(espacio.toFirestore());
  }

  /// Elimina un espacio
  Future<void> delete(String id) async {
    await _colEspacios.doc(id).delete();
  }
}
