import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_route_names.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../models/contacto_model.dart';
import '../providers/communication_provider.dart';

class MensajesPage extends ConsumerWidget {
  const MensajesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final contactosAsync = ref.watch(misContactosProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouteNames.home),
        ),
      ),
      body: contactosAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No fue posible cargar tus mensajes.\n$e')),
        data: (contactos) {
          if (contactos.isEmpty) {
            return const Center(
              child: Text('Todavía no tienes conversaciones. Usa el botón de abajo para escribir.'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(misContactosProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.md),
              itemCount: contactos.length,
              separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final contacto = contactos[index];

                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(contacto.nombre.isNotEmpty ? contacto.nombre[0].toUpperCase() : '?'),
                    ),
                    title: Text(contacto.nombre),
                    subtitle: Text(
                      contacto.ultimoMensaje,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: contacto.tieneNoLeidos
                        ? const CircleAvatar(radius: 6, backgroundColor: Colors.red)
                        : null,
                    onTap: () => context.push(
                      '${AppRouteNames.messages}/${contacto.usuarioId}',
                      extra: contacto.nombre,
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showElegirDestinatarioDialog(context, ref),
        icon: const Icon(Icons.edit),
        label: const Text('Escribir'),
      ),
    );
  }

  Future<void> _showElegirDestinatarioDialog(BuildContext context, WidgetRef ref) async {
    List<ContactoModel> participantes;

    try {
      participantes = await ref.read(todosLosParticipantesProvider.future);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo cargar la lista de participantes: $e')),
        );
      }
      return;
    }

    if (!context.mounted) return;

    if (participantes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay otros participantes registrados todavía.')),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        var busqueda = '';

        return StatefulBuilder(
          builder: (sheetContext, setState) {
            final filtrados = busqueda.isEmpty
                ? participantes
                : participantes
                    .where((p) => p.nombre.toLowerCase().contains(busqueda.toLowerCase()))
                    .toList();

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Escribir a...'),
                    const SizedBox(height: AppSpacing.sm),
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Buscar participante',
                        prefixIcon: Icon(Icons.search, size: 18),
                      ),
                      onChanged: (value) => setState(() => busqueda = value),
                    ),
                    SizedBox(
                      height: 300,
                      child: ListView(
                        children: [
                          for (final ContactoModel participante in filtrados)
                            ListTile(
                              leading: CircleAvatar(
                                child: Text(
                                  participante.nombre.isNotEmpty
                                      ? participante.nombre[0].toUpperCase()
                                      : '?',
                                ),
                              ),
                              title: Text(participante.nombre),
                              subtitle: participante.roles.isNotEmpty
                                  ? Text(participante.roles.join(', '))
                                  : null,
                              onTap: () {
                                Navigator.pop(sheetContext);
                                context.push(
                                  '${AppRouteNames.messages}/${participante.usuarioId}',
                                  extra: participante.nombre,
                                );
                              },
                            ),
                        ],
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
