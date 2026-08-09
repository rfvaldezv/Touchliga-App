import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_route_names.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/design_system/tokens/app_typography.dart';
import '../models/league_model.dart';
import '../providers/league_provider.dart';

class LeaguesPage extends ConsumerWidget {
  const LeaguesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final leaguesAsync = ref.watch(leaguesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis ligas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouteNames.home),
        ),
      ),
      body: leaguesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
                const SizedBox(height: AppSpacing.md),
                Text(
                  'No fue posible cargar tus ligas.\n$error',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.md),
                FilledButton(
                  onPressed: () => ref.invalidate(leaguesProvider),
                  child: const Text('Reintentar'),
                ),
              ],
            ),
          ),
        ),
        data: (leagues) {
          if (leagues.isEmpty) {
            return Center(
              child: Text(
                'Todavía no perteneces a ninguna liga.',
                style: AppTypography.body,
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => ref.refresh(leaguesProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: leagues.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) => _LeagueCard(league: leagues[index]),
            ),
          );
        },
      ),
    );
  }
}

class _LeagueCard extends StatelessWidget {
  const _LeagueCard({required this.league});

  final LeagueModel league;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          child: Text(
            league.nombre.isNotEmpty ? league.nombre[0].toUpperCase() : '?',
          ),
        ),
        title: Text(league.nombre, style: AppTypography.subtitle),
        subtitle: Text(
          league.descripcion.isNotEmpty ? league.descripcion : league.codigo,
        ),
        trailing: Icon(
          league.activo ? Icons.check_circle : Icons.pause_circle_outline,
          color: league.activo ? Colors.green : Colors.grey,
        ),
        onTap: () => context.push(
          '/leagues/${league.id}/temporadas',
          extra: league.nombre,
        ),
      ),
    );
  }
}
