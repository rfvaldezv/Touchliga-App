import '../../../core/network/api_client.dart';
import '../models/detalle_jornada_model.dart';
import '../models/ranking_model.dart';
import '../models/participante_pendiente_model.dart';

class ReportesService {
  ReportesService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<DetalleJornadaModel>> getDetalleJornada(int jornadaId) async {
    final response = await _apiClient.getList('/api/reportes/jornada/$jornadaId');
    return response.data!
        .map((j) => DetalleJornadaModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<RankingModel>> getRanking(int temporadaId) async {
    final response = await _apiClient.getList('/api/reportes/ranking/temporada/$temporadaId');
    return response.data!
        .map((j) => RankingModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<List<ParticipantePendienteModel>> getParticipantesPendientes(int jornadaId) async {
    final response = await _apiClient.getList('/api/reportes/pendientes/jornada/$jornadaId');
    return response.data!
        .map((j) => ParticipantePendienteModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// PDF de auditoría de una jornada -- tabla con cada participante y
  /// sus pronósticos de cada partido, para compartir en WhatsApp.
  Future<List<int>> getReporteAuditoriaPdf(int jornadaId) async {
    return _apiClient.getBytes('/api/reportes/jornada/$jornadaId/pdf-auditoria');
  }
}
