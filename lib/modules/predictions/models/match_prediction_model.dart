class MatchPredictionModel {
  const MatchPredictionModel({
    required this.matchId,
    required this.localTeamId,
    required this.visitorTeamId,
    required this.localTeam,
    required this.visitorTeam,
    required this.matchDate,
    required this.round,
    this.localTeamCrest,
    this.visitorTeamCrest,
    this.localTeamApodo,
    this.visitorTeamApodo,
    this.cancha,
    this.winnerTeamId,
    this.esDesempate = false,
    this.puntosTotalesPredichos,
    this.diferenciaPuntosPredicha,
    this.puntosTotalesReal,
    this.diferenciaPuntosReal,
    this.realGolesLocal,
    this.realGolesVisitante,
    this.locked = false,
  });

  final int matchId;

  final int localTeamId;
  final int visitorTeamId;

  /// Equipo LOCAL (siempre izquierda)
  final String localTeam;

  /// Equipo VISITANTE (siempre derecha)
  final String visitorTeam;

  final String? localTeamCrest;
  final String? visitorTeamCrest;

  final String? localTeamApodo;
  final String? visitorTeamApodo;

  final String? cancha;

  final DateTime matchDate;

  final int round;

  /// El equipo que el participante cree que va a ganar -- en
  /// Touchliga no se captura marcador, solo el ganador.
  final int? winnerTeamId;

  /// El administrador marca UN partido por jornada como el de la
  /// caja de desempate (suma de puntos total del partido).
  final bool esDesempate;

  /// Solo se captura cuando esDesempate es true. Segundo
  /// diferenciador junto con la suma de puntos: quien quede más
  /// cerca de (suma real + diferencia real) combinadas gana el
  /// punto extra.
  final int? puntosTotalesPredichos;
  final int? diferenciaPuntosPredicha;

  /// La suma/diferencia real de puntos del partido, una vez jugado
  /// -- solo tiene valor si el partido ya tiene resultado capturado.
  final int? puntosTotalesReal;
  final int? diferenciaPuntosReal;

  /// Marcador REAL del partido (goles/anotaciones de cada equipo)
  /// una vez jugado -- para mostrarlo en pantalla, aunque la
  /// predicción en sí solo sea sobre el ganador.
  final int? realGolesLocal;
  final int? realGolesVisitante;

  /// Cuando inicia el partido ya no puede modificarse
  final bool locked;

  bool get completed => winnerTeamId != null;

  bool get tieneResultadoReal => realGolesLocal != null && realGolesVisitante != null;

  bool get editable => !locked;

  MatchPredictionModel copyWith({
    int? winnerTeamId,
    int? puntosTotalesPredichos,
    int? diferenciaPuntosPredicha,
    bool? locked,
  }) {
    return MatchPredictionModel(
      matchId: matchId,
      localTeamId: localTeamId,
      visitorTeamId: visitorTeamId,
      localTeam: localTeam,
      visitorTeam: visitorTeam,
      localTeamCrest: localTeamCrest,
      visitorTeamCrest: visitorTeamCrest,
      localTeamApodo: localTeamApodo,
      visitorTeamApodo: visitorTeamApodo,
      cancha: cancha,
      matchDate: matchDate,
      round: round,
      winnerTeamId: winnerTeamId ?? this.winnerTeamId,
      esDesempate: esDesempate,
      puntosTotalesPredichos: puntosTotalesPredichos ?? this.puntosTotalesPredichos,
      diferenciaPuntosPredicha: diferenciaPuntosPredicha ?? this.diferenciaPuntosPredicha,
      puntosTotalesReal: puntosTotalesReal,
      diferenciaPuntosReal: diferenciaPuntosReal,
      realGolesLocal: realGolesLocal,
      realGolesVisitante: realGolesVisitante,
      locked: locked ?? this.locked,
    );
  }
}
