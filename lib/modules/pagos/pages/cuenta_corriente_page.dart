import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/design_system/tokens/app_spacing.dart';
import '../models/cuenta_corriente_model.dart';
import '../models/pago_model.dart';
import '../providers/pagos_provider.dart';

/// Cuenta corriente completa de un participante — todas las
/// temporadas donde tiene cuota, cuánto ha pagado y qué le falta.
class CuentaCorrientePage extends ConsumerWidget {
  const CuentaCorrientePage({super.key, required this.usuarioId});

  final int usuarioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cuentaAsync = ref.watch(cuentaCorrienteProvider(usuarioId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cuenta corriente'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: cuentaAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No fue posible cargar la cuenta corriente.\n$e')),
        data: (cuenta) {
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.md),
            children: [
              Text(
                cuenta.usuarioNombre,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: AppSpacing.md),
              Card(
                color: cuenta.saldoTotal > 0 ? Colors.orange.shade50 : Colors.green.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _Totalito(etiqueta: 'Adeudado', valor: cuenta.totalAdeudado),
                      _Totalito(etiqueta: 'Pagado', valor: cuenta.totalPagado, color: Colors.green),
                      _Totalito(
                        etiqueta: 'Saldo',
                        valor: cuenta.saldoTotal,
                        color: cuenta.saldoTotal > 0 ? Colors.red : Colors.green,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (cuenta.temporadas.isEmpty)
                const Text('Sin movimientos registrados.')
              else
                ...cuenta.temporadas.map((t) => _TemporadaCard(temporada: t, usuarioId: usuarioId)),
            ],
          );
        },
      ),
    );
  }
}

class _Totalito extends StatelessWidget {
  const _Totalito({required this.etiqueta, required this.valor, this.color});

  final String etiqueta;
  final double valor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(etiqueta, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          '\$${valor.toStringAsFixed(2)}',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}

class _TemporadaCard extends ConsumerWidget {
  const _TemporadaCard({required this.temporada, required this.usuarioId});

  final CuentaCorrienteTemporadaModel temporada;
  final int usuarioId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      child: ExpansionTile(
        leading: Icon(
          temporada.pagoCompleto ? Icons.check_circle : Icons.pending_outlined,
          color: temporada.pagoCompleto ? Colors.green : Colors.orange,
        ),
        title: Text(temporada.temporadaNombre),
        subtitle: Text(
          temporada.pagoCompleto
              ? 'Cubierto · \$${temporada.totalPagado.toStringAsFixed(2)}'
              : '\$${temporada.totalPagado.toStringAsFixed(2)} de \$${temporada.cuota.toStringAsFixed(2)} — faltan \$${temporada.saldoPendiente.toStringAsFixed(2)}',
        ),
        children: temporada.pagos.isEmpty
            ? [const ListTile(title: Text('Sin pagos registrados todavía.'))]
            : temporada.pagos
                .map(
                  (p) => ListTile(
                    dense: true,
                    leading: const Icon(Icons.receipt_long, size: 18),
                    title: Text('\$${p.monto.toStringAsFixed(2)} · ${p.metodoPago}'),
                    subtitle: Text('${p.fechaPago.day}/${p.fechaPago.month}/${p.fechaPago.year}'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Editar pago',
                          onPressed: () => _showEditarPagoDialog(context, ref, p, usuarioId),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          tooltip: 'Eliminar pago',
                          onPressed: () => _confirmarEliminarPago(context, ref, p, usuarioId),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
      ),
    );
  }
}

Future<void> _showEditarPagoDialog(
  BuildContext context,
  WidgetRef ref,
  PagoModel pago,
  int usuarioId,
) async {
  final montoController = TextEditingController(text: pago.monto.toStringAsFixed(2));
  final metodoController = TextEditingController(text: pago.metodoPago);
  final referenciaController = TextEditingController(text: pago.referencia ?? '');
  var fecha = pago.fechaPago;
  var enviando = false;
  String? error;

  await showDialog<void>(
    context: context,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (dialogContext, setState) {
          return AlertDialog(
            title: const Text('Editar pago'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: montoController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Monto'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: metodoController,
                    decoration: const InputDecoration(labelText: 'Método de pago'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  TextField(
                    controller: referenciaController,
                    decoration: const InputDecoration(labelText: 'Referencia (opcional)'),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Fecha: ${fecha.day}/${fecha.month}/${fecha.year}'),
                    trailing: const Icon(Icons.calendar_today, size: 18),
                    onTap: () async {
                      final elegida = await showDatePicker(
                        context: dialogContext,
                        initialDate: fecha,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (elegida != null) setState(() => fecha = elegida);
                    },
                  ),
                  if (error != null) ...[
                    const SizedBox(height: AppSpacing.sm),
                    Text(error!, style: const TextStyle(color: Colors.red, fontSize: 12)),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: enviando ? null : () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: enviando
                    ? null
                    : () async {
                        final monto = double.tryParse(montoController.text.trim());
                        if (monto == null || monto <= 0 || metodoController.text.trim().isEmpty) {
                          setState(() => error = 'Captura un monto válido y el método de pago.');
                          return;
                        }
                        setState(() {
                          enviando = true;
                          error = null;
                        });
                        try {
                          await ref.read(pagosServiceProvider).editarPago(
                                id: pago.id,
                                monto: monto,
                                metodoPago: metodoController.text.trim(),
                                fechaPago: fecha,
                                referencia: referenciaController.text.trim().isEmpty
                                    ? null
                                    : referenciaController.text.trim(),
                              );
                          ref.invalidate(cuentaCorrienteProvider(usuarioId));
                          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                        } catch (e) {
                          setState(() {
                            error = 'No se pudo guardar: $e';
                            enviando = false;
                          });
                        }
                      },
                child: enviando
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Guardar'),
              ),
            ],
          );
        },
      );
    },
  );
}

Future<void> _confirmarEliminarPago(
  BuildContext context,
  WidgetRef ref,
  PagoModel pago,
  int usuarioId,
) async {
  final confirmar = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      return AlertDialog(
        title: const Text('¿Eliminar este pago?'),
        content: Text(
          'Se eliminará el pago de \$${pago.monto.toStringAsFixed(2)} (${pago.metodoPago}). Esta acción no se puede deshacer.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      );
    },
  );

  if (confirmar != true) return;

  try {
    await ref.read(pagosServiceProvider).eliminarPago(pago.id);
    ref.invalidate(cuentaCorrienteProvider(usuarioId));
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo eliminar: $e')));
    }
  }
}
