import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_route_names.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/providers/seleccion_provider.dart';
import '../../administration/models/jornada_model.dart';
import '../../administration/services/administration_service.dart';

final _jornadasPorTemporadaProvider =
    FutureProvider.family<List<JornadaModel>, int>((ref, temporadaId) async {
  final service = AdministrationService(apiClient: ApiClient());
  return service.getJornadas(temporadaId: temporadaId);
});

class JornadasSelectPage extends ConsumerWidget {
  const JornadasSelectPage({
    super.key,
    required this.temporadaId,
    required this.temporadaNombre,
  });

  final int temporadaId;
  final String temporadaNombre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jornadasAsync = ref.watch(_jornadasPorTemporadaProvider(temporadaId));

    return Scaffold(
      appBar: AppBar(title: Text(temporadaNombre)),
      body: jornadasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No fue posible cargar las jornadas.\n$e')),
        data: (jornadas) {
          if (jornadas.isEmpty) {
            return const Center(child: Text('Esta temporada todavía no tiene jornadas.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: jornadas.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final jornada = jornadas[index];

              return Card(
                child: ListTile(
                  leading: Icon(
                    jornada.cerrada ? Icons.lock_outline : Icons.sports_soccer,
                    color: jornada.cerrada ? Colors.grey : null,
                  ),
                  title: Text(jornada.nombre),
                  subtitle: Text(
                    jornada.cerrada ? 'Cerrada — solo consulta' : 'Abierta para pronósticos',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ref.read(seleccionProvider.notifier).elegirJornada(jornada.id, jornada.nombre);

                    // Al elegir jornada, volvemos al inicio: ahí ya se
                    // reflejará la jornada activa en el Dashboard, y
                    // Pronósticos/Tabla usarán esta misma selección.
                    context.go(AppRouteNames.home);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
