import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/estadisticas_participante_model.dart';
import '../services/estadisticas_service.dart';

final estadisticasServiceProvider = Provider<EstadisticasService>((ref) {
  return EstadisticasService(apiClient: ApiClient());
});

final misEstadisticasProvider = FutureProvider.autoDispose
    .family<EstadisticasParticipanteModel, int>((ref, temporadaId) async {
  return ref.read(estadisticasServiceProvider).getMisEstadisticas(temporadaId);
});
