import '../../../core/network/api_client.dart';
import '../models/estadisticas_participante_model.dart';

class EstadisticasService {
  EstadisticasService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<EstadisticasParticipanteModel> getMisEstadisticas(int temporadaId) async {
    final response = await _apiClient.get('/api/estadisticas/participante/temporada/$temporadaId');
    return EstadisticasParticipanteModel.fromJson(response.data!);
  }
}
