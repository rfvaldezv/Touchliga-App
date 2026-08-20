import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/design_system/theme/app_spacing.dart';
import '../../../shared/utils/whatsapp_helper.dart';
import '../models/contacto_model.dart';
import '../providers/communication_provider.dart';

enum _Canal { interno, whatsapp }

/// Compositor único: elige uno o varios destinatarios, elige el
/// canal (interno o WhatsApp), escribe el texto una sola vez, se
/// manda a todos los que eligió. Sin nada automático -- eso vive en
/// otras pantallas (recordatorios de Jornadas/Pagos).
class NuevoMensajePage extends ConsumerStatefulWidget {
  const NuevoMensajePage({super.key});

  @override
  ConsumerState<NuevoMensajePage> createState() => _NuevoMensajePageState();
}

class _NuevoMensajePageState extends ConsumerState<NuevoMensajePage> {
  final Set<int> _seleccionados = {};
  final _busquedaController = TextEditingController();
  final _mensajeController = TextEditingController();
  String _busqueda = '';
  _Canal _canal = _Canal.interno;
  var _enviando = false;

  @override
  void dispose() {
    _busquedaController.dispose();
    _mensajeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final participantesAsync = ref.watch(todosLosParticipantesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Nuevo mensaje')),
      body: participantesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No fue posible cargar participantes.\n$e')),
        data: (participantes) {
          final busquedaNormalizada = _busqueda.trim().toLowerCase();
          final filtrados = busquedaNormalizada.isEmpty
              ? participantes
              : participantes.where((p) => p.nombre.toLowerCase().contains(busquedaNormalizada)).toList();

          final seleccionablesWhatsapp = _canal == _Canal.whatsapp
              ? filtrados.where((p) => p.telefono != null && p.telefono!.isNotEmpty).toList()
              : filtrados;

          return Column(
            children: [
              // --- Selector de canal ---
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: SegmentedButton<_Canal>(
                  segments: const [
                    ButtonSegment(
                      value: _Canal.interno,
                      label: Text('Mensaje interno'),
                      icon: Icon(Icons.chat_bubble_outline),
                    ),
                    ButtonSegment(
                      value: _Canal.whatsapp,
                      label: Text('WhatsApp'),
                      icon: Icon(Icons.chat),
                    ),
                  ],
                  selected: {_canal},
                  onSelectionChanged: (nuevo) => setState(() => _canal = nuevo.first),
                ),
              ),

              // --- Buscador ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: TextField(
                  controller: _busquedaController,
                  decoration: InputDecoration(
                    hintText: 'Buscar participante...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _busqueda.isEmpty
                        ? null
                        : IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => setState(() {
                              _busquedaController.clear();
                              _busqueda = '';
                            }),
                          ),
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onChanged: (value) => setState(() => _busqueda = value),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              // --- Barra de selección rápida ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_seleccionados.length} seleccionado${_seleccionados.length == 1 ? '' : 's'}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        final idsVisibles = seleccionablesWhatsapp.map((p) => p.usuarioId).toSet();
                        if (idsVisibles.every(_seleccionados.contains)) {
                          _seleccionados.removeAll(idsVisibles);
                        } else {
                          _seleccionados.addAll(idsVisibles);
                        }
                      }),
                      child: const Text('Todos / ninguno'),
                    ),
                  ],
                ),
              ),

              // --- Lista de participantes ---
              Expanded(
                child: ListView.builder(
                  itemCount: filtrados.length,
                  itemBuilder: (context, index) {
                    final p = filtrados[index];
                    final tieneTelefono = p.telefono != null && p.telefono!.isNotEmpty;
                    final deshabilitado = _canal == _Canal.whatsapp && !tieneTelefono;

                    return CheckboxListTile(
                      value: _seleccionados.contains(p.usuarioId),
                      onChanged: deshabilitado
                          ? null
                          : (marcado) => setState(() {
                                if (marcado ?? false) {
                                  _seleccionados.add(p.usuarioId);
                                } else {
                                  _seleccionados.remove(p.usuarioId);
                                }
                              }),
                      title: Text(p.nombre),
                      subtitle: deshabilitado
                          ? const Text('Sin teléfono registrado', style: TextStyle(color: Colors.red))
                          : (p.roles.isNotEmpty ? Text(p.roles.join(', ')) : null),
                    );
                  },
                ),
              ),

              // --- Mensaje + enviar ---
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextField(
                      controller: _mensajeController,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        hintText: 'Escribe tu mensaje...',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    FilledButton.icon(
                      icon: _enviando
                          ? const SizedBox(
                              width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.send),
                      label: Text(_enviando ? 'Enviando...' : 'Enviar (${_seleccionados.length})'),
                      onPressed: _enviando || _seleccionados.isEmpty || _mensajeController.text.trim().isEmpty
                          ? null
                          : () => _enviar(participantes),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _enviar(List<ContactoModel> participantes) async {
    final texto = _mensajeController.text.trim();
    final destinatarios = participantes.where((p) => _seleccionados.contains(p.usuarioId)).toList();

    setState(() => _enviando = true);

    if (_canal == _Canal.interno) {
      final service = ref.read(communicationServiceProvider);
      for (final d in destinatarios) {
        try {
          await service.enviarMensaje(destinatarioId: d.usuarioId, contenido: texto);
        } catch (_) {
          // Si uno falla, se sigue con el resto -- no se detiene el envío completo.
        }
      }
    } else {
      for (final d in destinatarios) {
        final numeroLimpio = d.telefono!.replaceAll(RegExp(r'[^\d]'), '');
        final uri = Uri.parse('whatsapp://send?phone=$numeroLimpio&text=${Uri.encodeComponent(texto)}');
        if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
        await esperarAntesDelSiguienteWhatsApp();
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Mensaje enviado a ${destinatarios.length} participante${destinatarios.length == 1 ? '' : 's'}.')),
      );
      context.pop();
    }
  }
}
