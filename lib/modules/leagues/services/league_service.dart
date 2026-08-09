import '../../../app/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/league_model.dart';

class LeagueService {
  LeagueService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<LeagueModel>> getUserLeagues() async {
    final response = await _apiClient.getList(ApiConstants.ligas);

    return response.data!
        .map((json) => LeagueModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<int> crear({
    required String codigo,
    required String nombre,
    required String descripcion,
    required bool activo,
  }) async {
    return _apiClient.postForValue<int>(
      ApiConstants.ligas,
      body: {
        'codigo': codigo,
        'nombre': nombre,
        'descripcion': descripcion,
        'activo': activo,
      },
    );
  }

  Future<void> actualizar({
    required int id,
    required String nombre,
    required String descripcion,
    required bool activo,
  }) async {
    await _apiClient.put(
      '${ApiConstants.ligas}/$id',
      body: {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'activo': activo,
      },
    );
  }

  Future<void> eliminar(int id) async {
    await _apiClient.delete('${ApiConstants.ligas}/$id');
  }
}
