import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/posicion_model.dart';
import '../services/standings_service.dart';

final standingsServiceProvider = Provider<StandingsService>((ref) {
  return StandingsService(apiClient: ApiClient());
});

final standingsProvider =
    FutureProvider.autoDispose.family<List<PosicionModel>, int>((ref, temporadaId) async {
  final service = ref.read(standingsServiceProvider);

  return service.getTablaPosiciones(temporadaId);
});
