import '../../../core/network/api_client.dart';
import '../models/detalle_jornada_model.dart';
import '../models/ranking_model.dart';

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
}
