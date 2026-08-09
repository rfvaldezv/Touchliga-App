class PosicionModel {
  const PosicionModel({
    required this.usuarioId,
    required this.nombre,
    required this.puntos,
    required this.aciertos,
    required this.pronosticos,
  });

  final int usuarioId;
  final String nombre;
  final int puntos;
  final int aciertos;
  final int pronosticos;

  factory PosicionModel.fromJson(Map<String, dynamic> json) {
    return PosicionModel(
      usuarioId: (json['usuarioId'] as num).toInt(),
      nombre: (json['nombre'] ?? '').toString(),
      puntos: (json['puntos'] as num).toInt(),
      aciertos: (json['aciertos'] as num).toInt(),
      pronosticos: (json['pronosticos'] as num).toInt(),
    );
  }
}
