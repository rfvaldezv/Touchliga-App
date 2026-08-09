import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/temporada_model.dart';
import '../services/temporada_service.dart';

final temporadaServiceProvider = Provider<TemporadaService>((ref) {
  return TemporadaService(apiClient: ApiClient());
});

final temporadasProvider = FutureProvider.autoDispose<List<TemporadaModel>>((ref) async {
  final service = ref.read(temporadaServiceProvider);
  return service.getTemporadas();
});
