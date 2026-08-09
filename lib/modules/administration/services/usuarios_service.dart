import '../../../core/network/api_client.dart';
import '../models/rol_model.dart';
import '../models/usuario_admin_model.dart';

class UsuariosService {
  UsuariosService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<UsuarioAdminModel>> getUsuarios() async {
    final response = await _apiClient.getList('/api/usuarios');
    return response.data!
        .map((json) => UsuarioAdminModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<List<RolModel>> getRoles() async {
    final response = await _apiClient.getList('/api/usuarios/roles');
    return response.data!
        .map((json) => RolModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<int> crearUsuario({
    required String nombre,
    required String apellidos,
    required String telefono,
    required String correo,
    required String password,
    required String sexo,
    required int invitadoPorId,
    required int ciudadId,
    required int paisId,
    required int estadoId,
  }) async {
    return _apiClient.postForValue<int>(
      '/api/usuarios',
      body: {
        'nombre': nombre,
        'apellidos': apellidos,
        'telefono': telefono,
        'correo': correo,
        'password': password,
        'sexo': sexo,
        'invitadoPorId': invitadoPorId,
        'ciudadId': ciudadId,
        'paisId': paisId,
        'estadoId': estadoId,
      },
    );
  }

  Future<void> asignarRol({required int usuarioId, required int rolId}) async {
    await _apiClient.post('/api/usuarios/$usuarioId/roles/$rolId');
  }

  Future<void> editarInfo({
    required int usuarioId,
    required String nombre,
    required String apellidos,
    required String telefono,
    required String correo,
    int? ciudadId,
    int? paisId,
    int? estadoId,
  }) async {
    await _apiClient.put(
      '/api/usuarios/$usuarioId/info',
      body: {
        'nombre': nombre,
        'apellidos': apellidos,
        'telefono': telefono,
        'correo': correo,
        'ciudadId': ciudadId,
        'paisId': paisId,
        'estadoId': estadoId,
      },
    );
  }

  /// Regresa la nueva contraseña temporal en texto plano (una sola
  /// vez) para que el admin se la comparta al participante.
  Future<String> restablecerPassword({required int usuarioId}) async {
    final response = await _apiClient.post('/api/usuarios/$usuarioId/restablecer-password');
    return (response.data?['password'] ?? '').toString();
  }

  /// estatus: 1=Activo, 2=InactivoTemporal, 3=BajaDefinitiva
  Future<void> cambiarEstatus({required int usuarioId, required int estatus}) async {
    await _apiClient.put(
      '/api/usuarios/$usuarioId/estatus',
      body: {'usuarioId': usuarioId, 'estatus': estatus},
    );
  }
}
