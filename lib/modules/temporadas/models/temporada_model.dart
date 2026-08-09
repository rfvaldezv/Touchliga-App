class TemporadaModel {
  const TemporadaModel({
    required this.id,
    required this.ligaId,
    required this.codigo,
    required this.nombre,
    required this.descripcion,
    required this.fechaInicio,
    required this.fechaFin,
    required this.cuota,
    required this.activo,
  });

  final int id;
  final int ligaId;
  final String codigo;
  final String nombre;
  final String descripcion;
  final DateTime fechaInicio;
  final DateTime fechaFin;
  final double cuota;
  final bool activo;

  factory TemporadaModel.fromJson(Map<String, dynamic> json) {
    return TemporadaModel(
      id: (json['id'] as num).toInt(),
      ligaId: (json['ligaId'] as num).toInt(),
      codigo: (json['codigo'] ?? '').toString(),
      nombre: (json['nombre'] ?? '').toString(),
      descripcion: (json['descripcion'] ?? '').toString(),
      fechaInicio: DateTime.tryParse(json['fechaInicio']?.toString() ?? '') ?? DateTime.now(),
      fechaFin: DateTime.tryParse(json['fechaFin']?.toString() ?? '') ?? DateTime.now(),
      cuota: (json['cuota'] as num?)?.toDouble() ?? 0,
      activo: json['activo'] ?? false,
    );
  }
}
