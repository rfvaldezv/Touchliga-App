import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/providers/catalogos_provider.dart';
import '../../equipos/models/equipo_model.dart';
import '../../equipos/providers/equipo_provider.dart';
import '../models/partido_model.dart';
import '../providers/administration_provider.dart';

class AdminJornadaDetailPage extends ConsumerWidget {
  const AdminJornadaDetailPage({super.key, required this.jornadaId});

  final int jornadaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partidosAsync = ref.watch(partidosPorJornadaProvider(jornadaId));
    final equiposAsync = ref.watch(equiposProvider);
    final jornadasAsync = ref.watch(jornadasAdminProvider);

    final jornadas = jornadasAsync.value ?? [];
    final miJornada = jornadas.where((j) => j.id == jornadaId);
    final yaCerrada = miJornada.isNotEmpty && miJornada.first.cerrada;

    return Scaffold(
      appBar: AppBar(
        title: Text('Jornada #$jornadaId'),
        actions: [
          if (yaCerrada)
            TextButton.icon(
              onPressed: () => _confirmarAbrirJornada(context, ref),
              icon: const Icon(Icons.lock_open, color: Colors.white70),
              label: const Text('🔒 Cerrada — reabrir', style: TextStyle(color: Colors.white70)),
            )
          else
            TextButton.icon(
              onPressed: () => _confirmarCerrarJornada(context, ref),
              icon: const Icon(Icons.lock, color: Colors.white),
              label: const Text('Cerrar jornada', style: TextStyle(color: Colors.white)),
            ),
        ],
      ),
      body: equiposAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No fue posible cargar los equipos.\n$e')),
        data: (equipos) {
          final equiposPorId = {for (final e in equipos) e.id: e};

          return partidosAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('No fue posible cargar los partidos.\n$e')),
            data: (partidos) {
              if (partidos.isEmpty) {
                return const Center(child: Text('Todavía no hay partidos en esta jornada.'));
              }

              return RefreshIndicator(
                onRefresh: () async =>
                    ref.invalidate(partidosPorJornadaProvider(jornadaId)),
                child: ListView.separated(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  itemCount: partidos.length,
                  separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                  itemBuilder: (context, index) {
                    final partido = partidos[index];
                    final local = equiposPorId[partido.equipoLocalId];
                    final visitante = equiposPorId[partido.equipoVisitanteId];

                    return Card(
                      child: ListTile(
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _EscudoChico(url: local?.escudoUrl, nombre: local?.nombre ?? '?'),
                            const SizedBox(width: 4),
                            _EscudoChico(url: visitante?.escudoUrl, nombre: visitante?.nombre ?? '?'),
                          ],
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${local?.nombre ?? '#${partido.equipoLocalId}'} vs ${visitante?.nombre ?? '#${partido.equipoVisitanteId}'}',
                              ),
                            ),
                            if (partido.esDesempate)
                              const Padding(
                                padding: EdgeInsets.only(left: 4),
                                child: Text('⭐', style: TextStyle(fontSize: 16)),
                              ),
                          ],
                        ),
                        subtitle: Text(
                          [
                            partido.tieneResultado
                                ? 'Resultado: ${partido.golesLocal} - ${partido.golesVisitante}'
                                : 'Sin resultado capturado',
                            if (partido.canchaNombre != null) partido.canchaNombre!,
                            if (partido.esDesempate) 'Partido de desempate',
                          ].join(' · '),
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (accion) {
                            switch (accion) {
                              case 'resultado':
                                _showCapturarResultadoDialog(context, ref, partido);
                                break;
                              case 'editar':
                                _showEditarPartidoDialog(context, ref, partido);
                                break;
                              case 'desempate':
                                _marcarDesempate(context, ref, partido, !partido.esDesempate);
                                break;
                              case 'eliminar':
                                _confirmarEliminarPartido(context, ref, partido);
                                break;
                            }
                          },
                          itemBuilder: (context) => [
                            PopupMenuItem(
                              value: 'resultado',
                              child: Text(partido.tieneResultado ? 'Corregir resultado' : 'Capturar resultado'),
                            ),
                            const PopupMenuItem(value: 'editar', child: Text('Editar datos del partido')),
                            PopupMenuItem(
                              value: 'desempate',
                              child: Text(
                                partido.esDesempate
                                    ? 'Quitar como partido de desempate'
                                    : 'Marcar como partido de desempate ⭐',
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'eliminar',
                              child: Text('Eliminar', style: TextStyle(color: Colors.red)),
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
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCrearPartidoDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nuevo partido'),
      ),
    );
  }

  Future<void> _confirmarCerrarJornada(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Cerrar esta jornada?'),
        content: const Text(
          'Ya no se podrán capturar ni editar pronósticos, ni corregir resultados de sus partidos. Si necesitas hacer un ajuste después, puedes volver a abrirla.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Cerrar jornada'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final service = ref.read(administrationServiceProvider);

    try {
      await service.cerrarJornada(jornadaId);

      ref.invalidate(jornadasAdminProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jornada cerrada.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cerrar: $e')),
        );
      }
    }
  }

  Future<void> _confirmarAbrirJornada(BuildContext context, WidgetRef ref) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Reabrir esta jornada?'),
        content: const Text(
          'Se podrán volver a editar pronósticos y resultados de sus partidos. Recuerda volver a cerrarla cuando termines el ajuste.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Reabrir'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final service = ref.read(administrationServiceProvider);

    try {
      await service.abrirJornada(jornadaId);

      ref.invalidate(jornadasAdminProvider);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Jornada reabierta.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo reabrir: $e')),
        );
      }
    }
  }

  Future<void> _showCrearPartidoDialog(BuildContext context, WidgetRef ref) async {
    List<EquipoModel> equipos;
    try {
      equipos = await ref.read(equiposProvider.future);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No fue posible cargar los equipos: $e')),
        );
      }
      return;
    }

    if (equipos.length < 2) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Necesitas al menos 2 equipos creados.')),
        );
      }
      return;
    }

    var equipoLocalId = equipos[0].id;
    var equipoVisitanteId = equipos[1].id;
    var canchaId = null as int?;
    var fechaHora = DateTime.now().add(const Duration(days: 1));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('Nuevo partido'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: equipoLocalId,
                    decoration: const InputDecoration(labelText: 'Equipo local'),
                    items: equipos
                        .map((e) => DropdownMenuItem(
                            value: e.id,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _EscudoChico(url: e.escudoUrl, nombre: e.nombre),
                                const SizedBox(width: 8),
                                Text(e.nombre),
                              ],
                            ),
                          ))
                        .toList(),
                    onChanged: (value) => setState(() => equipoLocalId = value!),
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: equipoVisitanteId,
                    decoration: const InputDecoration(labelText: 'Equipo visitante'),
                    items: equipos
                        .map((e) => DropdownMenuItem(
                            value: e.id,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _EscudoChico(url: e.escudoUrl, nombre: e.nombre),
                                const SizedBox(width: 8),
                                Text(e.nombre),
                              ],
                            ),
                          ))
                        .toList(),
                    onChanged: (value) => setState(() => equipoVisitanteId = value!),
                  ),
                  Consumer(
                    builder: (context, ref, _) {
                      final canchasAsync = ref.watch(canchasProvider);

                      return canchasAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (canchas) {
                          return DropdownButtonFormField<int?>(
                            initialValue: canchaId,
                            decoration: const InputDecoration(labelText: 'Cancha (opcional)'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Sin especificar')),
                              ...canchas.map(
                                (c) => DropdownMenuItem(value: c.id, child: Text(c.nombre)),
                              ),
                            ],
                            onChanged: (value) => setState(() => canchaId = value),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Fecha'),
                    subtitle: Text('${fechaHora.day}/${fechaHora.month}/${fechaHora.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: fechaHora,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => fechaHora = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              fechaHora.hour,
                              fechaHora.minute,
                            ));
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Hora'),
                    subtitle: Text(
                      '${fechaHora.hour.toString().padLeft(2, '0')}:${fechaHora.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: dialogContext,
                        initialTime: TimeOfDay(hour: fechaHora.hour, minute: fechaHora.minute),
                      );
                      if (picked != null) {
                        setState(() => fechaHora = DateTime(
                              fechaHora.year,
                              fechaHora.month,
                              fechaHora.day,
                              picked.hour,
                              picked.minute,
                            ));
                      }
                    },
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
                    if (equipoLocalId == equipoVisitanteId) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('El equipo local y visitante no pueden ser el mismo.')),
                      );
                      return;
                    }

                    final partidosExistentes =
                        ref.read(partidosPorJornadaProvider(jornadaId)).value ?? [];
                    final equiposYaUsados = <int>{};
                    for (final p in partidosExistentes) {
                      equiposYaUsados.add(p.equipoLocalId);
                      equiposYaUsados.add(p.equipoVisitanteId);
                    }

                    final repetido = [equipoLocalId, equipoVisitanteId]
                        .where(equiposYaUsados.contains)
                        .toList();

                    if (repetido.isNotEmpty) {
                      final nombreRepetido = equipos
                          .firstWhere((e) => e.id == repetido.first)
                          .nombre;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            '$nombreRepetido ya tiene un partido en esta jornada. '
                            'Un equipo no puede jugar dos veces en la misma jornada.',
                          ),
                        ),
                      );
                      return;
                    }

                    final service = ref.read(administrationServiceProvider);

                    await service.crearPartido(
                      jornadaId: jornadaId,
                      equipoLocalId: equipoLocalId,
                      equipoVisitanteId: equipoVisitanteId,
                      fechaHora: fechaHora,
                      canchaId: canchaId,
                    );

                    ref.invalidate(partidosPorJornadaProvider(jornadaId));

                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  },
                  child: const Text('Crear'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditarPartidoDialog(
    BuildContext context,
    WidgetRef ref,
    PartidoModel partido,
  ) async {
    List<EquipoModel> equipos;
    try {
      equipos = await ref.read(equiposProvider.future);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No fue posible cargar los equipos: $e')),
        );
      }
      return;
    }

    var equipoLocalId = partido.equipoLocalId;
    var equipoVisitanteId = partido.equipoVisitanteId;
    var canchaId = partido.canchaId;
    var fechaHora = partido.fechaHora;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('Editar partido'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: equipoLocalId,
                    decoration: const InputDecoration(labelText: 'Equipo local'),
                    items: equipos
                        .map((e) => DropdownMenuItem(
                            value: e.id,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _EscudoChico(url: e.escudoUrl, nombre: e.nombre),
                                const SizedBox(width: 8),
                                Text(e.nombre),
                              ],
                            ),
                          ))
                        .toList(),
                    onChanged: (value) => setState(() => equipoLocalId = value!),
                  ),
                  DropdownButtonFormField<int>(
                    initialValue: equipoVisitanteId,
                    decoration: const InputDecoration(labelText: 'Equipo visitante'),
                    items: equipos
                        .map((e) => DropdownMenuItem(
                            value: e.id,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _EscudoChico(url: e.escudoUrl, nombre: e.nombre),
                                const SizedBox(width: 8),
                                Text(e.nombre),
                              ],
                            ),
                          ))
                        .toList(),
                    onChanged: (value) => setState(() => equipoVisitanteId = value!),
                  ),
                  Consumer(
                    builder: (context, ref, _) {
                      final canchasAsync = ref.watch(canchasProvider);

                      return canchasAsync.when(
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => const SizedBox.shrink(),
                        data: (canchas) {
                          return DropdownButtonFormField<int?>(
                            initialValue: canchaId,
                            decoration: const InputDecoration(labelText: 'Cancha (opcional)'),
                            items: [
                              const DropdownMenuItem(value: null, child: Text('Sin especificar')),
                              ...canchas.map(
                                (c) => DropdownMenuItem(value: c.id, child: Text(c.nombre)),
                              ),
                            ],
                            onChanged: (value) => setState(() => canchaId = value),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Fecha'),
                    subtitle: Text('${fechaHora.day}/${fechaHora.month}/${fechaHora.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: fechaHora,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        setState(() => fechaHora = DateTime(
                              picked.year,
                              picked.month,
                              picked.day,
                              fechaHora.hour,
                              fechaHora.minute,
                            ));
                      }
                    },
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Hora'),
                    subtitle: Text(
                      '${fechaHora.hour.toString().padLeft(2, '0')}:${fechaHora.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: dialogContext,
                        initialTime: TimeOfDay(hour: fechaHora.hour, minute: fechaHora.minute),
                      );
                      if (picked != null) {
                        setState(() => fechaHora = DateTime(
                              fechaHora.year,
                              fechaHora.month,
                              fechaHora.day,
                              picked.hour,
                              picked.minute,
                            ));
                      }
                    },
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
                    if (equipoLocalId == equipoVisitanteId) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('El equipo local y visitante no pueden ser el mismo.')),
                      );
                      return;
                    }

                    final partidosExistentes = (ref.read(partidosPorJornadaProvider(jornadaId)).value ?? [])
                        .where((p) => p.id != partido.id);
                    final equiposYaUsados = <int>{};
                    for (final p in partidosExistentes) {
                      equiposYaUsados.add(p.equipoLocalId);
                      equiposYaUsados.add(p.equipoVisitanteId);
                    }

                    final repetido = [equipoLocalId, equipoVisitanteId]
                        .where(equiposYaUsados.contains)
                        .toList();

                    if (repetido.isNotEmpty) {
                      final nombreRepetido = equipos
                          .firstWhere((e) => e.id == repetido.first)
                          .nombre;
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(
                          content: Text(
                            '$nombreRepetido ya tiene otro partido en esta jornada. '
                            'Un equipo no puede jugar dos veces en la misma jornada.',
                          ),
                        ),
                      );
                      return;
                    }

                    final service = ref.read(administrationServiceProvider);

                    try {
                      await service.editarPartido(
                        id: partido.id,
                        equipoLocalId: equipoLocalId,
                        equipoVisitanteId: equipoVisitanteId,
                        fechaHora: fechaHora,
                        canchaId: canchaId,
                      );

                      ref.invalidate(partidosPorJornadaProvider(jornadaId));

                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    } catch (e) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('No se pudo guardar: $e')),
                      );
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

  Future<void> _confirmarEliminarPartido(
    BuildContext context,
    WidgetRef ref,
    PartidoModel partido,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar este partido?'),
        content: const Text(
          'Se eliminará de forma permanente, junto con cualquier pronóstico que ya se haya capturado para él.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    try {
      await ref.read(administrationServiceProvider).eliminarPartido(partido.id);
      ref.invalidate(partidosPorJornadaProvider(jornadaId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar: $e')),
        );
      }
    }
  }

  Future<void> _marcarDesempate(
    BuildContext context,
    WidgetRef ref,
    PartidoModel partido,
    bool esDesempate,
  ) async {
    if (esDesempate) {
      final confirmar = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('¿Marcar como partido de desempate?'),
          content: const Text(
            'Solo puede haber un partido de desempate por jornada — si ya habías marcado otro, se '
            'desmarca automáticamente. Los participantes verán una caja extra para predecir la suma '
            'y la diferencia de puntos de este partido.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Marcar'),
            ),
          ],
        ),
      );
      if (confirmar != true) return;
    }

    try {
      await ref.read(administrationServiceProvider).marcarDesempate(
            partidoId: partido.id,
            esDesempate: esDesempate,
          );
      ref.invalidate(partidosPorJornadaProvider(jornadaId));
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo actualizar: $e')),
        );
      }
    }
  }

  Future<void> _showCapturarResultadoDialog(
    BuildContext context,
    WidgetRef ref,
    PartidoModel partido,
  ) async {
    final golesLocalController =
        TextEditingController(text: partido.golesLocal?.toString() ?? '');
    final golesVisitanteController =
        TextEditingController(text: partido.golesVisitante?.toString() ?? '');

    List<EquipoModel> equipos;
    try {
      equipos = await ref.read(equiposProvider.future);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No fue posible cargar los equipos: $e')),
        );
      }
      return;
    }
    final local = equipos.where((e) => e.id == partido.equipoLocalId).isEmpty
        ? null
        : equipos.firstWhere((e) => e.id == partido.equipoLocalId);
    final visitante = equipos.where((e) => e.id == partido.equipoVisitanteId).isEmpty
        ? null
        : equipos.firstWhere((e) => e.id == partido.equipoVisitanteId);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Capturar resultado'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        _EscudoChico(url: local?.escudoUrl, nombre: local?.nombre ?? '?'),
                        const SizedBox(height: 4),
                        Text(
                          local?.nombre ?? 'Equipo ${partido.equipoLocalId}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                  const Text('vs', style: TextStyle(fontSize: 12)),
                  Expanded(
                    child: Column(
                      children: [
                        _EscudoChico(url: visitante?.escudoUrl, nombre: visitante?.nombre ?? '?'),
                        const SizedBox(height: 4),
                        Text(
                          visitante?.nombre ?? 'Equipo ${partido.equipoVisitanteId}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Expanded(
                    child: TextField(
                      controller: golesLocalController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(labelText: 'Goles'),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Text('-', style: TextStyle(fontSize: 20)),
                  ),
                  Expanded(
                    child: TextField(
                      controller: golesVisitanteController,
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      decoration: const InputDecoration(labelText: 'Goles'),
                    ),
                  ),
                ],
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
                final golesLocal = int.tryParse(golesLocalController.text);
                final golesVisitante = int.tryParse(golesVisitanteController.text);

                if (golesLocal == null || golesVisitante == null) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    const SnackBar(content: Text('Captura ambos marcadores.')),
                  );
                  return;
                }

                final service = ref.read(administrationServiceProvider);

                try {
                  await service.capturarResultado(
                    partidoId: partido.id,
                    golesLocal: golesLocal,
                    golesVisitante: golesVisitante,
                  );

                  ref.invalidate(partidosPorJornadaProvider(jornadaId));

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
  }
}

class _EscudoChico extends StatelessWidget {
  const _EscudoChico({required this.url, required this.nombre});

  final String? url;
  final String nombre;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 14,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: (url != null && url!.isNotEmpty) ? NetworkImage(url!) : null,
      child: (url == null || url!.isEmpty)
          ? Text(
              nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 10),
            )
          : null,
    );
  }
}
