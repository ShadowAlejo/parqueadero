class Vehiculo {
  final String tipo; // auto, moto, bicicleta, etc.
  final String placas;
  final String matricula;
  final String color;

  Vehiculo({
    required this.tipo,
    required this.placas,
    required this.matricula,
    required this.color,
  });

  Map<String, dynamic> toMap() {
    return {
      'tipo': tipo,
      'placas': placas,
      'matricula': matricula,
      'color': color,
    };
  }

  factory Vehiculo.fromMap(Map<String, dynamic> map) {
    return Vehiculo(
      tipo: map['tipo'] ?? '',
      placas: map['placas'] ?? '',
      matricula: map['matricula'] ?? '',
      color: map['color'] ?? '',
    );
  }
}
