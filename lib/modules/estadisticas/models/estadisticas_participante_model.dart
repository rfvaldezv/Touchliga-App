class EstadisticasParticipanteModel {
  const EstadisticasParticipanteModel({
    required this.rachaActual,
    required this.tendencia,
    required this.posicionActual,
    this.posicionAnterior,
    required this.movimientoPosiciones,
    required this.vecesEnPodio,
    required this.pronosticosAcertados,
    required this.pronosticosFallados,
    this.equipoFavoritoNombre,
    this.formaEquipoFavorito = const [],
  });

  final int rachaActual;
  final String tendencia; // Mejorando | Estable | Bajando
  final int posicionActual;
  final int? posicionAnterior;
  final int movimientoPosiciones;
  final int vecesEnPodio;
  final int pronosticosAcertados;
  final int pronosticosFallados;
  final String? equipoFavoritoNombre;
  final List<String> formaEquipoFavorito;

  int get totalPronosticos => pronosticosAcertados + pronosticosFallados;

  factory EstadisticasParticipanteModel.fromJson(Map<String, dynamic> json) {
    return EstadisticasParticipanteModel(
      rachaActual: (json['rachaActual'] as num?)?.toInt() ?? 0,
      tendencia: (json['tendencia'] ?? 'Estable').toString(),
      posicionActual: (json['posicionActual'] as num?)?.toInt() ?? 0,
      posicionAnterior: (json['posicionAnterior'] as num?)?.toInt(),
      movimientoPosiciones: (json['movimientoPosiciones'] as num?)?.toInt() ?? 0,
      vecesEnPodio: (json['vecesEnPodio'] as num?)?.toInt() ?? 0,
      pronosticosAcertados: (json['pronosticosAcertados'] as num?)?.toInt() ?? 0,
      pronosticosFallados: (json['pronosticosFallados'] as num?)?.toInt() ?? 0,
      equipoFavoritoNombre: json['equipoFavoritoNombre']?.toString(),
      formaEquipoFavorito: (json['formaEquipoFavorito'] as List?)?.map((e) => e.toString()).toList() ?? const [],
    );
  }
}
