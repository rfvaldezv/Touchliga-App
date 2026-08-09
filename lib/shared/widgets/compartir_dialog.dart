import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../modules/communication/providers/communication_provider.dart';

/// Diálogo reutilizable para "compartir" una estadística/tarjeta con
/// otros participantes — reutiliza el mismo mecanismo de Mensajes
/// (uno, varios, o todos), como ya se usa en la Cobranza de Pagos.
Future<void> mostrarDialogoCompartir(
  BuildContext context,
  WidgetRef ref, {
  required String mensajeSugerido,
}) async {
  final mensajeController = TextEditingController(text: mensajeSugerido);
  final seleccionados = <int>{};
  var enviando = false;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Text('Compartir'),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: mensajeController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Mensaje'),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '¿A quién?',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                  ),
                  Flexible(
                    child: Consumer(
                      builder: (context, ref, _) {
                        final contactosAsync = ref.watch(todosLosParticipantesProvider);
                        return contactosAsync.when(
                      loading: () => const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(),
                      ),
                      error: (e, _) => Text('No fue posible cargar contactos.\n$e'),
                      data: (contactos) {
                        return SizedBox(
                          height: 240,
                          child: Column(
                            children: [
                              Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                  onPressed: () => setState(() {
                                    if (seleccionados.length == contactos.length) {
                                      seleccionados.clear();
                                    } else {
                                      seleccionados
                                        ..clear()
                                        ..addAll(contactos.map((c) => c.usuarioId));
                                    }
                                  }),
                                  child: const Text('Seleccionar todos'),
                                ),
                              ),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: contactos.length,
                                  itemBuilder: (context, i) {
                                    final c = contactos[i];
                                    return CheckboxListTile(
                                      dense: true,
                                      title: Text(c.nombre),
                                      value: seleccionados.contains(c.usuarioId),
                                      onChanged: (marcado) => setState(() {
                                        if (marcado ?? false) {
                                          seleccionados.add(c.usuarioId);
                                        } else {
                                          seleccionados.remove(c.usuarioId);
                                        }
                                      }),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: enviando ? null : () => Navigator.pop(dialogContext),
                child: const Text('Cancelar'),
              ),
              FilledButton.icon(
                onPressed: (enviando || seleccionados.isEmpty)
                    ? null
                    : () async {
                        if (mensajeController.text.trim().isEmpty) return;

                        setState(() => enviando = true);

                        final servicio = ref.read(communicationServiceProvider);
                        var fallos = 0;

                        for (final usuarioId in seleccionados) {
                          try {
                            await servicio.enviarMensaje(
                              destinatarioId: usuarioId,
                              contenido: mensajeController.text.trim(),
                            );
                          } catch (_) {
                            fallos++;
                          }
                        }

                        if (dialogContext.mounted) Navigator.pop(dialogContext);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                fallos == 0 ? '¡Compartido!' : 'Compartido, $fallos no se pudo enviar.',
                              ),
                            ),
                          );
                        }
                      },
                icon: const Icon(Icons.send),
                label: Text(enviando ? 'Enviando...' : 'Enviar'),
              ),
            ],
          );
        },
      );
    },
  );
}
