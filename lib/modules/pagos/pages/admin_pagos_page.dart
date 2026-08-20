import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/utils/whatsapp_helper.dart';
import '../../../shared/providers/seleccion_provider.dart';
import '../../communication/providers/communication_provider.dart';
import '../../temporadas/providers/temporada_provider.dart';
import '../models/estatus_pago_model.dart';
import '../providers/pagos_provider.dart';

class AdminPagosPage extends ConsumerStatefulWidget {
  const AdminPagosPage({super.key});

  @override
  ConsumerState<AdminPagosPage> createState() => _AdminPagosPageState();
}

class _AdminPagosPageState extends ConsumerState<AdminPagosPage> {
  bool _modoSeleccion = false;
  final Set<int> _seleccionados = {};
  final _busquedaController = TextEditingController();
  String _busqueda = '';
  String? _filtroEstatus; // null = todos, 'completo', 'parcial', 'pendiente'

  @override
  void dispose() {
    _busquedaController.dispose();
    super.dispose();
  }

  void _alternarSeleccion(int usuarioId) {
    setState(() {
      if (_seleccionados.contains(usuarioId)) {
        _seleccionados.remove(usuarioId);
      } else {
        _seleccionados.add(usuarioId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final temporadaIdSeleccionada = ref.watch(seleccionProvider).temporadaId;

    if (temporadaIdSeleccionada != null) {
      return _buildConTemporada(context, temporadaIdSeleccionada);
    }

    // Sin selección previa (no se pasó por "Mis ligas") — se elige
    // sola la temporada más reciente, igual que ya hace Pronósticos,
    // para no dejar la pantalla en blanco esperando una navegación
    // que no es obvia.
    final temporadasAsync = ref.watch(temporadasProvider);

    return temporadasAsync.when(
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        appBar: AppBar(title: const Text('Pagos')),
        body: Center(child: Text('No fue posible cargar temporadas.\n$e')),
      ),
      data: (temporadas) {
        if (temporadas.isEmpty) {
          return Scaffold(
            appBar: AppBar(title: const Text('Pagos')),
            body: const Center(child: Text('Todavía no hay temporadas.')),
          );
        }

        final masReciente = ([...temporadas]..sort((a, b) => b.id.compareTo(a.id))).first;
        return _buildConTemporada(context, masReciente.id);
      },
    );
  }

  Widget _buildConTemporada(BuildContext context, int temporadaId) {
    final estatusAsync = ref.watch(estatusPagosProvider(temporadaId));

    return Scaffold(
      appBar: AppBar(
        title: Text(_modoSeleccion ? '${_seleccionados.length} seleccionados' : 'Pagos'),
        leading: IconButton(
          icon: Icon(_modoSeleccion ? Icons.close : Icons.arrow_back),
          onPressed: () {
            if (_modoSeleccion) {
              setState(() {
                _modoSeleccion = false;
                _seleccionados.clear();
              });
            } else {
              context.pop();
            }
          },
        ),
        actions: [
          if (!_modoSeleccion)
            IconButton(
              icon: const Icon(Icons.campaign_outlined),
              tooltip: 'Mandar cobranza',
              onPressed: () => setState(() => _modoSeleccion = true),
            ),
        ],
      ),
      body: estatusAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No fue posible cargar los pagos.\n$e')),
        data: (estatus) {
          final completos = estatus.where((e) => e.pagoCompleto).length;
          final quienesDeben = estatus.where((e) => !e.pagoCompleto).map((e) => e.usuarioId).toSet();

          final busquedaNormalizada = _busqueda.trim().toLowerCase();

          final estatusFiltrado = estatus.where((item) {
            final coincideTexto = busquedaNormalizada.isEmpty ||
                item.usuarioNombre.toLowerCase().contains(busquedaNormalizada);

            final esParcialItem = !item.pagoCompleto && item.totalPagado > 0;
            final coincideEstatus = _filtroEstatus == null ||
                (_filtroEstatus == 'completo' && item.pagoCompleto) ||
                (_filtroEstatus == 'parcial' && esParcialItem) ||
                (_filtroEstatus == 'pendiente' && !item.pagoCompleto && !esParcialItem);

            return coincideTexto && coincideEstatus;
          }).toList();

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '$completos de ${estatus.length} participantes ya cubrieron su cuota',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    if (_modoSeleccion)
                      TextButton(
                        onPressed: () => setState(() {
                          if (_seleccionados.length == quienesDeben.length) {
                            _seleccionados.clear();
                          } else {
                            _seleccionados
                              ..clear()
                              ..addAll(quienesDeben);
                          }
                        }),
                        child: const Text('Seleccionar todos los que deben'),
                      ),
                  ],
                ),
              ),
              if (!_modoSeleccion) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpacing.md, 0, AppSpacing.md, AppSpacing.sm),
                  child: TextField(
                    controller: _busquedaController,
                    decoration: InputDecoration(
                      hintText: 'Buscar por nombre...',
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md).copyWith(bottom: AppSpacing.sm),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        ChoiceChip(
                          label: const Text('Todos'),
                          selected: _filtroEstatus == null,
                          onSelected: (_) => setState(() => _filtroEstatus = null),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        ChoiceChip(
                          label: const Text('Completos'),
                          selected: _filtroEstatus == 'completo',
                          onSelected: (_) => setState(() => _filtroEstatus = 'completo'),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        ChoiceChip(
                          label: const Text('Parciales'),
                          selected: _filtroEstatus == 'parcial',
                          onSelected: (_) => setState(() => _filtroEstatus = 'parcial'),
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        ChoiceChip(
                          label: const Text('Pendientes'),
                          selected: _filtroEstatus == 'pendiente',
                          onSelected: (_) => setState(() => _filtroEstatus = 'pendiente'),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
              if (estatusFiltrado.isEmpty)
                const Expanded(
                  child: Center(child: Text('Ningún participante coincide con el filtro.')),
                )
              else
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => ref.invalidate(estatusPagosProvider(temporadaId)),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: estatusFiltrado.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = estatusFiltrado[index];
                      final esParcial = !item.pagoCompleto && item.totalPagado > 0;
                      final seleccionado = _seleccionados.contains(item.usuarioId);

                      return Card(
                        child: ListTile(
                          onTap: _modoSeleccion
                              ? () => _alternarSeleccion(item.usuarioId)
                              : () => context.push(
                                    '/administration/pagos/cuenta-corriente/${item.usuarioId}',
                                  ),
                          leading: _modoSeleccion
                              ? Checkbox(
                                  value: seleccionado,
                                  onChanged: (_) => _alternarSeleccion(item.usuarioId),
                                )
                              : Icon(
                                  item.pagoCompleto
                                      ? Icons.check_circle
                                      : (esParcial ? Icons.incomplete_circle : Icons.pending_outlined),
                                  color: item.pagoCompleto
                                      ? Colors.green
                                      : (esParcial ? Colors.amber.shade700 : Colors.orange),
                                ),
                          title: Text(item.usuarioNombre),
                          subtitle: Text(
                            item.pagoCompleto
                                ? 'Completo · \$${item.totalPagado.toStringAsFixed(2)}'
                                : esParcial
                                    ? 'Parcial: \$${item.totalPagado.toStringAsFixed(2)} de \$${item.cuota.toStringAsFixed(2)} (faltan \$${item.saldoPendiente.toStringAsFixed(2)})'
                                    : 'Pendiente — \$${item.cuota.toStringAsFixed(2)}',
                          ),
                          trailing: _modoSeleccion
                              ? null
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (!item.pagoCompleto && item.telefono != null && item.telefono!.isNotEmpty) ...[
                                      IconButton(
                                        tooltip: 'WhatsApp (recordatorio de saldo)',
                                        icon: const Icon(Icons.chat_bubble_outline, color: Colors.green),
                                        onPressed: () => _abrirWhatsAppSaldo(item.telefono!, item.usuarioNombre, item.saldoPendiente),
                                      ),
                                      IconButton(
                                        tooltip: 'WhatsApp (escribir mensaje)',
                                        icon: const Icon(Icons.edit_note, color: Colors.green),
                                        onPressed: () => _abrirWhatsAppPersonalizado(context, item.telefono!, item.usuarioNombre),
                                      ),
                                    ],
                                    if (!item.pagoCompleto)
                                      FilledButton(
                                        onPressed: () => _showRegistrarPagoDialog(
                                          context,
                                          ref,
                                          item,
                                          temporadaId,
                                        ),
                                        child: Text(esParcial ? 'Registrar resto' : 'Registrar pago'),
                                      ),
                                  ],
                                ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: _modoSeleccion && _seleccionados.isNotEmpty
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                FloatingActionButton.extended(
                  heroTag: 'whatsapp-masivo',
                  backgroundColor: Colors.green,
                  onPressed: () => _enviarWhatsAppMasivo(context, ref),
                  icon: const Icon(Icons.chat_bubble_outline),
                  label: Text('WhatsApp (${_seleccionados.length})'),
                ),
                const SizedBox(height: AppSpacing.sm),
                FloatingActionButton.extended(
                  heroTag: 'cobranza-app',
                  onPressed: () => _showCobranzaDialog(context, ref),
                  icon: const Icon(Icons.send),
                  label: Text('Enviar cobranza (${_seleccionados.length})'),
                ),
              ],
            )
          : null,
    );
  }

  Future<void> _enviarWhatsAppMasivo(BuildContext context, WidgetRef ref) async {
    final temporadaId = ref.read(seleccionProvider).temporadaId;
    if (temporadaId == null) return;

    final estatus = ref.read(estatusPagosProvider(temporadaId)).value ?? [];
    final seleccionadosConTelefono = estatus
        .where((e) => _seleccionados.contains(e.usuarioId) && e.telefono != null && e.telefono!.isNotEmpty)
        .toList();

    if (seleccionadosConTelefono.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ninguno de los seleccionados tiene teléfono registrado.')),
      );
      return;
    }

    for (final item in seleccionadosConTelefono) {
      final numeroLimpio = item.telefono!.replaceAll(RegExp(r'[^\d]'), '');
      final primerNombre = item.usuarioNombre.split(' ').first;
      final mensaje =
          'Hola $primerNombre! 🏈 Te recuerdo que tienes un saldo pendiente de \$${item.saldoPendiente.toStringAsFixed(2)} '
          'en Touchliga. ¡Gracias por tu apoyo!';

      final uri = Uri.parse('whatsapp://send?phone=$numeroLimpio&text=${Uri.encodeComponent(mensaje)}');
      if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);

      // Pausa entre cada uno -- le da tiempo a WhatsApp Web/tu
      // automatización de clic de procesar antes de abrir el
      // siguiente, y reduce el riesgo de que el navegador bloquee
      // varias ventanas abriéndose de golpe.
      await esperarAntesDelSiguienteWhatsApp();
    }

    if (context.mounted) {
      setState(() {
        _modoSeleccion = false;
        _seleccionados.clear();
      });
    }
  }

  Future<void> _showCobranzaDialog(BuildContext context, WidgetRef ref) async {
    final mensajeController = TextEditingController(
      text: 'Hola 👋 Te recordamos que tienes pendiente el pago de tu cuota de la temporada. '
          '¡Cualquier duda, avísanos!',
    );
    var enviando = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              title: Text('Mandar cobranza a ${_seleccionados.length} participante(s)'),
              content: TextField(
                controller: mensajeController,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Mensaje'),
              ),
              actions: [
                TextButton(
                  onPressed: enviando ? null : () => Navigator.pop(dialogContext),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: enviando
                      ? null
                      : () async {
                          if (mensajeController.text.trim().isEmpty) return;

                          setStateDialog(() => enviando = true);

                          final servicio = ref.read(communicationServiceProvider);
                          var fallos = 0;

                          for (final usuarioId in _seleccionados) {
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

                          if (mounted) {
                            setState(() {
                              _modoSeleccion = false;
                              _seleccionados.clear();
                            });

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  fallos == 0
                                      ? 'Cobranza enviada.'
                                      : 'Cobranza enviada, $fallos no se pudo mandar.',
                                ),
                              ),
                            );
                          }
                        },
                  child: enviando
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Enviar'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showRegistrarPagoDialog(
    BuildContext context,
    WidgetRef ref,
    EstatusPagoModel item,
    int temporadaId,
  ) async {
    final montoController = TextEditingController();
    final referenciaController = TextEditingController();
    var metodoPago = 'Efectivo';
    var fechaPago = DateTime.now();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setState) {
            return AlertDialog(
              title: Text('Registrar pago — ${item.usuarioNombre}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: montoController,
                    decoration: const InputDecoration(labelText: 'Monto'),
                    keyboardType: TextInputType.number,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: metodoPago,
                    decoration: const InputDecoration(labelText: 'Método de pago'),
                    items: const [
                      DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
                      DropdownMenuItem(value: 'Transferencia', child: Text('Transferencia')),
                      DropdownMenuItem(value: 'Tarjeta', child: Text('Tarjeta')),
                      DropdownMenuItem(value: 'Otro', child: Text('Otro')),
                    ],
                    onChanged: (value) => setState(() => metodoPago = value!),
                  ),
                  TextField(
                    controller: referenciaController,
                    decoration: const InputDecoration(
                      labelText: 'Referencia (opcional)',
                      hintText: 'Núm. de transferencia, folio, etc.',
                    ),
                  ),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Fecha de pago'),
                    subtitle: Text('${fechaPago.day}/${fechaPago.month}/${fechaPago.year}'),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: dialogContext,
                        initialDate: fechaPago,
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) setState(() => fechaPago = picked);
                    },
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
                    final monto = double.tryParse(montoController.text);

                    if (monto == null || monto <= 0) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        const SnackBar(content: Text('Captura un monto válido.')),
                      );
                      return;
                    }

                    try {
                      await ref.read(pagosServiceProvider).registrarPago(
                            usuarioId: item.usuarioId,
                            temporadaId: temporadaId,
                            monto: monto,
                            metodoPago: metodoPago,
                            fechaPago: fechaPago,
                            referencia: referenciaController.text.trim().isEmpty
                                ? null
                                : referenciaController.text.trim(),
                          );

                      ref.invalidate(estatusPagosProvider(temporadaId));

                      if (dialogContext.mounted) Navigator.pop(dialogContext);
                    } catch (e) {
                      ScaffoldMessenger.of(dialogContext).showSnackBar(
                        SnackBar(content: Text('No se pudo registrar: $e')),
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

  Future<void> _abrirWhatsAppSaldo(String telefono, String nombre, double saldoPendiente) async {
    final numeroLimpio = telefono.replaceAll(RegExp(r'[^\d]'), '');
    final primerNombre = nombre.split(' ').first;
    final mensaje =
        'Hola $primerNombre! 🏈 Te recuerdo que tienes un saldo pendiente de \$${saldoPendiente.toStringAsFixed(2)} '
        'en Touchliga. ¡Gracias por tu apoyo!';

    final uri = Uri.parse('whatsapp://send?phone=$numeroLimpio&text=${Uri.encodeComponent(mensaje)}');
    if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _abrirWhatsAppPersonalizado(BuildContext context, String telefono, String nombre) async {
    final controller = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Mensaje para $nombre'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Escribe tu mensaje...',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              icon: const Icon(Icons.send, size: 18),
              label: const Text('Abrir WhatsApp'),
              onPressed: () async {
                final numeroLimpio = telefono.replaceAll(RegExp(r'[^\d]'), '');
                final texto = controller.text.trim();
                final uri = Uri.parse(
                  'whatsapp://send?phone=$numeroLimpio${texto.isEmpty ? '' : '&text=${Uri.encodeComponent(texto)}'}',
                );
                if (await canLaunchUrl(uri)) await launchUrl(uri, mode: LaunchMode.externalApplication);
                if (dialogContext.mounted) Navigator.of(dialogContext).pop();
              },
            ),
          ],
        );
      },
    );
  }
}
