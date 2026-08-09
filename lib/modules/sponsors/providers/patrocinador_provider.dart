import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/patrocinador_model.dart';
import '../services/patrocinador_service.dart';

final patrocinadorServiceProvider = Provider<PatrocinadorService>((ref) {
  return PatrocinadorService(apiClient: ApiClient());
});

final patrocinadoresActivosProvider = FutureProvider.autoDispose<List<PatrocinadorModel>>((ref) async {
  return ref.read(patrocinadorServiceProvider).getActivos();
});

final patrocinadoresTodosProvider = FutureProvider.autoDispose<List<PatrocinadorModel>>((ref) async {
  return ref.read(patrocinadorServiceProvider).getAll();
});
