import '../models/current_round_model.dart';
import '../models/dashboard_model.dart';
import '../models/pending_predictions_model.dart';
import '../models/welcome_model.dart';
import '../services/dashboard_service.dart';

Map<String, dynamic>? _buscarPorId(List<Map<String, dynamic>> lista, int id) {
  for (final item in lista) {
    if ((item['id'] as num).toInt() == id) return item;
  }
  return null;
}

class DashboardRepository {
  DashboardRepository({required DashboardService service}) : _service = service;

  final DashboardService _service;

  /// [usuarioId] y [usuarioNombre] vienen de la sesión ya autenticada
  /// (authProvider). [seleccionLigaId]/[seleccionTemporadaId]/
  /// [seleccionJornadaId] vienen del selector (Ligas → Temporadas →
  /// Jornadas) si el usuario ya eligió algo — si no, se usa "la
  /// primera que exista" como antes, para que el Dashboard nunca
  /// quede vacío.
  Future<DashboardModel> loadDashboard({
    required int usuarioId,
    required String usuarioNombre,
    int? seleccionLigaId,
    int? seleccionTemporadaId,
    int? seleccionJornadaId,
  }) async {
    final ligas = await _service.getLigas();

    final liga = seleccionLigaId != null
        ? _buscarPorId(ligas, seleccionLigaId)
        : (ligas.isNotEmpty ? ligas.first : null);

    final ligaId = liga != null ? (liga['id'] as num).toInt() : null;

    final temporadas = await _service.getTemporadas(ligaId: ligaId);

    final temporada = seleccionTemporadaId != null
        ? _buscarPorId(temporadas, seleccionTemporadaId)
        : (temporadas.isNotEmpty ? temporadas.first : null);

    final temporadaId = temporada != null ? (temporada['id'] as num).toInt() : 0;

    final jornadas = temporadaId != 0
        ? await _service.getJornadas(temporadaId: temporadaId)
        : <Map<String, dynamic>>[];

    Map<String, dynamic>? _jornadaPorDefecto(List<Map<String, dynamic>> lista) {
      if (lista.isEmpty) return null;
      final ordenadas = [...lista]
        ..sort((a, b) => (b['numero'] as num).compareTo(a['numero'] as num));
      final abiertas = ordenadas.where((j) => j['cerrada'] != true);
      return abiertas.isNotEmpty ? abiertas.first : ordenadas.first;
    }

    final jornada = seleccionJornadaId != null
        ? _buscarPorId(jornadas, seleccionJornadaId)
        : _jornadaPorDefecto(jornadas);

    final jornadaId = jornada != null ? (jornada['id'] as num).toInt() : 0;
    final numeroJornada = jornada != null ? (jornada['numero'] as num).toInt() : 0;

    final partidos = jornadaId != 0
        ? await _service.getPartidosPorJornada(jornadaId)
        : <Map<String, dynamic>>[];

    final misPronosticos = jornadaId != 0
        ? await _service.getMisPronosticosPorJornada(jornadaId)
        : <Map<String, dynamic>>[];

    final tabla = temporadaId != 0
        ? await _service.getTablaPosiciones(temporadaId)
        : <Map<String, dynamic>>[];

    final totalMatches = partidos.length;
    final completedMatches =
        partidos.where((p) => p['tieneResultado'] == true).length;
    final pendingMatches = totalMatches - misPronosticos.length < 0
        ? 0
        : totalMatches - misPronosticos.length;

    var posicion = 0;
    var puntos = 0;

    for (var i = 0; i < tabla.length; i++) {
      if ((tabla[i]['usuarioId'] as num).toInt() == usuarioId) {
        posicion = i + 1;
        puntos = (tabla[i]['puntos'] as num).toInt();
        break;
      }
    }

    return DashboardModel(
      welcome: WelcomeModel(
        userName: usuarioNombre,
        leagueName: liga != null ? (liga['nombre'] ?? '').toString() : 'Sin liga',
        tournamentName:
            temporada != null ? (temporada['nombre'] ?? '').toString() : '',
        position: posicion,
        points: puntos,
      ),
      currentRound: CurrentRoundModel(
        round: numeroJornada,
        totalMatches: totalMatches,
        completedMatches: completedMatches,
        pendingMatches: pendingMatches,
      ),
      pendingPredictions: PendingPredictionsModel(pendingMatches: pendingMatches),
    );
  }
}
