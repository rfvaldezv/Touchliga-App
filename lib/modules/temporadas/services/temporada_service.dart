import '../../../app/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/temporada_model.dart';

class TemporadaService {
  TemporadaService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<TemporadaModel>> getTemporadas({int? ligaId}) async {
    final response = await _apiClient.getList(
      ApiConstants.temporadas,
      queryParameters: ligaId != null ? {'ligaId': ligaId} : null,
    );
    return response.data!
        .map((json) => TemporadaModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<int> crear({
    required int ligaId,
    required String codigo,
    required String nombre,
    required String descripcion,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required double cuota,
    required bool activo,
  }) async {
    return _apiClient.postForValue<int>(
      ApiConstants.temporadas,
      body: {
        'ligaId': ligaId,
        'codigo': codigo,
        'nombre': nombre,
        'descripcion': descripcion,
        'fechaInicio': fechaInicio.toIso8601String(),
        'fechaFin': fechaFin.toIso8601String(),
        'cuota': cuota,
        'activo': activo,
      },
    );
  }

  Future<void> actualizar({
    required int id,
    required String nombre,
    required String descripcion,
    required DateTime fechaInicio,
    required DateTime fechaFin,
    required double cuota,
    required bool activo,
  }) async {
    await _apiClient.put(
      '${ApiConstants.temporadas}/$id',
      body: {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'fechaInicio': fechaInicio.toIso8601String(),
        'fechaFin': fechaFin.toIso8601String(),
        'cuota': cuota,
        'activo': activo,
      },
    );
  }

  Future<void> eliminar(int id) async {
    await _apiClient.delete('${ApiConstants.temporadas}/$id');
  }
}
