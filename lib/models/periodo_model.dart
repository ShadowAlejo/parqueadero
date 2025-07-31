class Periodo {
  final String idPeriodo;
  final bool activo;
  final String nombre;

  Periodo({
    required this.idPeriodo,
    required this.activo,
    required this.nombre,
  });

  // Método para convertir los datos de Firestore a un objeto de tipo Periodo
  factory Periodo.fromFirestore(Map<String, dynamic> firestore) {
    return Periodo(
      idPeriodo: firestore['id_periodo'] ?? '',
      activo: firestore['activo'] ?? true,
      nombre: firestore['nombre'] ?? '',
    );
  }

  // Método para convertir un objeto de tipo Periodo a un mapa (para agregarlo a Firestore)
  Map<String, dynamic> toMap() {
    return {
      'id_periodo': idPeriodo,
      'activo': activo,
      'nombre': nombre,
    };
  }
}
