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
import '../../administration/models/partido_model.dart';
import '../../administration/providers/administration_provider.dart';
import '../../administration/services/administration_service.dart';
import '../../equipos/providers/equipo_provider.dart';

final _jornadasDeLaTemporadaProvider =
    FutureProvider.family<List<JornadaModel>, int>((ref, temporadaId) async {
  final service = AdministrationService(apiClient: ApiClient());
  return service.getJornadas(temporadaId: temporadaId);
});

class ResultsPage extends ConsumerStatefulWidget {
  const ResultsPage({super.key});

  @override
  ConsumerState<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends ConsumerState<ResultsPage> {
  int? _jornadaId;

  @override
  void initState() {
    super.initState();
    _jornadaId = ref.read(seleccionProvider).jornadaId;
  }

  @override
  Widget build(BuildContext context) {
    final temporadaId = ref.watch(seleccionProvider).temporadaId;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(AssetPaths.logoIsotipo, height: 24),
            const SizedBox(width: 8),
            const Text('Resultados'),
          ],
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouteNames.home),
        ),
      ),
      body: temporadaId == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Text(
                  'Primero elige una liga y temporada desde "Mis ligas".',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : Column(
              children: [
                _JornadaTabs(
                  temporadaId: temporadaId,
                  jornadaSeleccionadaId: _jornadaId,
                  onSeleccionar: (id) => setState(() => _jornadaId = id),
                ),
                Expanded(
                  child: _jornadaId == null
                      ? const Center(child: Text('Elige una jornada.'))
                      : _ListaResultados(jornadaId: _jornadaId!),
                ),
              ],
            ),
    );
  }
}

class _JornadaTabs extends ConsumerWidget {
  const _JornadaTabs({
    required this.temporadaId,
    required this.jornadaSeleccionadaId,
    required this.onSeleccionar,
  });

  final int temporadaId;
  final int? jornadaSeleccionadaId;
  final ValueChanged<int> onSeleccionar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jornadasAsync = ref.watch(_jornadasDeLaTemporadaProvider(temporadaId));

    return jornadasAsync.when(
      loading: () => const SizedBox(height: 56),
      error: (_, __) => const SizedBox.shrink(),
      data: (jornadas) {
        if (jornadas.isEmpty) return const SizedBox.shrink();

        return Container(
          height: 56,
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            itemCount: jornadas.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final jornada = jornadas[index];
              final seleccionada = jornada.id == jornadaSeleccionadaId;

              return ChoiceChip(
                label: Text('${jornada.numero}'),
                selected: seleccionada,
                selectedColor: AppColors.secondary,
                labelStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: seleccionada ? AppColors.onSecondary : AppColors.textPrimary,
                ),
                onSelected: (_) => onSeleccionar(jornada.id),
              );
            },
          ),
        );
      },
    );
  }
}

class _ListaResultados extends ConsumerWidget {
  const _ListaResultados({required this.jornadaId});

  final int jornadaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partidosAsync = ref.watch(partidosPorJornadaProvider(jornadaId));
    final equiposAsync = ref.watch(equiposProvider);

    return partidosAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('No fue posible cargar los resultados.\n$e')),
      data: (partidos) {
        final equipos = equiposAsync.value ?? [];
        final equiposPorId = {for (final e in equipos) e.id: e};

        if (partidos.isEmpty) {
          return const Center(child: Text('Esta jornada todavía no tiene partidos.'));
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(partidosPorJornadaProvider(jornadaId)),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.md),
            itemCount: partidos.length,
            separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final partido = partidos[index];
              final local = equiposPorId[partido.equipoLocalId];
              final visitante = equiposPorId[partido.equipoVisitanteId];

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _EquipoResultado(
                              nombre: local?.nombre ?? 'Equipo ${partido.equipoLocalId}',
                              apodo: local?.apodo,
                              escudoUrl: local?.escudoUrl,
                              alinearDerecha: true,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                            child: Text(
                              partido.tieneResultado
                                  ? '${partido.golesLocal} - ${partido.golesVisitante}'
                                  : 'vs',
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Expanded(
                            child: _EquipoResultado(
                              nombre: visitante?.nombre ?? 'Equipo ${partido.equipoVisitanteId}',
                              apodo: visitante?.apodo,
                              escudoUrl: visitante?.escudoUrl,
                              alinearDerecha: false,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      const Divider(height: 1),
                      const SizedBox(height: 10),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 14,
                        runSpacing: 2,
                        children: [
                          _Detallito(
                            icono: Icons.event,
                            color: Colors.blueAccent,
                            texto: '${partido.fechaHora.day}/${partido.fechaHora.month}',
                          ),
                          _Detallito(
                            icono: Icons.access_time_filled,
                            color: Colors.redAccent,
                            texto: '${partido.fechaHora.hour.toString().padLeft(2, '0')}:${partido.fechaHora.minute.toString().padLeft(2, '0')}',
                          ),
                          if (partido.canchaNombre != null)
                            _Detallito(
                              icono: Icons.location_on,
                              color: Colors.pinkAccent,
                              texto: partido.canchaNombre!,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _EquipoResultado extends StatelessWidget {
  const _EquipoResultado({
    required this.nombre,
    required this.escudoUrl,
    required this.alinearDerecha,
    this.apodo,
  });

  final String nombre;
  final String? apodo;
  final String? escudoUrl;
  final bool alinearDerecha;

  @override
  Widget build(BuildContext context) {
    final escudo = CircleAvatar(
      radius: 20,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: (escudoUrl != null && escudoUrl!.isNotEmpty)
          ? NetworkImage(escudoUrl!)
          : null,
      child: (escudoUrl == null || escudoUrl!.isEmpty)
          ? Text(nombre.isNotEmpty ? nombre[0].toUpperCase() : '?', style: const TextStyle(fontSize: 14))
          : null,
    );

    final texto = Expanded(
      child: Column(
        crossAxisAlignment: alinearDerecha ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Text(
            nombre,
            textAlign: alinearDerecha ? TextAlign.end : TextAlign.start,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          if (apodo != null && apodo!.isNotEmpty)
            Text(
              apodo!,
              textAlign: alinearDerecha ? TextAlign.end : TextAlign.start,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, color: AppColors.textSecondary),
            ),
        ],
      ),
    );

    return Row(
      children: alinearDerecha
          ? [texto, const SizedBox(width: 6), escudo]
          : [escudo, const SizedBox(width: 6), texto],
    );
  }
}

class _Detallito extends StatelessWidget {
  const _Detallito({required this.icono, required this.texto, this.color});

  final IconData icono;
  final String texto;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 14, color: color ?? AppColors.secondaryDark),
        const SizedBox(width: 3),
        Text(texto, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
