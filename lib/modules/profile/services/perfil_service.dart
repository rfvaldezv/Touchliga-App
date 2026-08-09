import '../../../core/network/api_client.dart';
import '../models/mi_perfil_model.dart';

class PerfilService {
  PerfilService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<MiPerfilModel> getMiPerfil() async {
    final response = await _apiClient.get('/api/perfil');
    return MiPerfilModel.fromJson(response.data!);
  }

  Future<void> actualizarPerfil({
    DateTime? fechaNacimiento,
    int? equipoFavoritoId,
    String? nickname,
    String? fotoUrl,
  }) async {
    await _apiClient.put(
      '/api/perfil',
      body: {
        'fechaNacimiento': fechaNacimiento?.toIso8601String(),
        'equipoFavoritoId': equipoFavoritoId,
        'nickname': nickname,
        'fotoUrl': fotoUrl,
      },
    );
  }
}
