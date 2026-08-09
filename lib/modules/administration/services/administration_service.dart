import '../../../app/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../models/jornada_model.dart';
import '../models/partido_model.dart';

class AdministrationService {
  AdministrationService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<JornadaModel>> getJornadas({int? temporadaId}) async {
    final response = await _apiClient.getList(
      ApiConstants.jornadas,
      queryParameters: temporadaId != null ? {'temporadaId': temporadaId} : null,
    );
    return response.data!
        .map((json) => JornadaModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<int> crearJornada({
    required int temporadaId,
    required String codigo,
    required String nombre,
    required String descripcion,
    required int numero,
    required DateTime fechaCierre,
  }) async {
    return _apiClient.postForValue<int>(
      ApiConstants.jornadas,
      body: {
        'temporadaId': temporadaId,
        'codigo': codigo,
        'nombre': nombre,
        'descripcion': descripcion,
        'numero': numero,
        'fechaCierre': fechaCierre.toIso8601String(),
        'activo': true,
      },
    );
  }

  Future<void> editarJornada({
    required int id,
    required String nombre,
    required String descripcion,
    required int numero,
    required DateTime fechaCierre,
    required bool activo,
  }) async {
    await _apiClient.put(
      '${ApiConstants.jornadas}/$id',
      body: {
        'id': id,
        'nombre': nombre,
        'descripcion': descripcion,
        'numero': numero,
        'fechaCierre': fechaCierre.toIso8601String(),
        'activo': activo,
      },
    );
  }

  Future<void> eliminarJornada(int id) async {
    await _apiClient.delete('${ApiConstants.jornadas}/$id');
  }

  Future<void> abrirJornada(int id) async {
    await _apiClient.post('${ApiConstants.jornadas}/$id/abrir');
  }

  Future<void> cerrarJornada(int jornadaId) async {
    await _apiClient.post(ApiConstants.cerrarJornada(jornadaId));
  }

  Future<List<PartidoModel>> getPartidosPorJornada(int jornadaId) async {
    final response = await _apiClient.getList(
      ApiConstants.partidosPorJornada(jornadaId),
    );
    return response.data!
        .map((json) => PartidoModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<int> crearPartido({
    required int jornadaId,
    required int equipoLocalId,
    required int equipoVisitanteId,
    required DateTime fechaHora,
    int? canchaId,
  }) async {
    return _apiClient.postForValue<int>(
      ApiConstants.partidos,
      body: {
        'jornadaId': jornadaId,
        'equipoLocalId': equipoLocalId,
        'equipoVisitanteId': equipoVisitanteId,
        'fechaHora': fechaHora.toIso8601String(),
        'canchaId': canchaId,
      },
    );
  }

  Future<void> capturarResultado({
    required int partidoId,
    required int golesLocal,
    required int golesVisitante,
  }) async {
    await _apiClient.post(
      ApiConstants.capturarResultado(partidoId),
      body: {'golesLocal': golesLocal, 'golesVisitante': golesVisitante},
    );
  }

  Future<void> editarPartido({
    required int id,
    required int equipoLocalId,
    required int equipoVisitanteId,
    required DateTime fechaHora,
    int? canchaId,
  }) async {
    await _apiClient.put(
      '${ApiConstants.partidos}/$id',
      body: {
        'id': id,
        'equipoLocalId': equipoLocalId,
        'equipoVisitanteId': equipoVisitanteId,
        'fechaHora': fechaHora.toIso8601String(),
        'canchaId': canchaId,
      },
    );
  }

  Future<void> eliminarPartido(int id) async {
    await _apiClient.delete('${ApiConstants.partidos}/$id');
  }

  Future<void> marcarDesempate({required int partidoId, required bool esDesempate}) async {
    await _apiClient.post(
      ApiConstants.marcarDesempate(partidoId),
      body: {'esDesempate': esDesempate},
    );
  }
}
