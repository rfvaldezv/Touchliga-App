import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_route_names.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
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
        onPressed: () => context.push('${AppRouteNames.messages}/nuevo'),
        icon: const Icon(Icons.edit),
        label: const Text('Escribir'),
      ),
    );
  }
}
