class DetallePartidoModel {
  const DetallePartidoModel({
    required this.partidoId,
    required this.puntos,
    this.escudoLocalUrl,
    this.escudoVisitanteUrl,
    this.equipoGanadorReal,
    this.equipoGanadorPronostico,
    this.esDesempate = false,
    this.puntosTotalesPredichos,
    this.diferenciaPuntosPredicha,
    this.puntosTotalesReal,
    this.diferenciaPuntosReal,
    this.puntosBono = 0,
  });

  final int partidoId;
  final int? puntos;
  final String? escudoLocalUrl;
  final String? escudoVisitanteUrl;
  final int? equipoGanadorReal;
  final int? equipoGanadorPronostico;
  final bool esDesempate;
  final int? puntosTotalesPredichos;
  final int? diferenciaPuntosPredicha;
  final int? puntosTotalesReal;
  final int? diferenciaPuntosReal;
  final int puntosBono;

  factory DetallePartidoModel.fromJson(Map<String, dynamic> json) {
    return DetallePartidoModel(
      partidoId: (json['partidoId'] as num).toInt(),
      puntos: (json['puntos'] as num?)?.toInt(),
      escudoLocalUrl: json['escudoLocalUrl']?.toString(),
      escudoVisitanteUrl: json['escudoVisitanteUrl']?.toString(),
      equipoGanadorReal: (json['equipoGanadorReal'] as num?)?.toInt(),
      equipoGanadorPronostico: (json['equipoGanadorPronostico'] as num?)?.toInt(),
      esDesempate: json['esDesempate'] as bool? ?? false,
      puntosTotalesPredichos: (json['puntosTotalesPredichos'] as num?)?.toInt(),
      diferenciaPuntosPredicha: (json['diferenciaPuntosPredicha'] as num?)?.toInt(),
      puntosTotalesReal: (json['puntosTotalesReal'] as num?)?.toInt(),
      diferenciaPuntosReal: (json['diferenciaPuntosReal'] as num?)?.toInt(),
      puntosBono: (json['puntosBono'] as num?)?.toInt() ?? 0,
    );
  }
}

class DetalleJornadaModel {
  const DetalleJornadaModel({
    required this.usuarioId,
    required this.nombre,
    required this.partidos,
    required this.total,
  });

  final int usuarioId;
  final String nombre;
  final List<DetallePartidoModel> partidos;
  final int total;

  factory DetalleJornadaModel.fromJson(Map<String, dynamic> json) {
    return DetalleJornadaModel(
      usuarioId: (json['usuarioId'] as num).toInt(),
      nombre: (json['nombre'] ?? '').toString(),
      partidos: (json['partidos'] as List? ?? [])
          .map((p) => DetallePartidoModel.fromJson(p as Map<String, dynamic>))
          .toList(),
      total: (json['total'] as num?)?.toInt() ?? 0,
    );
  }
}
