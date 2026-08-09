import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../../shared/widgets/compartir_dialog.dart';
import '../../communication/providers/communication_provider.dart';
import '../../temporadas/providers/temporada_provider.dart';
import '../models/resumen_financiero_model.dart';
import '../providers/pagos_provider.dart';

/// El "escritorio" de Finanzas — punto de entrada único para todo lo
/// relacionado a pagos: resumen, desglose por método (para
/// distinguir Stripe de lo manual), últimas transacciones, y accesos
/// directos a la lista completa / cuenta corriente / cobranza.
class FinanzasDashboardPage extends ConsumerStatefulWidget {
  const FinanzasDashboardPage({super.key});

  @override
  ConsumerState<FinanzasDashboardPage> createState() => _FinanzasDashboardPageState();
}

class _FinanzasDashboardPageState extends ConsumerState<FinanzasDashboardPage> {
  int? _temporadaId;

  @override
  Widget build(BuildContext context) {
    final temporadasAsync = ref.watch(temporadasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finanzas'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: temporadasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No fue posible cargar temporadas.\n$e')),
        data: (temporadas) {
          if (temporadas.isEmpty) {
            return const Center(child: Text('Todavía no hay temporadas.'));
          }

          final masReciente = ([...temporadas]..sort((a, b) => b.id.compareTo(a.id))).first;
          _temporadaId ??= masReciente.id;

          final resumenAsync = ref.watch(resumenFinancieroProvider(_temporadaId!));

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(resumenFinancieroProvider(_temporadaId!)),
            child: resumenAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('No fue posible cargar el resumen.\n$e')),
              data: (resumen) => ListView(
                padding: const EdgeInsets.all(AppSpacing.md),
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: _temporadaId,
                    decoration: const InputDecoration(labelText: 'Temporada'),
                    items: temporadas
                        .map((t) => DropdownMenuItem(value: t.id, child: Text(t.nombre)))
                        .toList(),
                    onChanged: (value) => setState(() => _temporadaId = value),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  _TarjetasResumen(resumen: resumen),
                  const SizedBox(height: AppSpacing.md),
                  _AccionesRapidas(temporadaId: _temporadaId!),
                  const SizedBox(height: AppSpacing.md),
                  _DesgloseMetodos(resumen: resumen),
                  const SizedBox(height: AppSpacing.md),
                  _UltimasTransacciones(resumen: resumen),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TarjetasResumen extends StatelessWidget {
  const _TarjetasResumen({required this.resumen});

  final ResumenFinancieroModel resumen;

  @override
  Widget build(BuildContext context) {
    final pct = resumen.porcentajeCubierto;
    final colorSemaforo = pct >= 90
        ? Colors.green
        : pct >= 50
            ? Colors.orange
            : Colors.red;

    return Row(
      children: [
        Expanded(
          child: _TarjetaMini(
            etiqueta: 'Recaudado',
            valor: '\$${resumen.totalRecaudado.toStringAsFixed(0)}',
            color: Colors.green,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _TarjetaMini(
            etiqueta: 'Pendiente',
            valor: '\$${resumen.totalPendiente.toStringAsFixed(0)}',
            color: Colors.red,
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _TarjetaMini(
            etiqueta: '🚦 Cubierto',
            valor: '${pct.round()}%',
            color: colorSemaforo,
            subtitulo: '${resumen.participantesCubiertos}/${resumen.totalParticipantes}',
          ),
        ),
      ],
    );
  }
}

class _TarjetaMini extends StatelessWidget {
  const _TarjetaMini({
    required this.etiqueta,
    required this.valor,
    required this.color,
    this.subtitulo,
  });

  final String etiqueta;
  final String valor;
  final Color color;
  final String? subtitulo;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withValues(alpha: 0.1),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Column(
          children: [
            Text(etiqueta, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            const SizedBox(height: 4),
            Text(valor, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
            if (subtitulo != null)
              Text(subtitulo!, style: const TextStyle(fontSize: 10, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

class _AccionesRapidas extends StatelessWidget {
  const _AccionesRapidas({required this.temporadaId});

  final int temporadaId;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/administration/pagos'),
            icon: const Icon(Icons.list_alt, size: 18),
            label: const Text('Todos los pagos'),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push('/administration/premios'),
            icon: const Icon(Icons.emoji_events_outlined, size: 18),
            label: const Text('Premios'),
          ),
        ),
      ],
    );
  }
}

class _DesgloseMetodos extends StatelessWidget {
  const _DesgloseMetodos({required this.resumen});

  final ResumenFinancieroModel resumen;

  IconData _icono(String metodo) {
    switch (metodo) {
      case 'Stripe':
        return Icons.credit_card;
      case 'Migracion':
        return Icons.history;
      case 'Efectivo':
        return Icons.payments_outlined;
      case 'Transferencia':
        return Icons.account_balance_outlined;
      default:
        return Icons.receipt_long;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (resumen.desglosePorMetodo.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Por método de pago', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: AppSpacing.sm),
            ...resumen.desglosePorMetodo.map(
              (d) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(_icono(d.metodoPago), size: 18, color: Colors.grey),
                    const SizedBox(width: 8),
                    Expanded(child: Text('${d.metodoPago} (${d.cantidad})')),
                    Text(
                      '\$${d.monto.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UltimasTransacciones extends StatelessWidget {
  const _UltimasTransacciones({required this.resumen});

  final ResumenFinancieroModel resumen;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Últimas transacciones', style: TextStyle(fontWeight: FontWeight.bold)),
                Consumer(
                  builder: (context, ref, _) => TextButton.icon(
                    onPressed: resumen.totalPendiente <= 0
                        ? null
                        : () => mostrarDialogoCompartir(
                              context,
                              ref,
                              mensajeSugerido:
                                  'Hola 👋 Te recordamos que tienes pendiente el pago de tu cuota. '
                                  '¡Cualquier duda, avísanos!',
                            ),
                    icon: const Icon(Icons.campaign_outlined, size: 16),
                    label: const Text('Cobranza'),
                  ),
                ),
              ],
            ),
            if (resumen.ultimasTransacciones.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
                child: Text('Sin transacciones todavía.'),
              )
            else
              ...resumen.ultimasTransacciones.map(
                (t) => ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    t.metodoPago == 'Stripe' ? Icons.credit_card : Icons.receipt_long,
                    size: 20,
                    color: t.metodoPago == 'Stripe' ? Colors.blue : Colors.grey,
                  ),
                  title: Text(t.usuarioNombre),
                  subtitle: Text(
                    '${t.metodoPago} · ${t.fechaPago.day}/${t.fechaPago.month}/${t.fechaPago.year}',
                  ),
                  trailing: Text('\$${t.monto.toStringAsFixed(2)}'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
