import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/rol_model.dart';
import '../models/usuario_admin_model.dart';
import '../services/usuarios_service.dart';

final usuariosServiceProvider = Provider<UsuariosService>((ref) {
  return UsuariosService(apiClient: ApiClient());
});

final usuariosProvider = FutureProvider.autoDispose<List<UsuarioAdminModel>>((ref) async {
  return ref.read(usuariosServiceProvider).getUsuarios();
});

final rolesProvider = FutureProvider.autoDispose<List<RolModel>>((ref) async {
  return ref.read(usuariosServiceProvider).getRoles();
});
