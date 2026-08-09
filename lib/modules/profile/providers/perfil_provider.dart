import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/mi_perfil_model.dart';
import '../services/perfil_service.dart';

final perfilServiceProvider = Provider<PerfilService>((ref) {
  return PerfilService(apiClient: ApiClient());
});

final miPerfilProvider = FutureProvider.autoDispose<MiPerfilModel>((ref) async {
  return ref.read(perfilServiceProvider).getMiPerfil();
});
