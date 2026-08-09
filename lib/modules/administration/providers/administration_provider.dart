import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/jornada_model.dart';
import '../models/partido_model.dart';
import '../services/administration_service.dart';

final administrationServiceProvider = Provider<AdministrationService>((ref) {
  return AdministrationService(apiClient: ApiClient());
});

final jornadasAdminProvider = FutureProvider.autoDispose<List<JornadaModel>>((ref) async {
  final service = ref.read(administrationServiceProvider);
  return service.getJornadas();
});

final partidosPorJornadaProvider =
    FutureProvider.autoDispose.family<List<PartidoModel>, int>((ref, jornadaId) async {
  final service = ref.read(administrationServiceProvider);
  return service.getPartidosPorJornada(jornadaId);
});
