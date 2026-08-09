import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_route_names.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../administration/providers/administration_provider.dart';
import '../../login/providers/auth_provider.dart';
import '../../temporadas/providers/temporada_provider.dart';
import '../models/ganador_premio_model.dart';
import '../providers/premios_provider.dart';

/// Pantalla de "Premios y Ganadores" — visible a todo participante
/// (transparencia total). El cálculo es una SUGERENCIA; el
/// administrador es quien aprueba, ajusta o niega cada uno.
class GanadoresPage extends ConsumerStatefulWidget {
  const GanadoresPage({super.key});

  @override
  ConsumerState<GanadoresPage> createState() => _GanadoresPageState();
}

class _GanadoresPageState extends ConsumerState<GanadoresPage> {
  String _ambito = 'Jornada';
  int? _jornadaId;
  int? _temporadaId;

  @override
  Widget build(BuildContext context) {
    final esAdmin = ref.watch(authProvider).user?.roles.contains('Administrador') ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Premios y ganadores'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouteNames.home),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'Jornada', label: Text('Por jornada')),
                ButtonSegment(value: 'Final', label: Text('Final de temporada')),
              ],
              selected: {_ambito},
              onSelectionChanged: (nuevo) => setState(() => _ambito = nuevo.first),
            ),
          ),
          if (_ambito == 'Jornada') _SelectorJornada(
            jornadaSeleccionadaId: _jornadaId,
            onSeleccionar: (id) => setState(() => _jornadaId = id),
          ) else _SelectorTemporada(
            temporadaSeleccionadaId: _temporadaId,
            onSeleccionar: (id) => setState(() => _temporadaId = id),
          ),
          Expanded(
            child: _ambito == 'Jornada'
                ? (_jornadaId == null
                    ? const Center(child: Text('Elige una jornada.'))
                    : _ListaGanadores(
                        ambito: 'Jornada',
                        referenciaId: _jornadaId!,
                        esAdmin: esAdmin,
                      ))
                : (_temporadaId == null
                    ? const Center(child: Text('Elige una temporada.'))
                    : _ListaGanadores(
                        ambito: 'Final',
                        referenciaId: _temporadaId!,
                        esAdmin: esAdmin,
                      )),
          ),
        ],
      ),
    );
  }
}

class _SelectorJornada extends ConsumerWidget {
  const _SelectorJornada({required this.jornadaSeleccionadaId, required this.onSeleccionar});

  final int? jornadaSeleccionadaId;
  final ValueChanged<int> onSeleccionar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jornadasAsync = ref.watch(jornadasAdminProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: jornadasAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text('No fue posible cargar jornadas.\n$e'),
        data: (jornadas) {
          if (jornadas.isEmpty) return const Text('Todavía no hay jornadas.');

          final ordenadas = [...jornadas]..sort((a, b) => a.numero.compareTo(b.numero));

          if (jornadaSeleccionadaId == null) {
            final cerradas = ordenadas.where((j) => j.cerrada).toList();
            final porDefecto = cerradas.isNotEmpty ? cerradas.last : ordenadas.last;
            WidgetsBinding.instance.addPostFrameCallback((_) => onSeleccionar(porDefecto.id));
          }

          return DropdownButtonFormField<int>(
            initialValue: jornadaSeleccionadaId,
            decoration: const InputDecoration(labelText: 'Jornada'),
            items: ordenadas.map((j) => DropdownMenuItem(value: j.id, child: Text(j.nombre))).toList(),
            onChanged: (value) {
              if (value != null) onSeleccionar(value);
            },
          );
        },
      ),
    );
  }
}

class _SelectorTemporada extends ConsumerWidget {
  const _SelectorTemporada({required this.temporadaSeleccionadaId, required this.onSeleccionar});

  final int? temporadaSeleccionadaId;
  final ValueChanged<int> onSeleccionar;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final temporadasAsync = ref.watch(temporadasProvider);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: temporadasAsync.when(
        loading: () => const LinearProgressIndicator(),
        error: (e, _) => Text('No fue posible cargar temporadas.\n$e'),
        data: (temporadas) {
          if (temporadas.isEmpty) return const Text('Todavía no hay temporadas.');

          if (temporadaSeleccionadaId == null) {
            WidgetsBinding.instance.addPostFrameCallback((_) => onSeleccionar(temporadas.first.id));
          }

          return DropdownButtonFormField<int>(
            initialValue: temporadaSeleccionadaId ?? temporadas.first.id,
            decoration: const InputDecoration(labelText: 'Temporada'),
            items: temporadas.map((t) => DropdownMenuItem(value: t.id, child: Text(t.nombre))).toList(),
            onChanged: (value) {
              if (value != null) onSeleccionar(value);
            },
          );
        },
      ),
    );
  }
}

class _ListaGanadores extends ConsumerWidget {
  const _ListaGanadores({required this.ambito, required this.referenciaId, required this.esAdmin});

  final String ambito;
  final int referenciaId;
  final bool esAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ganadoresAsync = ambito == 'Jornada'
        ? ref.watch(ganadoresJornadaProvider(referenciaId))
        : ref.watch(ganadoresFinalesProvider(referenciaId));

    return ganadoresAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('No fue posible cargar los ganadores.\n$e')),
      data: (grupos) {
        if (grupos.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(AppSpacing.lg),
              child: Text(
                'No hay premios configurados para esto todavía, o nadie ha capturado pronósticos.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(AppSpacing.md),
          itemCount: grupos.length,
          separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, i) {
            final grupo = grupos[i];
            final medalla = grupo.posicionDesde == 1
                ? '🥇'
                : (grupo.posicionDesde == 2 ? '🥈' : (grupo.posicionDesde == 3 ? '🥉' : '🏅'));
            final etiquetaPosicion = grupo.posicionDesde == grupo.posicionHasta
                ? '${grupo.posicionDesde}° lugar'
                : '${grupo.posicionDesde}°-${grupo.posicionHasta}° lugar (empate)';

            return Card(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(medalla, style: const TextStyle(fontSize: 20)),
                        const SizedBox(width: 8),
                        Text(etiquetaPosicion, style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    if (grupo.tipoPremio == 'Especie' && grupo.descripcion != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text('🎁 ${grupo.descripcion}', style: const TextStyle(color: Colors.grey)),
                      ),
                    const Divider(),
                    ...grupo.participantes.map(
                      (p) => _FilaParticipante(
                        ambito: ambito,
                        referenciaId: referenciaId,
                        participante: p,
                        tipoPremio: grupo.tipoPremio,
                        esAdmin: esAdmin,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _FilaParticipante extends ConsumerWidget {
  const _FilaParticipante({
    required this.ambito,
    required this.referenciaId,
    required this.participante,
    required this.tipoPremio,
    required this.esAdmin,
  });

  final String ambito;
  final int referenciaId;
  final GanadorParticipanteModel participante;
  final String tipoPremio;
  final bool esAdmin;

  Color _colorEstado(String estado) {
    switch (estado) {
      case 'Aprobado':
        return Colors.green;
      case 'Denegado':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final montoFinal = participante.montoAjustado ?? participante.montoSugerido;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(participante.nombre, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(
                  tipoPremio == 'Efectivo' || participante.motivo != null
                      ? '\$${montoFinal.toStringAsFixed(2)}'
                      : 'Regalo',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                if (participante.motivo != null)
                  Text(
                    'Motivo: ${participante.motivo}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _colorEstado(participante.estado).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              participante.estado,
              style: TextStyle(fontSize: 11, color: _colorEstado(participante.estado), fontWeight: FontWeight.bold),
            ),
          ),
          if (esAdmin) ...[
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.edit_outlined, size: 18),
              tooltip: 'Decidir',
              onPressed: () => _mostrarDialogoDecision(context, ref),
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoDecision(BuildContext context, WidgetRef ref) async {
    final montoController =
        TextEditingController(text: (participante.montoAjustado ?? participante.montoSugerido).toStringAsFixed(2));
    final motivoController = TextEditingController(text: participante.motivo ?? '');
    var estado = participante.estado == 'Pendiente' ? 'Aprobado' : participante.estado;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text('Decidir premio — ${participante.nombre}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Sugerido: \$${participante.montoSugerido.toStringAsFixed(2)}'),
                  const SizedBox(height: AppSpacing.sm),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'Aprobado', label: Text('Aprobar')),
                      ButtonSegment(value: 'Denegado', label: Text('Negar')),
                    ],
                    selected: {estado},
                    onSelectionChanged: (nuevo) => setState(() => estado = nuevo.first),
                  ),
                  if (estado == 'Aprobado') ...[
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: montoController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Monto a pagar'),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: motivoController,
                    decoration: InputDecoration(
                      labelText: estado == 'Denegado' ? 'Motivo (recomendado)' : 'Nota (opcional)',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    final monto = double.tryParse(montoController.text);

                    try {
                      await ref.read(premiosServiceProvider).decidirPremio(
                            ambito: ambito,
                            referenciaId: referenciaId,
                            usuarioId: participante.usuarioId,
                            estado: estado,
                            montoAjustado: estado == 'Aprobado' &&
                                    monto != null &&
                                    monto != participante.montoSugerido
                                ? monto
                                : null,
                            motivo: motivoController.text.trim().isEmpty
                                ? null
                                : motivoController.text.trim(),
                          );

                      if (ambito == 'Jornada') {
                        ref.invalidate(ganadoresJornadaProvider(referenciaId));
                      } else {
                        ref.invalidate(ganadoresFinalesProvider(referenciaId));
                      }

                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('No se pudo guardar: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
