import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/providers/seleccion_provider.dart';
import '../../../core/network/api_client.dart';
import '../models/temporada_model.dart';
import '../services/temporada_service.dart';

final _temporadasPorLigaProvider =
    FutureProvider.family<List<TemporadaModel>, int>((ref, ligaId) async {
  final service = TemporadaService(apiClient: ApiClient());
  return service.getTemporadas(ligaId: ligaId);
});

class TemporadasSelectPage extends ConsumerWidget {
  const TemporadasSelectPage({super.key, required this.ligaId, required this.ligaNombre});

  final int ligaId;
  final String ligaNombre;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final temporadasAsync = ref.watch(_temporadasPorLigaProvider(ligaId));

    return Scaffold(
      appBar: AppBar(title: Text(ligaNombre)),
      body: temporadasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No fue posible cargar las temporadas.\n$e')),
        data: (temporadas) {
          if (temporadas.isEmpty) {
            return const Center(child: Text('Esta liga todavía no tiene temporadas.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: temporadas.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final temporada = temporadas[index];

              return Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: Text(temporada.nombre),
                  subtitle: Text(
                    [
                      temporada.descripcion.isNotEmpty ? temporada.descripcion : temporada.codigo,
                      if (temporada.cuota > 0) 'Cuota: \$${temporada.cuota.toStringAsFixed(2)}',
                    ].join(' · '),
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    ref.read(seleccionProvider.notifier).elegirLiga(ligaId, ligaNombre);
                    ref.read(seleccionProvider.notifier).elegirTemporada(temporada.id, temporada.nombre);

                    context.push(
                      '/leagues/$ligaId/temporadas/${temporada.id}/jornadas',
                      extra: temporada.nombre,
                    );
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
