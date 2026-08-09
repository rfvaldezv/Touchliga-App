import '../../../app/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/posicion_model.dart';

class StandingsService {
  StandingsService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<PosicionModel>> getTablaPosiciones(int temporadaId) async {
    final response = await _apiClient.getList(
      ApiConstants.estandaresPorTemporada(temporadaId),
    );

    return response.data!
        .map((json) => PosicionModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
