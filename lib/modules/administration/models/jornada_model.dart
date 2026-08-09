class JornadaModel {
  const JornadaModel({
    required this.id,
    required this.temporadaId,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.numero,
    required this.fechaCierre,
    required this.cerrada,
    required this.activo,
  });

  final int id;
  final int temporadaId;
  final String codigo;
  final String nombre;
  final String descripcion;
  final int numero;
  final DateTime fechaCierre;
  final bool cerrada;
  final bool activo;

  factory JornadaModel.fromJson(Map<String, dynamic> json) {
    return JornadaModel(
      id: (json['id'] as num).toInt(),
      temporadaId: (json['temporadaId'] as num).toInt(),
      codigo: (json['codigo'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      numero: (json['numero'] as num).toInt(),
      fechaCierre: DateTime.tryParse(json['fechaCierre']?.toString() ?? '') ?? DateTime.now(),
      cerrada: json['cerrada'] ?? false,
      activo: json['activo'] ?? false,
    );
  }
}
