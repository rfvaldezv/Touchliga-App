import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../shared/design_system/theme/app_spacing.dart';
import '../../../shared/utils/whatsapp_helper.dart';
import '../providers/reportes_provider.dart';

class ParticipantesPendientesPage extends ConsumerStatefulWidget {
  const ParticipantesPendientesPage({super.key, required this.jornadaId});

  final int jornadaId;

  @override
  ConsumerState<ParticipantesPendientesPage> createState() => _ParticipantesPendientesPageState();
}

class _ParticipantesPendientesPageState extends ConsumerState<ParticipantesPendientesPage> {
  bool _modoSeleccion = false;
  final Set<int> _seleccionados = {};

  @override
  Widget build(BuildContext context) {
    final pendientesAsync = ref.watch(participantesPendientesProvider(widget.jornadaId));

    return Scaffold(
      appBar: AppBar(
        title: Text(_modoSeleccion ? '${_seleccionados.length} seleccionados' : 'Faltan por capturar'),
        leading: _modoSeleccion
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => setState(() {
                  _modoSeleccion = false;
                  _seleccionados.clear();
                }),
              )
            : null,
        actions: [
          if (!_modoSeleccion) ...[
            IconButton(
              tooltip: 'Seleccionar varios',
              icon: const Icon(Icons.checklist),
              onPressed: () => setState(() => _modoSeleccion = true),
            ),
            IconButton(
              tooltip: 'Actualizar',
              icon: const Icon(Icons.refresh),
              onPressed: () => ref.invalidate(participantesPendientesProvider(widget.jornadaId)),
            ),
          ],
        ],
      ),
      body: pendientesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Text('No fue posible cargar la lista.\n$error', textAlign: TextAlign.center),
          ),
        ),
        data: (pendientes) {
          if (pendientes.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.celebration_outlined, size: 56, color: Colors.green),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      '¡Todos capturaron sus pronósticos!',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            );
          }

          final sinNada = pendientes.where((p) => p.sinNada).length;
          final conTelefono = pendientes.where((p) => p.telefono != null && p.telefono!.isNotEmpty).toList();

          return Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                color: Colors.orange.shade50,
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${pendientes.length} participante${pendientes.length == 1 ? '' : 's'} con captura pendiente'
                        '${sinNada > 0 ? ' ($sinNada sin capturar nada todavía)' : ''}.',
                        style: TextStyle(color: Colors.orange.shade900, fontWeight: FontWeight.w600),
                      ),
                    ),
                    if (_modoSeleccion)
                      TextButton(
                        onPressed: () => setState(() {
                          if (_seleccionados.length == conTelefono.length) {
                            _seleccionados.clear();
                          } else {
                            _seleccionados
                              ..clear()
                              ..addAll(conTelefono.map((p) => p.usuarioId));
                          }
                        }),
                        child: const Text('Todos'),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                  itemCount: pendientes.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final p = pendientes[index];
                    final seleccionado = _seleccionados.contains(p.usuarioId);
                    final tieneTelefono = p.telefono != null && p.telefono!.isNotEmpty;

                    return ListTile(
                      onTap: _modoSeleccion && tieneTelefono
                          ? () => setState(() {
                                if (seleccionado) {
                                  _seleccionados.remove(p.usuarioId);
                                } else {
                                  _seleccionados.add(p.usuarioId);
                                }
                              })
                          : null,
                      leading: _modoSeleccion
                          ? Checkbox(
                              value: seleccionado,
                              onChanged: tieneTelefono
                                  ? (_) => setState(() {
                                        if (seleccionado) {
                                          _seleccionados.remove(p.usuarioId);
                                        } else {
                                          _seleccionados.add(p.usuarioId);
                                        }
                                      })
                                  : null,
                            )
                          : CircleAvatar(
                              backgroundColor: p.sinNada ? Colors.red.shade100 : Colors.orange.shade100,
                              child: Icon(
                                p.sinNada ? Icons.person_off_outlined : Icons.pending_outlined,
                                color: p.sinNada ? Colors.red.shade700 : Colors.orange.shade800,
                              ),
                            ),
                      title: Text(p.nombre),
                      subtitle: Text(
                        p.sinNada
                            ? 'No ha capturado nada (0 de ${p.totalPartidos})'
                            : 'Le faltan ${p.faltantes} de ${p.totalPartidos}',
                      ),
                      trailing: _modoSeleccion
                          ? null
                          : Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (tieneTelefono)
                                  IconButton(
                                    tooltip: 'WhatsApp (recordatorio automático)',
                                    icon: const Icon(Icons.chat_bubble_outline, color: Colors.green),
                                    onPressed: () => _abrirWhatsApp(p.telefono!, p.nombre, p.faltantes, p.sinNada),
                                  ),
                                IconButton(
                                  tooltip: 'Correo',
                                  icon: const Icon(Icons.email_outlined),
                                  onPressed: () => _abrirCorreo(p.correo),
                                ),
                              ],
                            ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _modoSeleccion && _seleccionados.isNotEmpty
          ? FloatingActionButton.extended(
              backgroundColor: Colors.green,
              onPressed: () => _enviarRecordatorioMasivo(),
              icon: const Icon(Icons.chat_bubble_outline),
              label: Text('Recordatorio (${_seleccionados.length})'),
            )
          : null,
    );
  }

  Future<void> _enviarRecordatorioMasivo() async {
    final pendientes = ref.read(participantesPendientesProvider(widget.jornadaId)).value ?? [];
    final seleccionados = pendientes.where((p) => _seleccionados.contains(p.usuarioId)).toList();

    for (final p in seleccionados) {
      await _abrirWhatsApp(p.telefono!, p.nombre, p.faltantes, p.sinNada);
      await esperarAntesDelSiguienteWhatsApp();
    }

    if (mounted) {
      setState(() {
        _modoSeleccion = false;
        _seleccionados.clear();
      });
    }
  }

  Future<void> _abrirWhatsApp(String telefono, String nombre, int faltantes, bool sinNada) async {
    final numeroLimpio = telefono.replaceAll(RegExp(r'[^\d]'), '');
    final primerNombre = nombre.split(' ').first;

    final mensaje = sinNada
        ? 'Hola $primerNombre! 🏈 Te recuerdo que todavía no capturas tus pronósticos de esta jornada en Touchliga. ¡No dejes pasar la oportunidad de sumar puntos!'
        : 'Hola $primerNombre! 🏈 Te faltan $faltantes pronóstico${faltantes == 1 ? '' : 's'} por capturar en esta jornada de Touchliga. ¡Complétalos antes de que cierre!';

    final uri = Uri.parse('whatsapp://send?phone=$numeroLimpio&text=${Uri.encodeComponent(mensaje)}');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _abrirCorreo(String correo) async {
    final uri = Uri(scheme: 'mailto', path: correo);
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }
}
