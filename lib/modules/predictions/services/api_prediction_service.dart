import '../../../app/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../equipos/services/equipo_service.dart';
import '../models/match_prediction_model.dart';
import '../models/prediction_day_model.dart';
import 'prediction_service.dart';

class ApiPredictionService implements PredictionService {
  ApiPredictionService({required ApiClient apiClient})
    : _apiClient = apiClient,
      _equipoService = EquipoService(apiClient: apiClient);

  final ApiClient _apiClient;
  final EquipoService _equipoService;

  @override
  Future<PredictionDayModel> loadPredictionDay({required int jornadaId}) async {
    // 1. Datos de la jornada (nombre, número, si ya cerró)
    final jornadaResponse = await _apiClient.get('${ApiConstants.jornadas}/$jornadaId');
    final jornada = jornadaResponse.data!;

    final cerrada = jornada['cerrada'] as bool? ?? false;
    final numero = jornada['numero'] as int? ?? 0;
    final nombreJornada = (jornada['nombre'] ?? 'Jornada $numero').toString();

    // 2. Partidos de la jornada
    final partidosResponse = await _apiClient.getList(
      ApiConstants.partidosPorJornada(jornadaId),
    );
    final partidos = partidosResponse.data!.cast<Map<String, dynamic>>();

    // 3. Equipos (para mostrar nombres reales)
    final equipos = await _equipoService.getEquipos();
    final nombresPorId = {for (final e in equipos) e.id: e.nombre};
    final escudosPorId = {for (final e in equipos) e.id: e.escudoUrl};
    final apodosPorId = {for (final e in equipos) e.id: e.apodo};

    // 4. Mis pronósticos ya capturados en esta jornada
    final pronosticosResponse = await _apiClient.getList(
      ApiConstants.misPronosticosPorJornada(jornadaId),
    );
    final pronosticos = pronosticosResponse.data!.cast<Map<String, dynamic>>();
    final pronosticoPorPartido = {
      for (final p in pronosticos) (p['partidoId'] as num).toInt(): p,
    };

    final matches = partidos.map((partido) {
      final partidoId = (partido['id'] as num).toInt();
      final equipoLocalId = (partido['equipoLocalId'] as num).toInt();
      final equipoVisitanteId = (partido['equipoVisitanteId'] as num).toInt();
      final miPronostico = pronosticoPorPartido[partidoId];

      return MatchPredictionModel(
        matchId: partidoId,
        localTeamId: equipoLocalId,
        visitorTeamId: equipoVisitanteId,
        localTeam: nombresPorId[equipoLocalId] ?? 'Equipo $equipoLocalId',
        visitorTeam: nombresPorId[equipoVisitanteId] ?? 'Equipo $equipoVisitanteId',
        localTeamCrest: escudosPorId[equipoLocalId],
        visitorTeamCrest: escudosPorId[equipoVisitanteId],
        localTeamApodo: apodosPorId[equipoLocalId],
        visitorTeamApodo: apodosPorId[equipoVisitanteId],
        cancha: partido['canchaNombre']?.toString(),
        matchDate: DateTime.tryParse(partido['fechaHora']?.toString() ?? '') ??
            DateTime.now(),
        round: numero,
        winnerTeamId: (miPronostico?['equipoGanadorId'] as num?)?.toInt(),
        esDesempate: partido['esDesempate'] as bool? ?? false,
        puntosTotalesPredichos: (miPronostico?['puntosTotalesPredichos'] as num?)?.toInt(),
        diferenciaPuntosPredicha: (miPronostico?['diferenciaPuntosPredicha'] as num?)?.toInt(),
        puntosTotalesReal: (partido['puntosTotalesReal'] as num?)?.toInt(),
        diferenciaPuntosReal: (partido['diferenciaPuntosReal'] as num?)?.toInt(),
        realGolesLocal: partido['golesLocal'] as int?,
        realGolesVisitante: partido['golesVisitante'] as int?,
        locked: cerrada,
      );
    }).toList();

    return PredictionDayModel(
      jornadaId: jornadaId,
      leagueId: 0,
      leagueName: nombreJornada,
      tournamentId: 0,
      tournamentName: jornada['codigo']?.toString() ?? '',
      round: numero,
      isOpen: !cerrada,
      matches: matches,
    );
  }

  @override
  Future<bool> savePredictions(PredictionDayModel predictionDay) async {
    final matchesToSave = predictionDay.matches.where(
      (m) => m.winnerTeamId != null,
    );

    final lote = matchesToSave
        .map((match) => {
              'partidoId': match.matchId,
              'equipoGanadorId': match.winnerTeamId,
              'puntosTotalesPredichos': match.esDesempate ? match.puntosTotalesPredichos : null,
              'diferenciaPuntosPredicha': match.esDesempate ? match.diferenciaPuntosPredicha : null,
            })
        .toList();

    if (lote.isEmpty) return predictionDay.isComplete;

    final completa = await _apiClient.postForValue<bool>(
      ApiConstants.guardarPronosticosLote(predictionDay.jornadaId),
      body: lote,
    );

    return completa;
  }
}
