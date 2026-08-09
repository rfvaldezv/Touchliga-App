import 'match_prediction_model.dart';

class PredictionDayModel {
  const PredictionDayModel({
    required this.jornadaId,
    required this.leagueId,
    required this.leagueName,
    required this.tournamentId,
    required this.tournamentName,
    required this.round,
    required this.matches,
    required this.isOpen,
  });

  final int jornadaId;

  final int leagueId;
  final String leagueName;

  final int tournamentId;
  final String tournamentName;

  final int round;

  final List<MatchPredictionModel> matches;

  /// Indica si la jornada continúa abierta para captura.
  final bool isOpen;

  /// Total de partidos de la jornada.
  int get totalMatches => matches.length;

  /// Partidos con ambos marcadores capturados.
  int get completedMatches => matches.where((match) => match.completed).length;

  /// Partidos pendientes de completar.
  int get pendingMatches => totalMatches - completedMatches;

  /// Indica si todos los pronósticos están completos.
  bool get isComplete => totalMatches > 0 && pendingMatches == 0;

  /// Progreso de captura entre 0.0 y 1.0.
  double get progress {
    if (totalMatches == 0) {
      return 0;
    }

    return completedMatches / totalMatches;
  }

  /// Porcentaje entero para mostrar en pantalla.
  int get progressPercentage => (progress * 100).round();

  /// Indica si todavía existe al menos un partido editable.
  bool get hasEditableMatches =>
      isOpen && matches.any((match) => match.editable);

  PredictionDayModel copyWith({
    int? jornadaId,
    int? leagueId,
    String? leagueName,
    int? tournamentId,
    String? tournamentName,
    int? round,
    List<MatchPredictionModel>? matches,
    bool? isOpen,
  }) {
    return PredictionDayModel(
      jornadaId: jornadaId ?? this.jornadaId,
      leagueId: leagueId ?? this.leagueId,
      leagueName: leagueName ?? this.leagueName,
      tournamentId: tournamentId ?? this.tournamentId,
      tournamentName: tournamentName ?? this.tournamentName,
      round: round ?? this.round,
      matches: matches ?? this.matches,
      isOpen: isOpen ?? this.isOpen,
    );
  }
}
