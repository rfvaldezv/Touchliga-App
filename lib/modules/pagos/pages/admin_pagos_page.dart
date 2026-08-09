import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/design_system/tokens/app_spacing.dart';
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
              Expanded(
                child: RefreshIndicator(
                  onRefresh: () async => ref.invalidate(estatusPagosProvider(temporadaId)),
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                    itemCount: estatus.length,
                    separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = estatus[index];
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
                          trailing: _modoSeleccion || item.pagoCompleto
                              ? null
                              : FilledButton(
                                  onPressed: () => _showRegistrarPagoDialog(
                                    context,
                                    ref,
                                    item,
                                    temporadaId,
                                  ),
                                  child: Text(esParcial ? 'Registrar resto' : 'Marcar pagado'),
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
          ? FloatingActionButton.extended(
              onPressed: () => _showCobranzaDialog(context, ref),
              icon: const Icon(Icons.send),
              label: Text('Enviar cobranza (${_seleccionados.length})'),
            )
          : null,
    );
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
}
