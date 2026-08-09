import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/configuracion_premio_model.dart';
import '../models/ganador_premio_model.dart';
import '../services/premios_service.dart';

final premiosServiceProvider = Provider<PremiosService>((ref) {
  return PremiosService(apiClient: ApiClient());
});

final configuracionPremiosProvider = FutureProvider.autoDispose
    .family<List<ConfiguracionPremioModel>, (int temporadaId, String ambito)>((ref, args) async {
  return ref.read(premiosServiceProvider).getConfiguracion(args.$1, args.$2);
});

final ganadoresJornadaProvider =
    FutureProvider.autoDispose.family<List<GanadorPremioModel>, int>((ref, jornadaId) async {
  return ref.read(premiosServiceProvider).getGanadoresJornada(jornadaId);
});

final ganadoresFinalesProvider =
    FutureProvider.autoDispose.family<List<GanadorPremioModel>, int>((ref, temporadaId) async {
  return ref.read(premiosServiceProvider).getGanadoresFinales(temporadaId);
});
