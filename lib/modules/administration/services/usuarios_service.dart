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
  /// Regresa la nueva contraseña temporal en texto plano (una sola
  /// vez) para que el admin se la comparta al participante. Si se
  /// manda [nuevaPassword], se usa esa; si no, el servidor genera
  /// una aleatoria.
  Future<String> restablecerPassword({required int usuarioId, String? nuevaPassword}) async {
    final response = await _apiClient.post(
      '/api/usuarios/$usuarioId/restablecer-password',
      body: nuevaPassword != null && nuevaPassword.trim().isNotEmpty
          ? {'nuevaPassword': nuevaPassword.trim()}
          : null,
    );
    return (response.data?['password'] ?? '').toString();
  }

  /// estatus: 1=Activo, 2=InactivoTemporal, 3=BajaDefinitiva
  Future<void> cambiarEstatus({required int usuarioId, required int estatus}) async {
    await _apiClient.put(
      '/api/usuarios/$usuarioId/estatus',
      body: {'usuarioId': usuarioId, 'estatus': estatus},
    );
  }

  /// Vincula (o desvincula, mandando parejaId: null) a este
  /// participante con otro como pareja/equipo -- solo visual.
  Future<void> asignarPareja({required int usuarioId, int? parejaId, String? nombreEquipo}) async {
    await _apiClient.put(
      '/api/usuarios/$usuarioId/pareja',
      body: {'parejaId': parejaId, 'nombreEquipo': nombreEquipo},
    );
  }

  /// Registra (o reemplaza) un segundo correo+contraseña que puede
  /// iniciar sesión COMO este mismo participante -- mismos
  /// pronósticos, mismos puntos, mismo Id.
  Future<void> agregarCredencialAlterna({
    required int usuarioId,
    required String correo,
    required String password,
  }) async {
    await _apiClient.put(
      '/api/usuarios/$usuarioId/credencial-alterna',
      body: {'correo': correo, 'password': password},
    );
  }

  Future<void> quitarCredencialAlterna({required int usuarioId}) async {
    await _apiClient.delete('/api/usuarios/$usuarioId/credencial-alterna');
  }

  /// Toma a un participante YA REGISTRADO y lo vincula como segundo
  /// acceso de otro, usando su correo+contraseña ya existentes.
  Future<void> vincularParticipanteExistente({
    required int usuarioObjetivoId,
    required int usuarioAVincularId,
  }) async {
    await _apiClient.put(
      '/api/usuarios/$usuarioObjetivoId/vincular-existente/$usuarioAVincularId',
    );
  }

  Future<void> desvincularParticipante({
    required int usuarioObjetivoId,
    required int usuarioVinculadoId,
  }) async {
    await _apiClient.delete(
      '/api/usuarios/$usuarioObjetivoId/vincular-existente/$usuarioVinculadoId',
    );
  }
}
