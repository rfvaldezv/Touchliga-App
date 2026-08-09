import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/design_system/tokens/app_spacing.dart';
import '../models/league_model.dart';
import '../providers/league_provider.dart';

class AdminLigasPage extends ConsumerWidget {
  const AdminLigasPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ligasAsync = ref.watch(leaguesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ligas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: ligasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No fue posible cargar las ligas.\n$e')),
        data: (ligas) {
          if (ligas.isEmpty) {
            return const Center(child: Text('Todavía no hay ligas. Crea la primera.'));
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(leaguesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: ligas.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final liga = ligas[index];

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(liga.nombre.isNotEmpty ? liga.nombre[0].toUpperCase() : '?'),
                    ),
                    title: Text(liga.nombre),
                    subtitle: Text(
                      liga.descripcion.isNotEmpty ? liga.descripcion : liga.codigo,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showFormDialog(context, ref, liga: liga),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          tooltip: 'Eliminar',
                          onPressed: () => _confirmarEliminar(context, ref, liga),
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
        label: const Text('Nueva liga'),
      ),
    );
  }

  Future<void> _confirmarEliminar(
    BuildContext context,
    WidgetRef ref,
    LeagueModel liga,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar esta liga?'),
        content: Text(
          'Se eliminará "${liga.nombre}" de forma permanente. '
          'Si tiene temporadas ya creadas, es posible que no se pueda eliminar.',
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
      await ref.read(leagueServiceProvider).eliminar(liga.id);
      ref.invalidate(leaguesProvider);
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
    LeagueModel? liga,
  }) async {
    final esNuevo = liga == null;

    final codigoController = TextEditingController(text: liga?.codigo ?? '');
    final nombreController = TextEditingController(text: liga?.nombre ?? '');
    final descripcionController = TextEditingController(text: liga?.descripcion ?? '');
    var activo = liga?.activo ?? true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(esNuevo ? 'Nueva liga' : 'Editar liga'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                      controller: descripcionController,
                      decoration: const InputDecoration(labelText: 'Descripción'),
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

                    final service = ref.read(leagueServiceProvider);

                    try {
                      if (esNuevo) {
                        await service.crear(
                          codigo: codigoController.text.trim(),
                          nombre: nombreController.text.trim(),
                          descripcion: descripcionController.text.trim(),
                          activo: activo,
                        );
                      } else {
                        await service.actualizar(
                          id: liga.id,
                          nombre: nombreController.text.trim(),
                          descripcion: descripcionController.text.trim(),
                          activo: activo,
                        );
                      }

                      ref.invalidate(leaguesProvider);

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
