import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../modules/dashboard/pages/dashboard_page.dart';
import '../../modules/administration/pages/admin_jornadas_page.dart';
import '../../modules/administration/pages/admin_estados_page.dart';
import '../../modules/administration/pages/admin_ciudades_page.dart';
import '../../modules/administration/pages/admin_jornada_detail_page.dart';
import '../../modules/administration/pages/admin_usuarios_page.dart';
import '../../modules/sponsors/pages/admin_patrocinadores_page.dart';
import '../../modules/pagos/pages/admin_pagos_page.dart';
import '../../modules/equipos/pages/admin_equipos_page.dart';
import '../../modules/leagues/pages/admin_ligas_page.dart';
import '../../modules/pagos/pages/mi_pago_page.dart';
import '../../modules/pagos/pages/cuenta_corriente_page.dart';
import '../../modules/pagos/pages/finanzas_dashboard_page.dart';
import '../../modules/premios/pages/admin_configuracion_premios_page.dart';
import '../../modules/premios/pages/ganadores_page.dart';
import '../../modules/estadisticas/pages/mis_estadisticas_page.dart';
import '../../modules/reportes/pages/detalle_jornada_page.dart';
import '../../modules/reportes/pages/ranking_page.dart';
import '../../modules/temporadas/pages/admin_temporadas_page.dart';
import '../../shared/pages/admin_catalogo_page.dart';
import '../../modules/communication/pages/anuncios_page.dart';
import '../../modules/communication/pages/mensajes_page.dart';
import '../../modules/communication/pages/conversacion_page.dart';
import '../../modules/jornadas/pages/jornadas_select_page.dart';
import '../../modules/leagues/pages/leagues_page.dart';
import '../../modules/temporadas/pages/temporadas_select_page.dart';
import '../../modules/login/pages/login_page.dart';
import '../../modules/login/providers/auth_provider.dart';
import '../../modules/login/providers/login_state.dart';
import '../../modules/predictions/pages/prediction_page.dart';
import '../../modules/profile/pages/profile_page.dart';
import '../../modules/results/pages/results_page.dart';
import '../../modules/splash/pages/splash_page.dart';
import '../../modules/standings/pages/standings_page.dart';
import 'app_route_names.dart';

/// Traduce los cambios del [authProvider] en notificaciones que GoRouter
/// pueda escuchar. Sin esto, `redirect` solo se evalúa al navegar y nunca
/// reacciona cuando `checkSession()` o `login()` cambian el estado de forma
/// asíncrona (la app se queda "atorada" en el splash o en el login).
class _AuthRouterRefreshNotifier extends ChangeNotifier {
  _AuthRouterRefreshNotifier(Ref ref) {
    ref.listen<LoginState>(authProvider, (previous, next) {
      if (previous?.authenticated != next.authenticated ||
          previous?.loading != next.loading) {
        notifyListeners();
      }
    });
  }
}

final _routerRefreshProvider = Provider<_AuthRouterRefreshNotifier>((ref) {
  return _AuthRouterRefreshNotifier(ref);
});

final appRouterProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = ref.watch(_routerRefreshProvider);

  return GoRouter(
    debugLogDiagnostics: true,
    initialLocation: AppRouteNames.splash,
    refreshListenable: refreshNotifier,

    redirect: (context, state) {
      final auth = ref.read(authProvider);

      final isSplash = state.matchedLocation == AppRouteNames.splash;
      final isLogin = state.matchedLocation == AppRouteNames.login;

      // Mientras se valida la sesión guardada, no navegar todavía.
      if (auth.loading) {
        return isSplash ? null : AppRouteNames.splash;
      }

      if (!auth.authenticated) {
        return isLogin ? null : AppRouteNames.login;
      }

      if (auth.authenticated && (isLogin || isSplash)) {
        return AppRouteNames.home;
      }

      return null;
    },

    routes: [
      GoRoute(
        path: AppRouteNames.splash,
        name: 'splash',
        builder: (context, state) => const SplashPage(),
      ),

      GoRoute(
        path: AppRouteNames.login,
        name: 'login',
        builder: (context, state) => const LoginPage(),
      ),

      GoRoute(
        path: AppRouteNames.home,
        name: 'home',
        builder: (context, state) => const DashboardPage(),
      ),

      GoRoute(
        path: AppRouteNames.administration,
        name: 'administration',
        builder: (context, state) => const AdminJornadasPage(),
        routes: [
          GoRoute(
            path: 'jornadas/:id',
            name: 'admin-jornada-detail',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              return AdminJornadaDetailPage(jornadaId: id);
            },
          ),
          GoRoute(
            path: 'usuarios',
            name: 'admin-usuarios',
            builder: (context, state) => const AdminUsuariosPage(),
          ),
          GoRoute(
            path: 'patrocinadores',
            name: 'admin-patrocinadores',
            builder: (context, state) => const AdminPatrocinadoresPage(),
          ),
          GoRoute(
            path: 'finanzas',
            name: 'admin-finanzas',
            builder: (context, state) => const FinanzasDashboardPage(),
          ),
          GoRoute(
            path: 'pagos',
            name: 'admin-pagos',
            builder: (context, state) => const AdminPagosPage(),
            routes: [
              GoRoute(
                path: 'cuenta-corriente/:usuarioId',
                name: 'cuenta-corriente',
                builder: (context, state) {
                  final usuarioId = int.parse(state.pathParameters['usuarioId']!);
                  return CuentaCorrientePage(usuarioId: usuarioId);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'premios',
            name: 'admin-configuracion-premios',
            builder: (context, state) => const AdminConfiguracionPremiosPage(),
          ),
          GoRoute(
            path: 'equipos',
            name: 'admin-equipos',
            builder: (context, state) => const AdminEquiposPage(),
          ),
          GoRoute(
            path: 'ligas',
            name: 'admin-ligas',
            builder: (context, state) => const AdminLigasPage(),
          ),
          GoRoute(
            path: 'detalle-jornada',
            name: 'detalle-jornada',
            builder: (context, state) => const DetalleJornadaPage(),
          ),
          GoRoute(
            path: 'ranking',
            name: 'ranking',
            builder: (context, state) => const RankingPage(),
          ),
          GoRoute(
            path: 'temporadas',
            name: 'admin-temporadas',
            builder: (context, state) => const AdminTemporadasPage(),
          ),
          GoRoute(
            path: 'canchas',
            name: 'admin-canchas',
            builder: (context, state) => const AdminCatalogoPage(
              titulo: 'Canchas',
              endpoint: '/api/canchas',
            ),
          ),
          GoRoute(
            path: 'paises',
            name: 'admin-paises',
            builder: (context, state) => const AdminCatalogoPage(
              titulo: 'Países',
              endpoint: '/api/paises',
            ),
          ),
          GoRoute(
            path: 'estados',
            name: 'admin-estados',
            builder: (context, state) => const AdminEstadosPage(),
          ),
          GoRoute(
            path: 'ciudades',
            name: 'admin-ciudades',
            builder: (context, state) => const AdminCiudadesPage(),
          ),
        ],
      ),

      GoRoute(
        path: AppRouteNames.announcements,
        name: 'announcements',
        builder: (context, state) => const AnunciosPage(),
      ),

      GoRoute(
        path: AppRouteNames.messages,
        name: 'messages',
        builder: (context, state) => const MensajesPage(),
        routes: [
          GoRoute(
            path: ':id',
            name: 'conversacion',
            builder: (context, state) {
              final id = int.parse(state.pathParameters['id']!);
              final nombre = state.extra as String?;
              return ConversacionPage(otroUsuarioId: id, otroNombre: nombre);
            },
          ),
        ],
      ),

      GoRoute(
        path: AppRouteNames.miPago,
        name: 'mi-pago',
        builder: (context, state) => const MiPagoPage(),
      ),

      GoRoute(
        path: AppRouteNames.ganadores,
        name: 'ganadores',
        builder: (context, state) => const GanadoresPage(),
      ),

      GoRoute(
        path: AppRouteNames.misEstadisticas,
        name: 'mis-estadisticas',
        builder: (context, state) => const MisEstadisticasPage(),
      ),

      GoRoute(
        path: AppRouteNames.leagues,
        name: 'leagues',
        builder: (context, state) => const LeaguesPage(),
        routes: [
          GoRoute(
            path: ':ligaId/temporadas',
            name: 'temporadas-select',
            builder: (context, state) {
              final ligaId = int.parse(state.pathParameters['ligaId']!);
              final ligaNombre = state.extra as String? ?? 'Liga';
              return TemporadasSelectPage(ligaId: ligaId, ligaNombre: ligaNombre);
            },
            routes: [
              GoRoute(
                path: ':temporadaId/jornadas',
                name: 'jornadas-select',
                builder: (context, state) {
                  final temporadaId = int.parse(state.pathParameters['temporadaId']!);
                  final temporadaNombre = state.extra as String? ?? 'Temporada';
                  return JornadasSelectPage(
                    temporadaId: temporadaId,
                    temporadaNombre: temporadaNombre,
                  );
                },
              ),
            ],
          ),
        ],
      ),

      GoRoute(
        path: AppRouteNames.predictions,
        name: 'predictions',
        builder: (context, state) => const PredictionPage(),
      ),

      GoRoute(
        path: AppRouteNames.results,
        name: 'results',
        builder: (context, state) => const ResultsPage(),
      ),

      GoRoute(
        path: AppRouteNames.standings,
        name: 'standings',
        builder: (context, state) => const StandingsPage(),
      ),

      GoRoute(
        path: AppRouteNames.profile,
        name: 'profile',
        builder: (context, state) => const ProfilePage(),
      ),
    ],

    errorBuilder: (context, state) {
      return Scaffold(
        appBar: AppBar(title: const Text('Página no encontrada')),
        body: Center(
          child: Text(
            'La ruta "${state.uri}" no existe.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    },
  );
});
