class Espacio {
  final String idEspacio;
  final bool disponible;
  final String numero;
  final String seccion;

  Espacio(
      {required this.idEspacio,
      required this.disponible,
      required this.numero,
      required this.seccion});

  // Métodos para convertir de y a Map
  factory Espacio.fromMap(Map<String, dynamic> map, String id) {
    return Espacio(
      idEspacio: id,
      disponible: map['disponible'] ?? true,
      numero: map['numero'] ?? '',
      seccion: map['seccion'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'disponible': disponible,
      'numero': numero,
      'seccion': seccion,
    };
  }
}
