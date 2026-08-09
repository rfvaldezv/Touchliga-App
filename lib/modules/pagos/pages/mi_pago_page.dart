import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/router/app_route_names.dart';
import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../temporadas/providers/temporada_provider.dart';
import '../models/resumen_pago_model.dart';
import '../providers/pagos_provider.dart';

/// Pantalla del participante para ver el estatus de su cuota y
/// pagarla con tarjeta (Stripe Checkout) — completa o a la mitad —
/// si todavía no lo ha hecho.
class MiPagoPage extends ConsumerStatefulWidget {
  const MiPagoPage({super.key});

  @override
  ConsumerState<MiPagoPage> createState() => _MiPagoPageState();
}

class _MiPagoPageState extends ConsumerState<MiPagoPage> with WidgetsBindingObserver {
  int? _temporadaId;
  String? _tipoPagoEnProceso;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Cuando el navegador se va a otra pestaña (a pagar en Stripe) y
    // luego vuelves a esta, el sistema manda "resumed" — ahí
    // aprovechamos para refrescar solos, sin que tengas que salir y
    // volver a entrar a mano.
    if (state == AppLifecycleState.resumed && _temporadaId != null) {
      ref.invalidate(miPagoProvider(_temporadaId!));
    }
  }

  Future<void> _pagarConTarjeta(String tipoPago) async {
    if (_temporadaId == null) return;

    setState(() => _tipoPagoEnProceso = tipoPago);

    try {
      final url = await ref
          .read(pagosServiceProvider)
          .iniciarCheckout(_temporadaId!, tipoPago: tipoPago);
      final abrio = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

      if (!abrio && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No se pudo abrir la página de pago.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo iniciar el pago: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _tipoPagoEnProceso = null);
    }
  }

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
                              const Text(
                                '¿Cómo quieres pagar?',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              FilledButton.icon(
                                onPressed: _tipoPagoEnProceso != null
                                    ? null
                                    : () => _pagarConTarjeta('Completo'),
                                icon: _tipoPagoEnProceso == 'Completo'
                                    ? const SizedBox(
                                        width: 16,
                                        height: 16,
                                        child: CircularProgressIndicator(strokeWidth: 2),
                                      )
                                    : const Icon(Icons.credit_card),
                                label: Text(
                                  'Pagar completo (\$${resumen.saldoPendiente.toStringAsFixed(2)})',
                                ),
                              ),
                              const SizedBox(height: AppSpacing.sm),
                              // Solo tiene sentido ofrecer "la mitad" si
                              // el saldo pendiente todavía alcanza para
                              // una mitad completa (si ya solo falta
                              // menos de eso, se le pide pagar el resto).
                              if (resumen.saldoPendiente >= resumen.cuota / 2)
                                OutlinedButton.icon(
                                  onPressed: _tipoPagoEnProceso != null
                                      ? null
                                      : () => _pagarConTarjeta('Mitad'),
                                  icon: _tipoPagoEnProceso == 'Mitad'
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        )
                                      : const Icon(Icons.credit_card_outlined),
                                  label: Text(
                                    'Pagar la mitad (\$${(resumen.cuota / 2).toStringAsFixed(2)})',
                                  ),
                                ),
                              const SizedBox(height: 4),
                              const Text(
                                'Se abre la página segura de Stripe en tu navegador.',
                                style: TextStyle(fontSize: 11, color: Colors.grey),
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
