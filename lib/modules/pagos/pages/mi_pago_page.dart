import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/router/app_route_names.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../temporadas/providers/temporada_provider.dart';
import '../models/resumen_pago_model.dart';
import '../providers/pagos_provider.dart';

/// Pantalla del participante para ver el estatus de su cuota --
/// solo informativa. El pago en sí se sigue haciendo por fuera de
/// la app (transferencia, efectivo, etc.), como se hacía antes;
/// aquí solo se refleja lo que el admin ya registró en Pagos.
class MiPagoPage extends ConsumerStatefulWidget {
  const MiPagoPage({super.key});

  @override
  ConsumerState<MiPagoPage> createState() => _MiPagoPageState();
}

class _MiPagoPageState extends ConsumerState<MiPagoPage> {
  int? _temporadaId;

  @override
  Widget build(BuildContext context) {
    final temporadasAsync = ref.watch(temporadasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi pago'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go(AppRouteNames.home),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: () {
              if (_temporadaId != null) {
                ref.invalidate(miPagoProvider(_temporadaId!));
              }
            },
          ),
        ],
      ),
      body: temporadasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No fue posible cargar temporadas.\n$e')),
        data: (temporadas) {
          if (temporadas.isEmpty) {
            return const Center(child: Text('Todavía no hay temporadas.'));
          }

          _temporadaId ??= temporadas.first.id;

          return Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                DropdownButtonFormField<int>(
                  initialValue: _temporadaId,
                  decoration: const InputDecoration(labelText: 'Temporada'),
                  items: temporadas
                      .map((t) => DropdownMenuItem(value: t.id, child: Text(t.nombre)))
                      .toList(),
                  onChanged: (value) => setState(() => _temporadaId = value),
                ),
                const SizedBox(height: AppSpacing.lg),
                Consumer(
                  builder: (context, ref, _) {
                    final miPagoAsync = ref.watch(miPagoProvider(_temporadaId!));

                    return miPagoAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, _) => Text('No fue posible cargar tu estatus de pago.\n$e'),
                      data: (resumen) {
                        if (resumen.cuota <= 0) {
                          return const Text('Esta temporada no tiene cuota configurada.');
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _TarjetaResumen(resumen: resumen),
                            if (resumen.pagos.isNotEmpty) ...[
                              const SizedBox(height: AppSpacing.md),
                              const Text('Historial', style: TextStyle(fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              ...resumen.pagos.map(
                                (p) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(Icons.receipt_long, size: 18),
                                  title: Text('\$${p.monto.toStringAsFixed(2)} · ${p.metodoPago}'),
                                  subtitle: Text(
                                    '${p.fechaPago.day}/${p.fechaPago.month}/${p.fechaPago.year}',
                                  ),
                                ),
                              ),
                            ],
                            if (!resumen.pagoCompleto) ...[
                              const SizedBox(height: AppSpacing.lg),
                              Card(
                                color: Colors.blue.shade50,
                                child: Padding(
                                  padding: const EdgeInsets.all(AppSpacing.md),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Icon(Icons.info_outline, color: Colors.blue.shade700),
                                      const SizedBox(width: AppSpacing.sm),
                                      Expanded(
                                        child: Text(
                                          'Para cubrir tu saldo pendiente, contacta al '
                                          'administrador de tu liga -- él registrará tu pago '
                                          'aquí en cuanto lo reciba.',
                                          style: TextStyle(color: Colors.blue.shade900),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ],
                        );
                      },
                    );
                  },
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _TarjetaResumen extends StatelessWidget {
  const _TarjetaResumen({required this.resumen});

  final ResumenPagoModel resumen;

  @override
  Widget build(BuildContext context) {
    final completo = resumen.pagoCompleto;

    return Card(
      color: completo ? Colors.green.shade50 : null,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  completo ? Icons.check_circle : Icons.pending_outlined,
                  color: completo ? Colors.green : Colors.orange,
                ),
                const SizedBox(width: 8),
                Text(
                  completo ? 'Cuota cubierta' : 'Cuota pendiente',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Cuota: \$${resumen.cuota.toStringAsFixed(2)}'),
            Text('Pagado: \$${resumen.totalPagado.toStringAsFixed(2)}'),
            if (!completo)
              Text(
                'Saldo pendiente: \$${resumen.saldoPendiente.toStringAsFixed(2)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
          ],
        ),
      ),
    );
  }
}
