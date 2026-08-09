import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants/asset_paths.dart';
import '../../../app/router/app_route_names.dart';
import '../../../core/widgets/app_bottom_navigation.dart';
import '../../../core/widgets/app_drawer.dart';
import '../../../shared/design_system/widgets/advertising/sponsor_banner.dart';
import '../../login/providers/auth_provider.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/dashboard_body.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboardAsync = ref.watch(dashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AssetPaths.logoIsotipo, height: 28),
            const SizedBox(width: 8),
            const Text('Touchliga'),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Cerrar sesión',
            onPressed: () => ref.read(authProvider.notifier).logout(),
          ),
        ],
      ),

      drawer: const AppDrawer(),

      body: Stack(
        fit: StackFit.expand,
        children: [
          // Fondo de marca, sutil — un overlay blanco semi-transparente
          // encima para que las tarjetas y el texto sigan leyéndose
          // bien sin importar qué tan clara/oscura salga la imagen.
          Image.asset(AssetPaths.homeBackground, fit: BoxFit.cover),
          Container(color: Colors.white.withValues(alpha: 0.88)),

          SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: dashboardAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator()),
                    error: (error, stackTrace) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                            const SizedBox(height: 12),
                            Text(
                              'No fue posible cargar el panel.\n$error',
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),
                            FilledButton(
                              onPressed: () => ref.invalidate(dashboardProvider),
                              child: const Text('Reintentar'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (model) => RefreshIndicator(
                      onRefresh: () => ref.refresh(dashboardProvider.future),
                      child: DashboardBody(model: model),
                    ),
                  ),
                ),
                const SponsorBanner(),
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: AppBottomNavigation(
        index: 0,
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
