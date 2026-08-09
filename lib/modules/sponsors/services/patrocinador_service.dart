import '../../../core/network/api_client.dart';
import '../models/patrocinador_model.dart';

class PatrocinadorService {
  PatrocinadorService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  /// Solo los activos, ordenados — para el banner rotativo.
  Future<List<PatrocinadorModel>> getActivos() async {
    final response = await _apiClient.getList('/api/patrocinadores/activos');
    return response.data!.map((j) => PatrocinadorModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Todos (activos e inactivos) — para administración.
  Future<List<PatrocinadorModel>> getAll() async {
    final response = await _apiClient.getList('/api/patrocinadores');
    return response.data!.map((j) => PatrocinadorModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<int> crear({
    required String codigo,
    required String nombre,
    required String descripcion,
    required String imagenUrl,
    String? enlaceUrl,
    required int orden,
    required bool activo,
  }) async {
    return _apiClient.postForValue<int>(
      '/api/patrocinadores',
      body: {
        'codigo': codigo,
        'nombre': nombre,
        'descripcion': descripcion,
        'imagenUrl': imagenUrl,
        'enlaceUrl': enlaceUrl,
        'orden': orden,
        'activo': activo,
      },
    );
  }

  Future<void> actualizar({
    required int id,
    required String nombre,
    required String descripcion,
    required String imagenUrl,
    String? enlaceUrl,
    required int orden,
    required bool activo,
  }) async {
    await _apiClient.put(
      '/api/patrocinadores/$id',
      body: {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'imagenUrl': imagenUrl,
        'enlaceUrl': enlaceUrl,
        'orden': orden,
        'activo': activo,
      },
    );
  }

  Future<void> eliminar(int id) async {
    await _apiClient.delete('/api/patrocinadores/$id');
  }
}
