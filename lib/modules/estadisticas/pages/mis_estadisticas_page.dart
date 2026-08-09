import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_route_names.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/widgets/compartir_dialog.dart';
import '../../temporadas/providers/temporada_provider.dart';
import '../models/estadisticas_participante_model.dart';
import '../providers/estadisticas_provider.dart';
import '../widgets/dona_aciertos.dart';

/// Dashboard personal del participante — estadísticas divertidas y
/// compartibles, pensadas para picar la curiosidad y el reto amistoso
/// entre amigos (fase 1 del roadmap de BI).
class MisEstadisticasPage extends ConsumerStatefulWidget {
  const MisEstadisticasPage({super.key});

  @override
  ConsumerState<MisEstadisticasPage> createState() => _MisEstadisticasPageState();
}

class _MisEstadisticasPageState extends ConsumerState<MisEstadisticasPage> {
  int? _temporadaId;

  @override
  Widget build(BuildContext context) {
    final temporadasAsync = ref.watch(temporadasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis estadísticas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouteNames.home),
        ),
      ),
      body: temporadasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No fue posible cargar temporadas.\n$e')),
        data: (temporadas) {
          if (temporadas.isEmpty) {
            return const Center(child: Text('Todavía no hay temporadas.'));
          }

          _temporadaId ??= temporadas.first.id;

          final estadisticasAsync = ref.watch(misEstadisticasProvider(_temporadaId!));

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(misEstadisticasProvider(_temporadaId!)),
            child: estadisticasAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('No fue posible cargar tus estadísticas.\n$e')),
              data: (stats) => ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  _TarjetaRacha(stats: stats),
                  const SizedBox(height: AppSpacing.md),
                  _TarjetaTendencia(stats: stats),
                  const SizedBox(height: AppSpacing.md),
                  _TarjetaMovimiento(stats: stats),
                  const SizedBox(height: AppSpacing.md),
                  _TarjetaPodio(stats: stats),
                  const SizedBox(height: AppSpacing.md),
                  _TarjetaAciertos(stats: stats),
                  const SizedBox(height: AppSpacing.md),
                  if (stats.equipoFavoritoNombre != null) _TarjetaEquipoFavorito(stats: stats),
                  const SizedBox(height: AppSpacing.md),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TarjetaBase extends StatelessWidget {
  const _TarjetaBase({
    required this.icono,
    required this.titulo,
    required this.child,
    required this.mensajeCompartir,
  });

  final String icono;
  final String titulo;
  final Widget child;
  final String mensajeCompartir;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icono, style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(titulo, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                Consumer(
                  builder: (context, ref, _) => IconButton(
                    icon: const Icon(Icons.share_outlined, size: 20),
                    tooltip: 'Compartir',
                    onPressed: () => mostrarDialogoCompartir(context, ref, mensajeSugerido: mensajeCompartir),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}

class _TarjetaRacha extends StatelessWidget {
  const _TarjetaRacha({required this.stats});

  final EstadisticasParticipanteModel stats;

  @override
  Widget build(BuildContext context) {
    final racha = stats.rachaActual;
    final texto = racha == 0
        ? 'Todavía no arrancas racha — ¡esta jornada es tu oportunidad!'
        : '¡Llevas $racha jornada${racha == 1 ? '' : 's'} seguida${racha == 1 ? '' : 's'} sumando puntos!';

    return _TarjetaBase(
      icono: '🔥',
      titulo: 'Racha actual',
      mensajeCompartir: '🔥 $texto ¿Quién me alcanza?',
      child: Text(texto, style: const TextStyle(fontSize: 15)),
    );
  }
}

class _TarjetaTendencia extends StatelessWidget {
  const _TarjetaTendencia({required this.stats});

  final EstadisticasParticipanteModel stats;

  @override
  Widget build(BuildContext context) {
    final (emoji, color, texto) = switch (stats.tendencia) {
      'Mejorando' => ('🟢', Colors.green, '¡Vas mejorando jornada tras jornada!'),
      'Bajando' => ('🔴', Colors.red, 'Bajaste un poco la última jornada — ¡a remontar!'),
      _ => ('🟡', Colors.orange, 'Te mantienes estable.'),
    };

    return _TarjetaBase(
      icono: '📈',
      titulo: 'Tendencia',
      mensajeCompartir: '$emoji Mi tendencia esta temporada: $texto',
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 28)),
          const SizedBox(width: 12),
          Expanded(child: Text(texto, style: TextStyle(fontSize: 15, color: color))),
        ],
      ),
    );
  }
}

class _TarjetaMovimiento extends StatelessWidget {
  const _TarjetaMovimiento({required this.stats});

  final EstadisticasParticipanteModel stats;

  @override
  Widget build(BuildContext context) {
    final mov = stats.movimientoPosiciones;
    final (icono, color, texto) = mov > 0
        ? (Icons.arrow_upward, Colors.green, 'Subiste $mov lugar${mov == 1 ? '' : 'es'} en la tabla')
        : mov < 0
            ? (Icons.arrow_downward, Colors.red, 'Bajaste ${mov.abs()} lugar${mov.abs() == 1 ? '' : 'es'} en la tabla')
            : (Icons.remove, Colors.grey, 'Te mantuviste en el mismo lugar');

    return _TarjetaBase(
      icono: '📊',
      titulo: 'Movimiento en la tabla',
      mensajeCompartir: '📊 Ahora estoy en el lugar #${stats.posicionActual} — $texto',
      child: Row(
        children: [
          Icon(icono, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Vas en el lugar #${stats.posicionActual} — $texto',
              style: const TextStyle(fontSize: 15),
            ),
          ),
        ],
      ),
    );
  }
}

class _TarjetaPodio extends StatelessWidget {
  const _TarjetaPodio({required this.stats});

  final EstadisticasParticipanteModel stats;

  @override
  Widget build(BuildContext context) {
    final veces = stats.vecesEnPodio;
    final texto = veces == 0
        ? 'Todavía no llegas al podio — ¡esta jornada puede ser la primera!'
        : 'Has quedado en el top 3 de la jornada $veces vez${veces == 1 ? '' : 'es'}';

    return _TarjetaBase(
      icono: '🥇',
      titulo: 'Medallero personal',
      mensajeCompartir: '🥇 $texto',
      child: Text(texto, style: const TextStyle(fontSize: 15)),
    );
  }
}

class _TarjetaAciertos extends StatelessWidget {
  const _TarjetaAciertos({required this.stats});

  final EstadisticasParticipanteModel stats;

  @override
  Widget build(BuildContext context) {
    final total = stats.totalPronosticos;
    final pct = total > 0 ? ((stats.pronosticosAcertados / total) * 100).round() : 0;

    return _TarjetaBase(
      icono: '🍩',
      titulo: 'Mis aciertos',
      mensajeCompartir: '🍩 Llevo $pct% de mis pronósticos acertados esta temporada 🎯',
      child: DonaAciertos(
        acertados: stats.pronosticosAcertados,
        fallados: stats.pronosticosFallados,
      ),
    );
  }
}

/// Racha reciente del equipo favorito registrado en Perfil — una
/// flecha por partido: hacia arriba si ganó, horizontal si empató,
/// hacia abajo si perdió. Se lee de izquierda (más viejo) a derecha
/// (más reciente).
class _TarjetaEquipoFavorito extends StatelessWidget {
  const _TarjetaEquipoFavorito({required this.stats});

  final EstadisticasParticipanteModel stats;

  @override
  Widget build(BuildContext context) {
    final nombre = stats.equipoFavoritoNombre!;
    final forma = stats.formaEquipoFavorito;

    // El backend manda "mas reciente primero" -- se invierte para
    // leer la racha de izquierda a derecha en orden cronologico.
    final formaCronologica = forma.reversed.toList();

    final ganados = forma.where((r) => r == 'G').length;
    final empatados = forma.where((r) => r == 'E').length;
    final perdidos = forma.where((r) => r == 'P').length;

    final texto = forma.isEmpty
        ? '$nombre todavía no tiene partidos jugados registrados.'
        : 'De sus últimos ${forma.length}: $nombre ganó $ganados, empató $empatados y perdió $perdidos';

    return _TarjetaBase(
      icono: '⚽',
      titulo: 'Tu equipo favorito: $nombre',
      mensajeCompartir: '⚽ $texto',
      child: forma.isEmpty
          ? Text(texto, style: const TextStyle(fontSize: 15))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: formaCronologica.map((resultado) {
                    final (icono, color) = switch (resultado) {
                      'G' => (Icons.trending_up, Colors.green),
                      'P' => (Icons.trending_down, Colors.red),
                      _ => (Icons.trending_flat, Colors.orange),
                    };
                    return Icon(icono, color: color, size: 32);
                  }).toList(),
                ),
                const SizedBox(height: 8),
                Text(texto, style: const TextStyle(fontSize: 13, color: Colors.grey)),
              ],
            ),
    );
  }
}
