import '../../core/network/api_client.dart';
import '../models/catalogo_item_model.dart';

/// Servicio genérico para catálogos simples (Ciudad, País, Estado, etc.)
/// que comparten la misma forma id/codigo/nombre/descripcion/activo.
/// Evita repetir el mismo modelo/servicio 10 veces.
class CatalogoService {
  CatalogoService({required ApiClient apiClient, required String endpoint})
    : _apiClient = apiClient,
      _endpoint = endpoint;

  final ApiClient _apiClient;
  final String _endpoint;

  Future<List<CatalogoItemModel>> getAll() async {
    final response = await _apiClient.getList(_endpoint);
    return response.data!
        .map((json) => CatalogoItemModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<int> crear({
    required String codigo,
    required String nombre,
    required String descripcion,
    required bool activo,
  }) async {
    return _apiClient.postForValue<int>(
      _endpoint,
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
      '$_endpoint/$id',
      body: {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'activo': activo,
      },
    );
  }
}
