import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_route_names.dart';
import '../../../shared/design_system/tokens/app_colors.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/design_system/tokens/app_typography.dart';
import '../../../shared/design_system/widgets/forms/selector_imagen_widget.dart';
import '../../login/providers/auth_provider.dart';
import '../models/anuncio_model.dart';
import '../providers/communication_provider.dart';

class AnunciosPage extends ConsumerWidget {
  const AnunciosPage({super.key});

  bool _puedeCrear(WidgetRef ref) {
    final roles = ref.read(authProvider).user?.roles ?? const [];
    return roles.contains('Administrador') || roles.contains('Capturador');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anunciosAsync = ref.watch(anunciosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Anuncios'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouteNames.home),
        ),
      ),
      body: anunciosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No fue posible cargar los anuncios.\n$e')),
        data: (anuncios) {
          if (anuncios.isEmpty) {
            return const Center(child: Text('Todavía no hay anuncios.'));
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(anunciosProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: anuncios.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final anuncio = anuncios[index];

                return Card(
                  clipBehavior: Clip.antiAlias,
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (anuncio.imagenUrl != null && anuncio.imagenUrl!.isNotEmpty) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              anuncio.imagenUrl!,
                              width: double.infinity,
                              height: 160,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(anuncio.titulo, style: AppTypography.subtitle),
                            ),
                            if (_puedeCrear(ref))
                              PopupMenuButton<String>(
                                onSelected: (accion) {
                                  if (accion == 'editar') {
                                    _showEditarAnuncioDialog(context, ref, anuncio);
                                  } else if (accion == 'eliminar') {
                                    _confirmarEliminar(context, ref, anuncio);
                                  }
                                },
                                itemBuilder: (context) => const [
                                  PopupMenuItem(value: 'editar', child: Text('Editar')),
                                  PopupMenuItem(
                                    value: 'eliminar',
                                    child: Text('Eliminar', style: TextStyle(color: Colors.red)),
                                  ),
                                ],
                              ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(anuncio.contenido, style: AppTypography.body),
                        const SizedBox(height: AppSpacing.sm),
                        _FilaReacciones(anuncio: anuncio),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '${anuncio.autorNombre} · ${anuncio.fechaPublicacion.day}/${anuncio.fechaPublicacion.month}/${anuncio.fechaPublicacion.year}',
                          style: AppTypography.caption,
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
      floatingActionButton: _puedeCrear(ref)
          ? FloatingActionButton.extended(
              onPressed: () => _showCrearAnuncioDialog(context, ref),
              icon: const Icon(Icons.campaign),
              label: const Text('Nuevo anuncio'),
            )
          : null,
    );
  }

  Future<void> _showCrearAnuncioDialog(BuildContext context, WidgetRef ref) async {
    final tituloController = TextEditingController();
    final contenidoController = TextEditingController();
    String? imagenUrl;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('Nuevo anuncio'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SelectorImagenWidget(
                      urlActual: imagenUrl,
                      onCambio: (nuevaUrl) => setState(() => imagenUrl = nuevaUrl),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: tituloController,
                      decoration: const InputDecoration(labelText: 'Título'),
                    ),
                    TextField(
                      controller: contenidoController,
                      decoration: const InputDecoration(labelText: 'Contenido'),
                      maxLines: 4,
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
                    if (tituloController.text.trim().isEmpty ||
                        contenidoController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Título y contenido son obligatorios.')),
                      );
                      return;
                    }

                    try {
                      await ref.read(communicationServiceProvider).crearAnuncio(
                            titulo: tituloController.text.trim(),
                            contenido: contenidoController.text.trim(),
                            imagenUrl: imagenUrl,
                          );

                      ref.invalidate(anunciosProvider);

                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    } catch (e) {
                      if (dialogContext.mounted) {
                        ScaffoldMessenger.of(dialogContext).showSnackBar(
                          SnackBar(content: Text('No se pudo publicar: $e')),
                        );
                      }
                    }
                  },
                  child: const Text('Publicar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showEditarAnuncioDialog(
    BuildContext context,
    WidgetRef ref,
    AnuncioModel anuncio,
  ) async {
    final tituloController = TextEditingController(text: anuncio.titulo);
    final contenidoController = TextEditingController(text: anuncio.contenido);
    var reenviarPush = false;
    var imagenUrl = anuncio.imagenUrl;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('Editar anuncio'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SelectorImagenWidget(
                      urlActual: imagenUrl,
                      onCambio: (nuevaUrl) => setState(() => imagenUrl = nuevaUrl),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      controller: tituloController,
                      decoration: const InputDecoration(labelText: 'Título'),
                    ),
                    TextField(
                      controller: contenidoController,
                      decoration: const InputDecoration(labelText: 'Contenido'),
                      maxLines: 4,
                    ),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Reenviar notificación'),
                      subtitle: const Text('Avisa de nuevo a todos por push'),
                      value: reenviarPush,
                      onChanged: (value) => setState(() => reenviarPush = value),
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
                    if (tituloController.text.trim().isEmpty ||
                        contenidoController.text.trim().isEmpty) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Título y contenido son obligatorios.')),
                      );
                      return;
                    }

                    try {
                      await ref.read(communicationServiceProvider).editarAnuncio(
                            id: anuncio.id,
                            titulo: tituloController.text.trim(),
                            contenido: contenidoController.text.trim(),
                            reenviarPush: reenviarPush,
                            imagenUrl: imagenUrl,
                          );

                      ref.invalidate(anunciosProvider);

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

  Future<void> _confirmarEliminar(
    BuildContext context,
    WidgetRef ref,
    AnuncioModel anuncio,
  ) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar este anuncio?'),
        content: Text('Se eliminará "${anuncio.titulo}" de forma permanente.'),
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
      await ref.read(communicationServiceProvider).eliminarAnuncio(anuncio.id);
      ref.invalidate(anunciosProvider);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar: $e')),
        );
      }
    }
  }
}

/// Fila de reacciones rápidas — los emojis ya usados por alguien se
/// muestran con su conteo; el resto aparecen tenues, listos para
/// tocar. Tocar el emoji con el que ya reaccionaste lo quita.
class _FilaReacciones extends ConsumerWidget {
  const _FilaReacciones({required this.anuncio});

  final AnuncioModel anuncio;

  static const _emojisDisponibles = ['👍', '🔥', '😂', '❤️', '😮'];

  Future<void> _reaccionar(WidgetRef ref, String emoji) async {
    try {
      await ref.read(communicationServiceProvider).reaccionarAnuncio(
            anuncioId: anuncio.id,
            emoji: emoji,
          );
      ref.invalidate(anunciosProvider);
    } catch (_) {
      // Silencioso a propósito — una reacción fallida no amerita
      // interrumpir con un SnackBar, se puede volver a intentar.
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Wrap(
      spacing: 6,
      runSpacing: 4,
      children: _emojisDisponibles.map((emoji) {
        final conteo = anuncio.reacciones[emoji] ?? 0;
        final esMia = anuncio.miReaccion == emoji;

        return GestureDetector(
          onTap: () => _reaccionar(ref, emoji),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: esMia ? AppColors.secondary.withValues(alpha: 0.35) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(16),
              border: esMia ? Border.all(color: AppColors.primary, width: 1) : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(emoji, style: const TextStyle(fontSize: 15)),
                if (conteo > 0) ...[
                  const SizedBox(width: 4),
                  Text(
                    '$conteo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: esMia ? FontWeight.bold : FontWeight.normal,
                      color: esMia ? AppColors.primary : Colors.grey.shade700,
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}
