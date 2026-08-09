import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants/asset_paths.dart';
import '../../../app/router/app_route_names.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../shared/design_system/tokens/app_colors.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/design_system/widgets/advertising/sponsor_banner.dart';
import '../../../shared/providers/seleccion_provider.dart';
import '../providers/standings_provider.dart';

class StandingsPage extends ConsumerWidget {
  const StandingsPage({super.key, this.temporadaId = 1});

  final int temporadaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final temporadaSeleccionada = ref.watch(seleccionProvider).temporadaId;
    final idEfectivo = temporadaSeleccionada ?? temporadaId;
    final posicionesAsync = ref.watch(standingsProvider(idEfectivo));

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AssetPaths.logoIsotipo, height: 24),
            const SizedBox(width: 8),
            const Text('Tabla de posiciones'),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: posicionesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: AppSpacing.md),
                Text('No fue posible cargar la tabla.\n$error', textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () => ref.invalidate(standingsProvider(idEfectivo)),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (posiciones) {
          if (posiciones.isEmpty) {
            return const Center(
              child: Text('Todavía no hay pronósticos calificados en esta temporada.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(standingsProvider(idEfectivo).future),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: posiciones.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final posicion = posiciones[index];

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: switch (index) {
                        0 => const Color(0xFFFFD700), // oro
                        1 => const Color(0xFFC0C0C0), // plata
                        2 => const Color(0xFFCD7F32), // bronce
                        _ => Theme.of(context).colorScheme.surfaceContainerHighest,
                      },
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: index <= 2 ? Colors.black87 : null,
                        ),
                      ),
                    ),
                    title: Text(posicion.nombre),
                    subtitle: Text(
                      '${posicion.aciertos} aciertos de ${posicion.pronosticos} pronósticos',
                    ),
                    trailing: Text(
                      '${posicion.puntos} pts',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.secondaryDark,
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
          ),
          const SponsorBanner(),
        ],
      ),
      bottomNavigationBar: AppBottomNavigation(
        index: 2,
        onTap: (index) {
          switch (index) {
            case 0:
              context.go(AppRouteNames.home);
              break;
            case 1:
              context.go(AppRouteNames.messages);
              break;
            case 2:
              context.go(AppRouteNames.ganadores);
              break;
            case 3:
              context.go(AppRouteNames.misEstadisticas);
              break;
            case 4:
              context.go(AppRouteNames.profile);
              break;
          }
        },
      ),
    );
  }
}
