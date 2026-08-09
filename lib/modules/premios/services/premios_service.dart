import '../../../core/network/api_client.dart';
import '../models/configuracion_premio_model.dart';
import '../models/ganador_premio_model.dart';

class PremiosService {
  PremiosService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<ConfiguracionPremioModel>> getConfiguracion(int temporadaId, String ambito) async {
    final response =
        await _apiClient.getList('/api/premios/configuracion/temporada/$temporadaId/ambito/$ambito');
    return response.data!
        .map((j) => ConfiguracionPremioModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<void> guardarConfiguracion(
    int temporadaId,
    String ambito,
    List<ConfiguracionPremioModel> premios,
  ) async {
    await _apiClient.post(
      '/api/premios/configuracion',
      body: {
        'temporadaId': temporadaId,
        'ambito': ambito,
        'premios': premios.map((p) => p.toJson()).toList(),
      },
    );
  }

  Future<List<GanadorPremioModel>> getGanadoresJornada(int jornadaId) async {
    final response = await _apiClient.getList('/api/premios/ganadores/jornada/$jornadaId');
    return response.data!.map((j) => GanadorPremioModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<GanadorPremioModel>> getGanadoresFinales(int temporadaId) async {
    final response = await _apiClient.getList('/api/premios/ganadores/temporada/$temporadaId');
    return response.data!.map((j) => GanadorPremioModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> decidirPremio({
    required String ambito,
    required int referenciaId,
    required int usuarioId,
    required String estado,
    double? montoAjustado,
    String? motivo,
  }) async {
    await _apiClient.post(
      '/api/premios/decidir',
      body: {
        'ambito': ambito,
        'referenciaId': referenciaId,
        'usuarioId': usuarioId,
        'estado': estado,
        'montoAjustado': montoAjustado,
        'motivo': motivo,
      },
    );
  }
}
