import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/design_system/widgets/forms/selector_imagen_widget.dart';
import '../models/equipo_model.dart';
import '../providers/equipo_provider.dart';
import '../services/equipo_service.dart';

class AdminEquiposPage extends ConsumerWidget {
  const AdminEquiposPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final equiposAsync = ref.watch(equiposProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Equipos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: equiposAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No fue posible cargar los equipos.\n$e')),
        data: (equipos) {
          if (equipos.isEmpty) {
            return const Center(child: Text('Todavía no hay equipos.'));
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(equiposProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: equipos.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final equipo = equipos[index];

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage: (equipo.escudoUrl != null && equipo.escudoUrl!.isNotEmpty)
                          ? NetworkImage(equipo.escudoUrl!)
                          : null,
                      child: (equipo.escudoUrl == null || equipo.escudoUrl!.isEmpty)
                          ? Text(equipo.nombre.isNotEmpty ? equipo.nombre[0].toUpperCase() : '?')
                          : null,
                    ),
                    title: Text(equipo.nombre),
                    subtitle: Text(
                      equipo.apodo != null ? '${equipo.codigo} · ${equipo.apodo}' : equipo.codigo,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showFormDialog(context, ref, equipo: equipo),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Eliminar',
                          onPressed: () => _confirmarEliminar(context, ref, equipo),
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
        label: const Text('Nuevo equipo'),
      ),
    );
  }

  Future<void> _showFormDialog(
    BuildContext context,
    WidgetRef ref, {
    EquipoModel? equipo,
  }) async {
    final esNuevo = equipo == null;

    final codigoController = TextEditingController(text: equipo?.codigo ?? '');
    final nombreController = TextEditingController(text: equipo?.nombre ?? '');
    final descripcionController = TextEditingController(text: equipo?.descripcion ?? '');
    final apodoController = TextEditingController(text: equipo?.apodo ?? '');
    var escudoUrl = equipo?.escudoUrl;
    var activo = equipo?.activo ?? true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(esNuevo ? 'Nuevo equipo' : 'Editar equipo'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SelectorImagenWidget(
                      urlActual: escudoUrl,
                      circular: true,
                      onCambio: (nuevaUrl) => setState(() => escudoUrl = nuevaUrl),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    if (esNuevo)
                      TextField(
                        controller: codigoController,
                        decoration: const InputDecoration(labelText: 'Código'),
                      ),
                    TextField(
                      controller: nombreController,
                      decoration: const InputDecoration(labelText: 'Nombre'),
                    ),
                    TextField(
                      controller: apodoController,
                      decoration: const InputDecoration(
                        labelText: 'Apodo (opcional)',
                        hintText: 'Ej. Águilas',
                      ),
                    ),
                    TextField(
                      controller: descripcionController,
                      decoration: const InputDecoration(labelText: 'Descripción'),
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Activo'),
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

                    final service = ref.read(equipoServiceProvider);

                    try {
                      if (esNuevo) {
                        await service.crear(
                          codigo: codigoController.text.trim(),
                          nombre: nombreController.text.trim(),
                          descripcion: descripcionController.text.trim(),
                          escudoUrl: escudoUrl,
                          apodo: apodoController.text.trim().isEmpty ? null : apodoController.text.trim(),
                          activo: activo,
                        );
                      } else {
                        await service.actualizar(
                          id: equipo.id,
                          nombre: nombreController.text.trim(),
                          descripcion: descripcionController.text.trim(),
                          escudoUrl: escudoUrl,
                          apodo: apodoController.text.trim().isEmpty ? null : apodoController.text.trim(),
                          activo: activo,
                        );
                      }

                      ref.invalidate(equiposProvider);

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

  Future<void> _confirmarEliminar(
    BuildContext context,
    WidgetRef ref,
    EquipoModel equipo,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar este equipo?'),
        content: Text(
          'Se eliminará "${equipo.nombre}" de forma permanente. '
          'Si tiene partidos ya registrados, es posible que no se pueda eliminar.',
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
      await ref.read(equipoServiceProvider).eliminar(equipo.id);
      ref.invalidate(equiposProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar: $e')),
        );
      }
    }
  }
}
