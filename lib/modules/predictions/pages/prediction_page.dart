import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/constants/asset_paths.dart';
import '../../../app/router/app_route_names.dart';
import '../../../core/network/api_client.dart';
import '../../../shared/design_system/tokens/app_colors.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/providers/seleccion_provider.dart';
import '../../administration/models/jornada_model.dart';
import '../../administration/providers/administration_provider.dart';
import '../../administration/services/administration_service.dart';
import '../models/match_prediction_model.dart';
import '../providers/prediction_provider.dart';
import '../widgets/prediction_list.dart';

class PredictionPage extends ConsumerStatefulWidget {
  const PredictionPage({super.key, this.jornadaId = 1});

  final int jornadaId;

  @override
  ConsumerState<PredictionPage> createState() => _PredictionPageState();
}

class _PredictionPageState extends ConsumerState<PredictionPage> {
  late int _jornadaId;

  @override
  void initState() {
    super.initState();

    // Si el usuario ya eligió una jornada en el selector (Ligas →
    // Temporadas → Jornadas), se usa esa de inmediato. Si no, se
    // busca automáticamente la jornada abierta más reciente (la de
    // número más alto que no esté cerrada) en vez de caer en un
    // valor fijo — así "Pronósticos" desde el Dashboard siempre
    // aterriza en la jornada correcta sin pasos extra.
    final jornadaGuardada = ref.read(seleccionProvider).jornadaId;

    if (jornadaGuardada != null) {
      _jornadaId = jornadaGuardada;
      Future.microtask(_cargar);
    } else {
      _jornadaId = widget.jornadaId;
      Future.microtask(_elegirJornadaMasReciente);
    }
  }

  Future<void> _elegirJornadaMasReciente() async {
    try {
      final service = AdministrationService(apiClient: ApiClient());
      final todas = await service.getJornadas();

      if (todas.isEmpty) {
        await _cargar();
        return;
      }

      // La más reciente por número, sin importar si está abierta o
      // cerrada — así la pantalla siempre aterriza en la jornada que
      // se está jugando ahora mismo (o la que acaba de cerrar),
      // porque así es como se organiza el juego: por jornada.
      final ordenadas = [...todas]..sort((a, b) => b.numero.compareTo(a.numero));
      final elegida = ordenadas.first;

      if (!mounted) return;

      setState(() => _jornadaId = elegida.id);
      ref.read(seleccionProvider.notifier).elegirJornada(elegida.id, elegida.nombre);
    } catch (_) {
      // Si falla la búsqueda automática, seguimos con el valor por
      // default en vez de dejar la pantalla sin cargar nada.
    }

    await _cargar();
  }

  Future<void> _cargar() async {
    await ref.read(predictionProvider.notifier).load(jornadaId: _jornadaId);
  }

  void _cambiarJornada(JornadaModel jornada) {
    if (jornada.id == _jornadaId) return;

    setState(() => _jornadaId = jornada.id);

    ref.read(seleccionProvider.notifier).elegirJornada(jornada.id, jornada.nombre);

    _cargar();
  }

  Future<void> _save() async {
    final ok = await ref.read(predictionProvider.notifier).save();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Pronósticos guardados correctamente.'
              : 'Faltan partidos por capturar.',
        ),
      ),
    );
  }

  void _updateMatch(MatchPredictionModel match) {
    ref.read(predictionProvider.notifier).updateMatch(match);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(predictionProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AssetPaths.logoIsotipo, height: 24),
            const SizedBox(width: 8),
            const Text('Pronósticos'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouteNames.home),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.emoji_events_outlined),
            tooltip: 'Ver clasificación',
            onPressed: () => context.go(AppRouteNames.standings),
          ),
        ],
      ),
      body: Column(
        children: [
          _JornadaTabs(
            jornadaSeleccionadaId: _jornadaId,
            onSeleccionar: _cambiarJornada,
          ),

          if (state.hasValue)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Jornada ${state.value!.round}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
          const SizedBox(height: 4),

          Expanded(
            child: state.when(
              loading: () => const Center(child: CircularProgressIndicator()),

              error: (error, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(error.toString(), textAlign: TextAlign.center),
                      const SizedBox(height: 16),
                      FilledButton(onPressed: _cargar, child: const Text('Reintentar')),
                    ],
                  ),
                ),
              ),

              data: (predictionDay) {
                return RefreshIndicator(
                  onRefresh: _cargar,
                  child: PredictionList(
                    predictionDay: predictionDay,
                    onMatchChanged: _updateMatch,
                  ),
                );
              },
            ),
          ),

          SafeArea(
            top: false,
            minimum: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: (state.value?.isOpen ?? false) ? _save : null,
                icon: const Icon(Icons.save),
                label: const Text(
                  'GUARDAR Y ENVIAR',
                  style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _JornadaTabs extends ConsumerStatefulWidget {
  const _JornadaTabs({
    required this.jornadaSeleccionadaId,
    required this.onSeleccionar,
  });

  final int jornadaSeleccionadaId;
  final ValueChanged<JornadaModel> onSeleccionar;

  @override
  ConsumerState<_JornadaTabs> createState() => _JornadaTabsState();
}

class _JornadaTabsState extends ConsumerState<_JornadaTabs> {
  final _scrollController = ScrollController();
  bool _yaSeDesplazo = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _desplazarSiHaceFalta(List<JornadaModel> ordenadas) {
    if (_yaSeDesplazo) return;

    final indice = ordenadas.indexWhere((j) => j.id == widget.jornadaSeleccionadaId);
    if (indice <= 0) return;

    _yaSeDesplazo = true;

    const anchoAproximadoPorPestana = 58.0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;

      final destino = (indice * anchoAproximadoPorPestana)
          .clamp(0.0, _scrollController.position.maxScrollExtent);

      _scrollController.animateTo(
        destino,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // Se resuelve la temporada a partir de la jornada actual, en
    // vez de depender de que quedara guardada de antes — si se
    // aterriza aquí directo desde el Dashboard (sin pasar por
    // "Mis ligas"), esa selección previa puede no existir todavía.
    final todasLasJornadasAsync = ref.watch(jornadasAdminProvider);

    return todasLasJornadasAsync.when(
      loading: () => const SizedBox(height: 56),
      error: (_, __) => const SizedBox.shrink(),
      data: (todas) {
        if (todas.isEmpty) return const SizedBox.shrink();

        final actual = todas.where((j) => j.id == widget.jornadaSeleccionadaId);

        if (actual.isEmpty) return const SizedBox.shrink();

        final temporadaId = actual.first.temporadaId;

        final ordenadas = todas.where((j) => j.temporadaId == temporadaId).toList()
          ..sort((a, b) => a.numero.compareTo(b.numero));

        _desplazarSiHaceFalta(ordenadas);

        return Container(
          height: 56,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: ListView.separated(
            controller: _scrollController,
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: ordenadas.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final jornada = ordenadas[index];
              final seleccionada = jornada.id == widget.jornadaSeleccionadaId;

              return ChoiceChip(
                avatar: jornada.cerrada
                    ? const Icon(Icons.lock_outline, size: 14, color: Colors.grey)
                    : null,
                label: Text('${jornada.numero}'),
                selected: seleccionada,
                selectedColor: AppColors.secondary,
                disabledColor: Colors.grey.shade200,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: jornada.cerrada
                      ? Colors.grey
                      : (seleccionada ? AppColors.onSecondary : AppColors.textPrimary),
                ),
                // Las jornadas cerradas se muestran pero no se
                // pueden tocar — solo las abiertas permiten
                // capturar/editar pronósticos.
                // Las jornadas cerradas SÍ se pueden abrir para
                // consultar lo que ya se capturó — solo que los
                // marcadores salen deshabilitados dentro (eso ya lo
                // maneja ApiPredictionService con locked: cerrada).
                onSelected: (_) => widget.onSeleccionar(jornada),
              );
            },
          ),
        );
      },
    );
  }
}
