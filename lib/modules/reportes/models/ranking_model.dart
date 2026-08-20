class PuntosPorJornadaModel {
  const PuntosPorJornadaModel({
    required this.jornadaId,
    required this.numero,
    required this.puntos,
    required this.calificados,
    required this.todosLosPartidosConResultado,
  });

  final int jornadaId;
  final int numero;
  final int puntos;
  final int calificados;
  final bool todosLosPartidosConResultado;

  factory PuntosPorJornadaModel.fromJson(Map<String, dynamic> json) {
    return PuntosPorJornadaModel(
      jornadaId: (json['jornadaId'] as num).toInt(),
      numero: (json['numero'] as num).toInt(),
      puntos: (json['puntos'] as num?)?.toInt() ?? 0,
      calificados: (json['calificados'] as num?)?.toInt() ?? 0,
      todosLosPartidosConResultado: json['todosLosPartidosConResultado'] ?? false,
    );
  }
}

class RankingModel {
  const RankingModel({
    required this.usuarioId,
    required this.nombre,
    required this.tienePareja,
    this.nombreEquipo,
    required this.jornadas,
    required this.totalPuntos,
    required this.porcentajeProductividad,
  });

  final int usuarioId;
  final String nombre;
  final bool tienePareja;
  final String? nombreEquipo;
  final List<PuntosPorJornadaModel> jornadas;
  final int totalPuntos;
  final double porcentajeProductividad;

  factory RankingModel.fromJson(Map<String, dynamic> json) {
    return RankingModel(
      usuarioId: (json['usuarioId'] as num).toInt(),
      nombre: (json['nombre'] ?? '').toString(),
      tienePareja: json['tienePareja'] ?? false,
      nombreEquipo: json['nombreEquipo']?.toString(),
      jornadas: (json['jornadas'] as List? ?? [])
          .map((j) => PuntosPorJornadaModel.fromJson(j as Map<String, dynamic>))
          .toList(),
      totalPuntos: (json['totalPuntos'] as num?)?.toInt() ?? 0,
      porcentajeProductividad: (json['porcentajeProductividad'] as num?)?.toDouble() ?? 0,
    );
  }
}
