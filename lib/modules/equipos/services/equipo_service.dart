import '../../../app/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/equipo_model.dart';

class EquipoService {
  EquipoService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<EquipoModel>> getEquipos() async {
    final response = await _apiClient.getList(ApiConstants.equipos);

    return response.data!
        .map((json) => EquipoModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<int> crear({
    required String codigo,
    required String nombre,
    required String descripcion,
    String? escudoUrl,
    String? apodo,
    required bool activo,
  }) async {
    return _apiClient.postForValue<int>(
      ApiConstants.equipos,
      body: {
        'codigo': codigo,
        'nombre': nombre,
        'descripcion': descripcion,
        'escudoUrl': escudoUrl,
        'apodo': apodo,
        'activo': activo,
      },
    );
  }

  Future<void> actualizar({
    required int id,
    required String nombre,
    required String descripcion,
    String? escudoUrl,
    String? apodo,
    required bool activo,
  }) async {
    await _apiClient.put(
      '${ApiConstants.equipos}/$id',
      body: {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'escudoUrl': escudoUrl,
        'apodo': apodo,
        'activo': activo,
      },
    );
  }

  Future<void> eliminar(int id) async {
    await _apiClient.delete('${ApiConstants.equipos}/$id');
  }
}
