import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/providers/seleccion_provider.dart';
import '../../login/providers/auth_provider.dart';
import '../models/dashboard_model.dart';
import '../repositories/dashboard_repository.dart';
import '../services/dashboard_service.dart';

final dashboardServiceProvider = Provider<DashboardService>((ref) {
  return DashboardService(apiClient: ApiClient());
});

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(service: ref.read(dashboardServiceProvider));
});

final dashboardProvider = FutureProvider.autoDispose<DashboardModel>((ref) async {
  final repository = ref.read(dashboardRepositoryProvider);
  final user = ref.watch(authProvider).user;
  final seleccion = ref.watch(seleccionProvider);

  return repository.loadDashboard(
    usuarioId: user?.userId ?? 0,
    usuarioNombre: user?.name ?? '',
    seleccionLigaId: seleccion.ligaId,
    seleccionTemporadaId: seleccion.temporadaId,
    seleccionJornadaId: seleccion.jornadaId,
  );
});
