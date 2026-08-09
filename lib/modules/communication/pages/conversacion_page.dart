import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/services/archivo_service.dart';
import '../../login/providers/auth_provider.dart';
import '../models/mensaje_model.dart';
import '../providers/communication_provider.dart';

class ConversacionPage extends ConsumerStatefulWidget {
  const ConversacionPage({super.key, required this.otroUsuarioId, this.otroNombre});

  final int otroUsuarioId;
  final String? otroNombre;

  @override
  ConsumerState<ConversacionPage> createState() => _ConversacionPageState();
}

class _ConversacionPageState extends ConsumerState<ConversacionPage> {
  final _controller = TextEditingController();
  List<MensajeModel> _mensajes = [];
  bool _cargando = true;
  Object? _error;
  String? _imagenPendienteUrl;
  bool _subiendoImagen = false;

  Future<void> _elegirImagen() async {
    final resultado = await FilePicker.platform.pickFiles(type: FileType.image, withData: true);
    final archivo = resultado?.files.single;
    final Uint8List? bytes = archivo?.bytes;

    if (archivo == null || bytes == null) return;

    setState(() => _subiendoImagen = true);

    try {
      final url = await ArchivoService().subir(bytes, archivo.name);
      if (mounted) setState(() => _imagenPendienteUrl = url);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo subir la imagen: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _subiendoImagen = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() => _cargando = true);

    try {
      final service = ref.read(communicationServiceProvider);
      final mensajes = await service.getConversacion(widget.otroUsuarioId);
      await service.marcarConversacionLeida(widget.otroUsuarioId);

      if (mounted) {
        setState(() {
          _mensajes = mensajes;
          _cargando = false;
          _error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() { _error = e; _cargando = false; });
    }
  }

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    final imagenUrl = _imagenPendienteUrl;

    if (texto.isEmpty && imagenUrl == null) return;

    _controller.clear();
    setState(() => _imagenPendienteUrl = null);

    try {
      await ref.read(communicationServiceProvider).enviarMensaje(
            destinatarioId: widget.otroUsuarioId,
            contenido: texto,
            imagenUrl: imagenUrl,
          );
      await _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo enviar: $e')),
        );
      }
    }
  }

  Future<void> _showOpcionesMensaje(MensajeModel mensaje) async {
    final accion = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Editar'),
                onTap: () => Navigator.pop(sheetContext, 'editar'),
              ),
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Eliminar', style: TextStyle(color: Colors.red)),
                onTap: () => Navigator.pop(sheetContext, 'eliminar'),
              ),
            ],
          ),
        );
      },
    );

    if (accion == 'editar') {
      await _editarMensaje(mensaje);
    } else if (accion == 'eliminar') {
      await _eliminarMensaje(mensaje);
    }
  }

  Future<void> _editarMensaje(MensajeModel mensaje) async {
    final controller = TextEditingController(text: mensaje.contenido);
    var reenviarPush = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: const Text('Editar mensaje'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: controller,
                    decoration: const InputDecoration(labelText: 'Mensaje'),
                    maxLines: 4,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Reenviar notificación'),
                    value: reenviarPush,
                    onChanged: (value) => setState(() => reenviarPush = value),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    if (controller.text.trim().isEmpty) return;

                    try {
                      await ref.read(communicationServiceProvider).editarMensaje(
                            id: mensaje.id,
                            contenido: controller.text.trim(),
                            reenviarPush: reenviarPush,
                          );

                      await _cargar();

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

  Future<void> _eliminarMensaje(MensajeModel mensaje) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('¿Eliminar este mensaje?'),
        content: const Text('Se eliminará para ambos, de forma permanente.'),
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
      await ref.read(communicationServiceProvider).eliminarMensaje(mensaje.id);
      await _cargar();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo eliminar: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final miUsuarioId = ref.watch(authProvider).user?.userId;

    return Scaffold(
      appBar: AppBar(title: Text(widget.otroNombre ?? 'Conversación')),
      body: Column(
        children: [
          Expanded(
            child: _cargando
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('No fue posible cargar la conversación.\n$_error'))
                    : _mensajes.isEmpty
                        ? const Center(child: Text('Todavía no hay mensajes. Escribe el primero.'))
                        : ListView.builder(
                            reverse: true,
                            padding: const EdgeInsets.all(AppSpacing.md),
                            itemCount: _mensajes.length,
                            itemBuilder: (context, index) {
                              final mensaje = _mensajes[_mensajes.length - 1 - index];
                              final esMio = mensaje.remitenteId == miUsuarioId;

                              return Align(
                                alignment: esMio ? Alignment.centerRight : Alignment.centerLeft,
                                child: GestureDetector(
                                  onLongPress: esMio ? () => _showOpcionesMensaje(mensaje) : null,
                                  child: Container(
                                    margin: const EdgeInsets.symmetric(vertical: 4),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm,
                                    ),
                                    constraints: BoxConstraints(
                                      maxWidth: MediaQuery.of(context).size.width * 0.75,
                                    ),
                                    decoration: BoxDecoration(
                                      color: esMio
                                          ? Theme.of(context).colorScheme.primaryContainer
                                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        if (mensaje.imagenUrl != null && mensaje.imagenUrl!.isNotEmpty) ...[
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: Image.network(
                                              mensaje.imagenUrl!,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) =>
                                                  const SizedBox.shrink(),
                                            ),
                                          ),
                                          if (mensaje.contenido.isNotEmpty)
                                            const SizedBox(height: AppSpacing.xs),
                                        ],
                                        if (mensaje.contenido.isNotEmpty) Text(mensaje.contenido),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
          ),
          SafeArea(
            top: false,
            minimum: const EdgeInsets.all(AppSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_imagenPendienteUrl != null || _subiendoImagen)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: Stack(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _subiendoImagen
                              ? const SizedBox(
                                  width: 70,
                                  height: 70,
                                  child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                )
                              : Image.network(_imagenPendienteUrl!, width: 70, height: 70, fit: BoxFit.cover),
                        ),
                        if (!_subiendoImagen)
                          Positioned(
                            top: -8,
                            right: -8,
                            child: IconButton(
                              icon: const Icon(Icons.cancel, size: 18),
                              onPressed: () => setState(() => _imagenPendienteUrl = null),
                            ),
                          ),
                      ],
                    ),
                  ),
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.image_outlined),
                      tooltip: 'Adjuntar imagen',
                      onPressed: _subiendoImagen ? null : _elegirImagen,
                    ),
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: 'Escribe un mensaje...',
                          border: OutlineInputBorder(),
                        ),
                        onSubmitted: (_) => _enviar(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton.filled(
                      onPressed: _enviar,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
