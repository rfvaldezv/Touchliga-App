class PartidoModel {
  const PartidoModel({
    required this.id,
    required this.jornadaId,
    required this.equipoLocalId,
    required this.equipoVisitanteId,
    required this.fechaHora,
    required this.golesLocal,
    required this.golesVisitante,
    required this.tieneResultado,
    required this.esDesempate,
    this.canchaId,
    this.canchaNombre,
  });

  final int id;
  final int jornadaId;
  final int equipoLocalId;
  final int equipoVisitanteId;
  final DateTime fechaHora;
  final int? golesLocal;
  final int? golesVisitante;
  final bool tieneResultado;
  final bool esDesempate;
  final int? canchaId;
  final String? canchaNombre;

  factory PartidoModel.fromJson(Map<String, dynamic> json) {
    return PartidoModel(
      id: (json['id'] as num).toInt(),
      jornadaId: (json['jornadaId'] as num).toInt(),
      equipoLocalId: (json['equipoLocalId'] as num).toInt(),
      equipoVisitanteId: (json['equipoVisitanteId'] as num).toInt(),
      fechaHora: DateTime.tryParse(json['fechaHora']?.toString() ?? '') ?? DateTime.now(),
      golesLocal: (json['golesLocal'] as num?)?.toInt(),
      golesVisitante: (json['golesVisitante'] as num?)?.toInt(),
      tieneResultado: json['tieneResultado'] ?? false,
      esDesempate: json['esDesempate'] ?? false,
      canchaId: (json['canchaId'] as num?)?.toInt(),
      canchaNombre: json['canchaNombre']?.toString(),
    );
  }
}
