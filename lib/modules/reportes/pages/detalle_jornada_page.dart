import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../administration/providers/administration_provider.dart';
import '../../login/providers/auth_provider.dart';
import '../../pagos/providers/pagos_provider.dart';
import '../models/detalle_jornada_model.dart';
import '../providers/reportes_provider.dart';

/// Detalle partido por partido de una jornada, por participante —
/// verde = marcador exacto (3), amarillo = acertó resultado (1),
/// rojo = no acertó (0). Diseño inspirado en la quiniela web actual.
class DetalleJornadaPage extends ConsumerStatefulWidget {
  const DetalleJornadaPage({super.key});

  @override
  ConsumerState<DetalleJornadaPage> createState() => _DetalleJornadaPageState();
}

class _DetalleJornadaPageState extends ConsumerState<DetalleJornadaPage> {
  int? _jornadaId;
  final _scrollPestanasController = ScrollController();
  bool _yaSeDesplazo = false;

  @override
  void dispose() {
    _scrollPestanasController.dispose();
    super.dispose();
  }

  void _desplazarAJornadaSeleccionada(List<dynamic> ordenadas) {
    if (_yaSeDesplazo) return;

    final indice = ordenadas.indexWhere((j) => j.id == _jornadaId);
    if (indice <= 0) return;

    _yaSeDesplazo = true;

    // Ancho aproximado de cada pestaña (número + separación) — no
    // necesita ser exacto, solo acercar lo suficiente para que la
    // jornada seleccionada quede visible sin tener que buscarla.
    const anchoAproximadoPorPestana = 58.0;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollPestanasController.hasClients) return;

      final destino = (indice * anchoAproximadoPorPestana)
          .clamp(0.0, _scrollPestanasController.position.maxScrollExtent);

      _scrollPestanasController.animateTo(
        destino,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final jornadasAsync = ref.watch(jornadasAdminProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jornadas de pronósticos'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: jornadasAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('No fue posible cargar jornadas.\n$e')),
        data: (jornadas) {
          if (jornadas.isEmpty) {
            return const Center(child: Text('Todavía no hay jornadas.'));
          }

          final ordenadas = [...jornadas]..sort((a, b) => a.numero.compareTo(b.numero));

          if (_jornadaId == null) {
            final cerradas = ordenadas.where((j) => j.cerrada);
            _jornadaId = cerradas.isNotEmpty ? cerradas.last.id : ordenadas.last.id;
          }

          _desplazarAJornadaSeleccionada(ordenadas);

          final temporadaId = ordenadas.firstWhere((j) => j.id == _jornadaId).temporadaId;

          return Column(
            children: [
              // --- Pestañas de jornada (1, 2, 3...) ---
              SizedBox(
                height: 56,
                child: ListView.separated(
                  controller: _scrollPestanasController,
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                  itemCount: ordenadas.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final jornada = ordenadas[index];
                    final seleccionada = jornada.id == _jornadaId;

                    return ChoiceChip(
                      label: Text('${jornada.numero}'),
                      selected: seleccionada,
                      selectedColor: Colors.green.shade600,
                      labelStyle: TextStyle(
                        color: seleccionada ? Colors.white : null,
                        fontWeight: FontWeight.bold,
                      ),
                      onSelected: (_) => setState(() => _jornadaId = jornada.id),
                    );
                  },
                ),
              ),

              // --- Leyenda de colores ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 4,
                  children: const [
                    _LeyendaColor(color: Color(0xFF31F077), texto: '1 Pt (Acertó)'),
                    _LeyendaColor(color: Color(0xFFFF1307), texto: '0 Pts (No acertó)'),
                    _LeyendaColor(color: Color(0xFFFF6D00), texto: '+1 Bono desempate ⭐'),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),

              Expanded(
                child: _TablaDetalle(jornadaId: _jornadaId!, temporadaId: temporadaId),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _LeyendaColor extends StatelessWidget {
  const _LeyendaColor({required this.color, required this.texto});

  final Color color;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
        ),
        const SizedBox(width: 4),
        Text(texto, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}

class _TablaDetalle extends ConsumerWidget {
  const _TablaDetalle({required this.jornadaId, required this.temporadaId});

  final int jornadaId;
  final int temporadaId;

  Color _colorDePuntos(int? puntos) {
    if (puntos == null) return Colors.grey.shade300;
    if (puntos >= 1) return const Color(0xFF31F077);
    return const Color(0xFFFF1307);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detalleAsync = ref.watch(detalleJornadaProvider(jornadaId));
    final miUsuarioId = ref.watch(authProvider).user?.userId;
    final esAdmin = ref.watch(authProvider).user?.roles.contains('Administrador') ?? false;

    return detalleAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('No fue posible cargar el detalle.\n$e')),
      data: (filas) {
        if (filas.isEmpty) {
          return const Center(child: Text('Nadie ha capturado pronósticos en esta jornada todavía.'));
        }

        final partidosHeader = filas.first.partidos;
        final pagosPorUsuario = <int, double?>{};

        if (esAdmin) {
          // El estatus de pagos es solo para el administrador — el
          // endpoint mismo lo rechaza para cualquier otro rol, así
          // que ni se pide si no aplica.
          final pagosAsync = ref.watch(estatusPagosProvider(temporadaId));

          if (pagosAsync.hasValue) {
            for (final p in pagosAsync.value!) {
              pagosPorUsuario[p.usuarioId] = p.totalPagado;
            }
          }
        }

        Widget conDivisor(Widget child) {
          return Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: Colors.grey.shade300)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: child,
          );
        }

        final controladorScrollTabla = ScrollController();
        return Scrollbar(
          controller: controladorScrollTabla,
          thumbVisibility: true,
          trackVisibility: true,
          child: SingleChildScrollView(
          controller: controladorScrollTabla,
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columnSpacing: 0,
            horizontalMargin: 12,
            columns: [
              DataColumn(label: conDivisor(const Text('Participante'))),
              if (esAdmin) DataColumn(label: conDivisor(const Text('Pago'))),
              for (final partido in partidosHeader)
                DataColumn(
                  label: conDivisor(
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (partido.esDesempate)
                          const Text('⭐', style: TextStyle(fontSize: 10)),
                        Text(
                          partido.puntosTotalesReal != null
                              ? 'Total: ${partido.puntosTotalesReal} (dif: ${partido.diferenciaPuntosReal})'
                              : (partido.equipoGanadorReal != null ? 'Jugado' : 'Por jugar'),
                          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _EscudoMini(url: partido.escudoLocalUrl),
                            const SizedBox(width: 2),
                            _EscudoMini(url: partido.escudoVisitanteUrl),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              const DataColumn(label: Text('Total')),
            ],
            rows: filas.map((DetalleJornadaModel fila) {
              final esMio = fila.usuarioId == miUsuarioId;
              final monto = pagosPorUsuario[fila.usuarioId];

              return DataRow(
                color: esMio
                    ? WidgetStateProperty.all(Colors.amber.withValues(alpha: 0.25))
                    : null,
                cells: [
                  DataCell(
                    conDivisor(
                      ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 160),
                        child: Text(
                          esMio ? '${fila.nombre} (Tú)' : fila.nombre,
                          overflow: TextOverflow.ellipsis,
                          style: esMio ? const TextStyle(fontWeight: FontWeight.bold) : null,
                        ),
                      ),
                    ),
                  ),
                  if (esAdmin)
                    DataCell(
                      conDivisor(
                        Text(
                          monto != null ? '\$${monto.toStringAsFixed(2)}' : '-',
                          style: TextStyle(
                            color: (monto ?? 0) > 0 ? Colors.green.shade700 : Colors.red,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  for (final partido in fila.partidos)
                    DataCell(
                      conDivisor(
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (partido.equipoGanadorPronostico == null)
                              const Text('-', style: TextStyle(fontSize: 12))
                            else
                              Icon(
                                partido.puntos == 1 ? Icons.check_circle : Icons.cancel,
                                size: 14,
                                color: partido.puntos == 1 ? const Color(0xFF31F077) : const Color(0xFFFF1307),
                              ),
                            const SizedBox(width: 4),
                            Container(
                              width: 20,
                              height: 20,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _colorDePuntos(partido.puntos),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                partido.puntos?.toString() ?? '-',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            if (partido.esDesempate && partido.puntosTotalesPredichos != null) ...[
                              const SizedBox(width: 4),
                              Text(
                                '(${partido.puntosTotalesPredichos}/${partido.diferenciaPuntosPredicha ?? '-'})',
                                style: const TextStyle(fontSize: 10, color: Colors.grey),
                              ),
                              if (partido.puntosBono > 0)
                                const Padding(
                                  padding: EdgeInsets.only(left: 2),
                                  child: Text('⭐', style: TextStyle(fontSize: 12)),
                                ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  DataCell(
                    Text(
                      fila.total.toString(),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
          ),
        );
      },
    );
  }
}

class _EscudoMini extends StatelessWidget {
  const _EscudoMini({required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 10,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: (url != null && url!.isNotEmpty) ? NetworkImage(url!) : null,
      child: (url == null || url!.isEmpty) ? const Icon(Icons.shield_outlined, size: 10) : null,
    );
  }
}
