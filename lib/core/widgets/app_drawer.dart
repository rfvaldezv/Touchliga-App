import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/constants/asset_paths.dart';
import '../../app/router/app_route_names.dart';
import '../../modules/login/providers/auth_provider.dart';
import '../../shared/design_system/tokens/app_colors.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  /// Solo cosmético: oculta el acceso a Administración si el usuario
  /// no tiene el rol. La seguridad real vive en el backend
  /// ([Authorize(Roles = ...)] en cada endpoint) — esto es nada más
  /// para no confundir a un jugador normal con una opción que de
  /// todas formas le rebotaría con 403.
  bool _esAdminOCapturador(WidgetRef ref) {
    final roles = ref.read(authProvider).user?.roles ?? const [];
    return roles.contains('Administrador') || roles.contains('Capturador');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void navigate(String route) {
      Navigator.of(context).pop();
      context.go(route);
    }

    return Drawer(
      child: ListView(
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(color: AppColors.primary),
            child: Center(
              child: Image.asset(AssetPaths.logoBlanco, height: 70),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.home),
            title: const Text("Inicio"),
            onTap: () => navigate(AppRouteNames.home),
          ),

          ListTile(
            leading: const Icon(Icons.emoji_events_outlined),
            title: const Text("Mis ligas"),
            onTap: () => navigate(AppRouteNames.leagues),
          ),

          ListTile(
            leading: const Icon(Icons.sports_soccer),
            title: const Text("Pronósticos"),
            onTap: () => navigate(AppRouteNames.predictions),
          ),

          ListTile(
            leading: const Icon(Icons.emoji_events),
            title: const Text("Clasificación"),
            onTap: () => navigate(AppRouteNames.standings),
          ),

          ListTile(
            leading: const Icon(Icons.campaign_outlined),
            title: const Text("Anuncios"),
            onTap: () => navigate(AppRouteNames.announcements),
          ),

          ListTile(
            leading: const Icon(Icons.chat_bubble_outline),
            title: const Text("Mensajes"),
            onTap: () => navigate(AppRouteNames.messages),
          ),

          ListTile(
            leading: const Icon(Icons.credit_card),
            title: const Text("Mi pago"),
            onTap: () => navigate(AppRouteNames.miPago),
          ),

          ListTile(
            leading: const Icon(Icons.emoji_events),
            title: const Text("Premios y ganadores"),
            onTap: () => navigate(AppRouteNames.ganadores),
          ),

          ListTile(
            leading: const Icon(Icons.insights),
            title: const Text("Mis estadísticas"),
            onTap: () => navigate(AppRouteNames.misEstadisticas),
          ),

          ListTile(
            leading: const Icon(Icons.person),
            title: const Text("Perfil"),
            onTap: () => navigate(AppRouteNames.profile),
          ),

          if (_esAdminOCapturador(ref)) ...[
            const Divider(),

            ListTile(
              leading: const Icon(Icons.admin_panel_settings_outlined),
              title: const Text("Operación"),
              onTap: () => navigate(AppRouteNames.administration),
            ),
          ],

          const Divider(),

          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text("Cerrar sesión"),
            onTap: () {
              Navigator.of(context).pop();
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
    );
  }
}
