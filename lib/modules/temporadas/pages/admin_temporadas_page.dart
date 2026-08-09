import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../leagues/models/league_model.dart';
import '../../leagues/providers/league_provider.dart';
import '../models/temporada_model.dart';
import '../providers/temporada_provider.dart';

class AdminTemporadasPage extends ConsumerWidget {
  const AdminTemporadasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final temporadasAsync = ref.watch(temporadasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Temporadas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: temporadasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No fue posible cargar las temporadas.\n$e')),
        data: (temporadas) {
          if (temporadas.isEmpty) {
            return const Center(child: Text('Todavía no hay temporadas. Crea la primera.'));
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(temporadasProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: temporadas.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final temporada = temporadas[index];

                return Card(
                  child: ListTile(
                    leading: const Icon(Icons.calendar_month_outlined),
                    title: Text(temporada.nombre),
                    subtitle: Text(
                      '${_formatFecha(temporada.fechaInicio)} — ${_formatFecha(temporada.fechaFin)}'
                      '${temporada.cuota > 0 ? ' · Cuota: \$${temporada.cuota.toStringAsFixed(2)}' : ''}',
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          temporada.activo ? Icons.check_circle : Icons.pause_circle_outline,
                          color: temporada.activo ? Colors.green : Colors.grey,
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showFormDialog(context, ref, temporada: temporada),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Eliminar',
                          onPressed: () => _confirmarEliminar(context, ref, temporada),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormDialog(context, ref),
        icon: const Icon(Icons.add),
        label: const Text('Nueva temporada'),
      ),
    );
  }

  String _formatFecha(DateTime fecha) => '${fecha.day}/${fecha.month}/${fecha.year}';

  Future<void> _confirmarEliminar(
    BuildContext context,
    WidgetRef ref,
    TemporadaModel temporada,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar esta temporada?'),
        content: Text(
          'Se eliminará "${temporada.nombre}" de forma permanente. '
          'Si tiene jornadas ya creadas, es posible que no se pueda eliminar.',
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
      await ref.read(temporadaServiceProvider).eliminar(temporada.id);
      ref.invalidate(temporadasProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar: $e')),
        );
      }
    }
  }

  Future<void> _showFormDialog(
    BuildContext context,
    WidgetRef ref, {
    TemporadaModel? temporada,
  }) async {
    final esNuevo = temporada == null;

    List<LeagueModel> ligas;
    try {
      // ref.read(...).value da una foto instantánea que puede seguir
      // vacía si el proveedor (autoDispose) se acaba de recrear al
      // entrar a esta pantalla -- se espera la carga real en su lugar.
      ligas = await ref.read(leaguesProvider.future);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No fue posible cargar las ligas: $e')),
        );
      }
      return;
    }

    if (esNuevo && ligas.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Primero crea al menos una liga.')),
        );
      }
      return;
    }

    final codigoController = TextEditingController(text: temporada?.codigo ?? '');
    final nombreController = TextEditingController(text: temporada?.nombre ?? '');
    final descripcionController = TextEditingController(text: temporada?.descripcion ?? '');
    final cuotaController = TextEditingController(
      text: temporada != null && temporada.cuota > 0 ? temporada.cuota.toStringAsFixed(2) : '',
    );
    var ligaId = temporada?.ligaId ?? ligas.first.id;
    var fechaInicio = temporada?.fechaInicio ?? DateTime.now();
    var fechaFin = temporada?.fechaFin ?? DateTime.now().add(const Duration(days: 180));
    var activo = temporada?.activo ?? true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(esNuevo ? 'Nueva temporada' : 'Editar temporada'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (esNuevo) ...[
                      DropdownButtonFormField<int>(
                        initialValue: ligaId,
                        decoration: const InputDecoration(labelText: 'Liga'),
                        items: ligas
                            .map((l) => DropdownMenuItem(value: l.id, child: Text(l.nombre)))
                            .toList(),
                        onChanged: (value) => setState(() => ligaId = value!),
                      ),
                      TextField(
                        controller: codigoController,
                        decoration: const InputDecoration(labelText: 'Código'),
                      ),
                    ],
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    TextField(
                      controller: descripcionController,
                      decoration: const InputDecoration(labelText: 'Descripción'),
                    ),
                    TextField(
                      controller: cuotaController,
                      decoration: const InputDecoration(
                        labelText: 'Cuota',
                        hintText: 'Monto que paga cada participante esta temporada',
                        prefixText: '\$ ',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Fecha de inicio'),
                      subtitle: Text(_formatFecha(fechaInicio)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: fechaInicio,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 730)),
                        );
                        if (picked != null) setState(() => fechaInicio = picked);
                      },
                    ),
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Fecha de fin'),
                      subtitle: Text(_formatFecha(fechaFin)),
                      trailing: const Icon(Icons.calendar_today),
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: dialogContext,
                          initialDate: fechaFin,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 730)),
                        );
                        if (picked != null) setState(() => fechaFin = picked);
                      },
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Activa'),
                      value: activo,
                      onChanged: (value) => setState(() => activo = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (nombreController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('El nombre es obligatorio.')),
                      );
                      return;
                    }

                    if (fechaFin.isBefore(fechaInicio)) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('La fecha de fin no puede ser antes que la de inicio.')),
                      );
                      return;
                    }

                    final cuota = double.tryParse(cuotaController.text.trim()) ?? 0;
                    final service = ref.read(temporadaServiceProvider);

                    try {
                      if (esNuevo) {
                        await service.crear(
                          ligaId: ligaId,
                          codigo: codigoController.text.trim(),
                          nombre: nombreController.text.trim(),
                          descripcion: descripcionController.text.trim(),
                          fechaInicio: fechaInicio,
                          fechaFin: fechaFin,
                          cuota: cuota,
                          activo: activo,
                        );
                      } else {
                        await service.actualizar(
                          id: temporada.id,
                          nombre: nombreController.text.trim(),
                          descripcion: descripcionController.text.trim(),
                          fechaInicio: fechaInicio,
                          fechaFin: fechaFin,
                          cuota: cuota,
                          activo: activo,
                        );
                      }

                      ref.invalidate(temporadasProvider);

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
}
