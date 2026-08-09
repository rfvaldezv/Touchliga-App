import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/design_system/widgets/forms/selector_imagen_widget.dart';
import '../models/patrocinador_model.dart';
import '../providers/patrocinador_provider.dart';

class AdminPatrocinadoresPage extends ConsumerWidget {
  const AdminPatrocinadoresPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final patrocinadoresAsync = ref.watch(patrocinadoresTodosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Patrocinadores'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: patrocinadoresAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No fue posible cargar los patrocinadores.\n$e')),
        data: (patrocinadores) {
          if (patrocinadores.isEmpty) {
            return const Center(child: Text('Todavía no hay patrocinadores.'));
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(patrocinadoresTodosProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: patrocinadores.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final patrocinador = patrocinadores[index];

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: patrocinador.activo ? Colors.green : Colors.grey,
                      child: Text('${patrocinador.orden}'),
                    ),
                    title: Text(patrocinador.nombre),
                    subtitle: Text(patrocinador.enlaceUrl ?? 'Sin enlace'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined),
                          onPressed: () => _showFormDialog(context, ref, patrocinador: patrocinador),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline),
                          onPressed: () => _confirmarEliminar(context, ref, patrocinador),
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
        label: const Text('Nuevo patrocinador'),
      ),
    );
  }

  Future<void> _confirmarEliminar(
    BuildContext context,
    WidgetRef ref,
    PatrocinadorModel patrocinador,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar patrocinador?'),
        content: Text('Se eliminará "${patrocinador.nombre}" de forma permanente.'),
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

    await ref.read(patrocinadorServiceProvider).eliminar(patrocinador.id);
    ref.invalidate(patrocinadoresTodosProvider);
    ref.invalidate(patrocinadoresActivosProvider);
  }

  Future<void> _showFormDialog(
    BuildContext context,
    WidgetRef ref, {
    PatrocinadorModel? patrocinador,
  }) async {
    final esNuevo = patrocinador == null;

    final codigoController = TextEditingController(text: patrocinador?.codigo ?? '');
    final nombreController = TextEditingController(text: patrocinador?.nombre ?? '');
    final descripcionController = TextEditingController(text: patrocinador?.descripcion ?? '');
    var imagenUrl = patrocinador?.imagenUrl;
    final enlaceController = TextEditingController(text: patrocinador?.enlaceUrl ?? '');
    final ordenController = TextEditingController(text: (patrocinador?.orden ?? 1).toString());
    var activo = patrocinador?.activo ?? true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text(esNuevo ? 'Nuevo patrocinador' : 'Editar patrocinador'),
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
                    SelectorImagenWidget(
                      urlActual: imagenUrl,
                      onCambio: (nuevaUrl) => setState(() => imagenUrl = nuevaUrl),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: enlaceController,
                      decoration: const InputDecoration(
                        labelText: 'Enlace (opcional)',
                        hintText: 'https://...',
                      ),
                    ),
                    TextField(
                      controller: ordenController,
                      decoration: const InputDecoration(labelText: 'Orden de aparición'),
                      keyboardType: TextInputType.number,
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
                    if (nombreController.text.trim().isEmpty ||
                        imagenUrl == null ||
                        imagenUrl!.trim().isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Nombre e imagen son obligatorios.')),
                      );
                      return;
                    }

                    final service = ref.read(patrocinadorServiceProvider);
                    final orden = int.tryParse(ordenController.text) ?? 1;

                    try {
                      if (esNuevo) {
                        await service.crear(
                          codigo: codigoController.text.trim(),
                          nombre: nombreController.text.trim(),
                          descripcion: descripcionController.text.trim(),
                          imagenUrl: imagenUrl!,
                          enlaceUrl: enlaceController.text.trim().isEmpty
                              ? null
                              : enlaceController.text.trim(),
                          orden: orden,
                          activo: activo,
                        );
                      } else {
                        await service.actualizar(
                          id: patrocinador.id,
                          nombre: nombreController.text.trim(),
                          descripcion: descripcionController.text.trim(),
                          imagenUrl: imagenUrl!,
                          enlaceUrl: enlaceController.text.trim().isEmpty
                              ? null
                              : enlaceController.text.trim(),
                          orden: orden,
                          activo: activo,
                        );
                      }

                      ref.invalidate(patrocinadoresTodosProvider);
                      ref.invalidate(patrocinadoresActivosProvider);

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
