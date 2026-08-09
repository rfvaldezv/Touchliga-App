class GanadorParticipanteModel {
  const GanadorParticipanteModel({
    required this.usuarioId,
    required this.nombre,
    required this.puntos,
    required this.montoSugerido,
    required this.estado,
    this.montoAjustado,
    this.motivo,
  });

  final int usuarioId;
  final String nombre;
  final int puntos;
  final double montoSugerido;
  final String estado; // Pendiente | Aprobado | Denegado
  final double? montoAjustado;
  final String? motivo;

  factory GanadorParticipanteModel.fromJson(Map<String, dynamic> json) {
    return GanadorParticipanteModel(
      usuarioId: (json['usuarioId'] as num).toInt(),
      nombre: (json['nombre'] ?? '').toString(),
      puntos: (json['puntos'] as num?)?.toInt() ?? 0,
      montoSugerido: (json['montoSugerido'] as num?)?.toDouble() ?? 0,
      estado: (json['estado'] ?? 'Pendiente').toString(),
      montoAjustado: (json['montoAjustado'] as num?)?.toDouble(),
      motivo: json['motivo']?.toString(),
    );
  }
}

class GanadorPremioModel {
  const GanadorPremioModel({
    required this.posicionDesde,
    required this.posicionHasta,
    required this.participantes,
    required this.tipoPremio,
    this.descripcion,
    required this.huboEmpate,
  });

  final int posicionDesde;
  final int posicionHasta;
  final List<GanadorParticipanteModel> participantes;
  final String tipoPremio;
  final String? descripcion;
  final bool huboEmpate;

  factory GanadorPremioModel.fromJson(Map<String, dynamic> json) {
    return GanadorPremioModel(
      posicionDesde: (json['posicionDesde'] as num).toInt(),
      posicionHasta: (json['posicionHasta'] as num).toInt(),
      participantes: (json['participantes'] as List? ?? [])
          .map((p) => GanadorParticipanteModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      tipoPremio: (json['tipoPremio'] ?? '').toString(),
      descripcion: json['descripcion']?.toString(),
      huboEmpate: json['huboEmpate'] ?? false,
    );
  }
}
