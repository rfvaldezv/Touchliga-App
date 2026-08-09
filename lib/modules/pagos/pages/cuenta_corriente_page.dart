import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/design_system/tokens/app_spacing.dart';
import '../models/cuenta_corriente_model.dart';
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
                ...cuenta.temporadas.map((t) => _TemporadaCard(temporada: t)),
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

class _TemporadaCard extends StatelessWidget {
  const _TemporadaCard({required this.temporada});

  final CuentaCorrienteTemporadaModel temporada;

  @override
  Widget build(BuildContext context) {
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
                  ),
                )
                .toList(),
      ),
    );
  }
}
