import '../../../app/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

/// Compone el panel principal a partir de los endpoints reales que ya
/// existen (no hay un /api/dashboard dedicado en el backend todavía).
class DashboardService {
  DashboardService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<Map<String, dynamic>>> getLigas() async {
    final response = await _apiClient.getList(ApiConstants.ligas);
    return response.data!.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getTemporadas({int? ligaId}) async {
    final response = await _apiClient.getList(
      ApiConstants.temporadas,
      queryParameters: ligaId != null ? {'ligaId': ligaId} : null,
    );
    return response.data!.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getJornadas({int? temporadaId}) async {
    final response = await _apiClient.getList(
      ApiConstants.jornadas,
      queryParameters: temporadaId != null ? {'temporadaId': temporadaId} : null,
    );
    return response.data!.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getPartidosPorJornada(int jornadaId) async {
    final response = await _apiClient.getList(
      ApiConstants.partidosPorJornada(jornadaId),
    );
    return response.data!.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getMisPronosticosPorJornada(int jornadaId) async {
    final response = await _apiClient.getList(
      ApiConstants.misPronosticosPorJornada(jornadaId),
    );
    return response.data!.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getTablaPosiciones(int temporadaId) async {
    final response = await _apiClient.getList(
      ApiConstants.estandaresPorTemporada(temporadaId),
    );
    return response.data!.cast<Map<String, dynamic>>();
  }
}
