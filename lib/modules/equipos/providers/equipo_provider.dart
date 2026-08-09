import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/equipo_model.dart';
import '../services/equipo_service.dart';

final equipoServiceProvider = Provider<EquipoService>((ref) {
  return EquipoService(apiClient: ApiClient());
});

final equiposProvider = FutureProvider.autoDispose<List<EquipoModel>>((ref) async {
  final service = ref.read(equipoServiceProvider);
  return service.getEquipos();
});
