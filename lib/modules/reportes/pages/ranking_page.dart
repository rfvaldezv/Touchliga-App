import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../login/providers/auth_provider.dart';
import '../../temporadas/providers/temporada_provider.dart';
import '../models/ranking_model.dart';
import '../providers/reportes_provider.dart';

/// Ranking de la temporada — por default "Acumulado Total" (todas
/// las jornadas), o se puede filtrar a una sola jornada tocándola,
/// y regresar al acumulado tocando el botón verde de nuevo.
class RankingPage extends ConsumerStatefulWidget {
  const RankingPage({super.key});

  @override
  ConsumerState<RankingPage> createState() => _RankingPageState();
}

class _RankingPageState extends ConsumerState<RankingPage> {
  int? _temporadaId;
  int? _jornadaFiltro;

  @override
  Widget build(BuildContext context) {
    final temporadasAsync = ref.watch(temporadasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Ranking'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: temporadasAsync.when(
              loading: () => const LinearProgressIndicator(),
              error: (e, _) => Text('No fue posible cargar temporadas.\n$e'),
              data: (temporadas) {
                if (temporadas.isEmpty) {
                  return const Text('Todavía no hay temporadas.');
                }

                _temporadaId ??= temporadas.first.id;

                return DropdownButtonFormField<int>(
                  initialValue: _temporadaId,
                  decoration: const InputDecoration(labelText: 'Temporada'),
                  items: temporadas
                      .map((t) => DropdownMenuItem(value: t.id, child: Text(t.nombre)))
                      .toList(),
                  onChanged: (value) => setState(() {
                    _temporadaId = value;
                    _jornadaFiltro = null;
                  }),
                );
              },
            ),
          ),
          Expanded(
            child: _temporadaId == null
                ? const Center(child: Text('Elige una temporada.'))
                : _ContenidoRanking(
                    temporadaId: _temporadaId!,
                    jornadaFiltro: _jornadaFiltro,
                    onCambiarFiltro: (id) => setState(() => _jornadaFiltro = id),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ContenidoRanking extends ConsumerWidget {
  const _ContenidoRanking({
    required this.temporadaId,
    required this.jornadaFiltro,
    required this.onCambiarFiltro,
  });

  final int temporadaId;
  final int? jornadaFiltro;
  final ValueChanged<int?> onCambiarFiltro;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rankingAsync = ref.watch(rankingProvider(temporadaId));

    return rankingAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('No fue posible cargar el ranking.\n$e')),
      data: (filas) {
        if (filas.isEmpty) {
          return const Center(child: Text('Nadie ha capturado pronósticos en esta temporada todavía.'));
        }

        final jornadasDisponibles = filas.first.jornadas;

        return Column(
          children: [
            // --- "Acumulado Total" + pestañas de jornada ---
            SizedBox(
              height: 56,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                children: [
                  ChoiceChip(
                    avatar: const Icon(Icons.emoji_events, size: 16, color: Colors.white),
                    label: const Text('Acumulado Total'),
                    selected: jornadaFiltro == null,
                    selectedColor: Colors.green.shade600,
                    labelStyle: TextStyle(
                      color: jornadaFiltro == null ? Colors.white : null,
                      fontWeight: FontWeight.bold,
                    ),
                    onSelected: (_) => onCambiarFiltro(null),
                  ),
                  const SizedBox(width: 8),
                  for (final jornada in jornadasDisponibles) ...[
                    ChoiceChip(
                      label: Text('${jornada.numero}'),
                      selected: jornadaFiltro == jornada.jornadaId,
                      onSelected: (_) => onCambiarFiltro(jornada.jornadaId),
                    ),
                    const SizedBox(width: 8),
                  ],
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  jornadaFiltro == null
                      ? 'RANKING ACUMULADO TOTAL'
                      : 'RANKING — JORNADA ${jornadasDisponibles.firstWhere((j) => j.jornadaId == jornadaFiltro).numero}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Expanded(
              child: jornadaFiltro == null
                  ? _TablaAcumulada(filas: filas)
                  : _TablaJornadaUnica(filas: filas, jornadaId: jornadaFiltro!),
            ),
          ],
        );
      },
    );
  }
}

// Paleta rotativa solo para diferenciar visualmente cada columna de
// jornada en el encabezado — no representa ningún dato.
const _paletaJornadas = [
  Colors.orange,
  Colors.brown,
  Colors.lightGreen,
  Colors.cyan,
  Colors.pink,
  Colors.black87,
  Colors.deepPurple,
  Colors.amber,
  Colors.red,
];

Widget _conDivisor(Widget child) {
  return Container(
    decoration: BoxDecoration(
      border: Border(right: BorderSide(color: Colors.grey.shade300)),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    child: child,
  );
}

Widget _celdaNombre(String nombre, int posicion, bool esMio) {
  return _conDivisor(
    ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 160),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (posicion <= 3)
            Text(
              posicion == 1 ? '🥇' : (posicion == 2 ? '🥈' : '🥉'),
              style: const TextStyle(fontSize: 14),
            )
          else
            Text('$posicion.', style: const TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              nombre,
              overflow: TextOverflow.ellipsis,
              style: esMio ? const TextStyle(fontWeight: FontWeight.bold) : null,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Vista "Acumulado Total" — todas las jornadas como columnas.
class _TablaAcumulada extends ConsumerWidget {
  const _TablaAcumulada({required this.filas});

  final List<RankingModel> filas;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jornadasHeader = filas.first.jornadas;
    final miUsuarioId = ref.watch(authProvider).user?.userId;
    final controladorScroll = ScrollController();

    return Scrollbar(
      controller: controladorScroll,
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
      controller: controladorScroll,
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 0,
        horizontalMargin: 12,
        columns: [
          DataColumn(label: _conDivisor(const Text('Participante'))),
          for (var i = 0; i < jornadasHeader.length; i++)
            DataColumn(
              label: _conDivisor(
                CircleAvatar(
                  radius: 12,
                  backgroundColor: _paletaJornadas[i % _paletaJornadas.length],
                  child: Text(
                    '${jornadasHeader[i].numero}',
                    style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          DataColumn(label: _conDivisor(const Text('Total'))),
          const DataColumn(label: Text('%')),
        ],
        rows: filas.asMap().entries.map((entry) {
          final posicion = entry.key + 1;
          final RankingModel fila = entry.value;
          final esMio = fila.usuarioId == miUsuarioId;

          return DataRow(
            color: esMio ? WidgetStateProperty.all(Colors.amber.withValues(alpha: 0.25)) : null,
            cells: [
              DataCell(_celdaNombre(fila.nombre, posicion, esMio)),
              for (final jornada in fila.jornadas)
                DataCell(
                  _conDivisor(
                    Text(
                      jornada.puntos.toString(),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              DataCell(
                _conDivisor(
                  Text(fila.totalPuntos.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              DataCell(Text('${fila.porcentajeProductividad.toStringAsFixed(0)}%')),
            ],
          );
        }).toList(),
      ),
      ),
    );
  }
}

/// Vista filtrada a UNA jornada — reordena por los puntos de esa
/// jornada, y el % se recalcula solo con esa jornada (no el
/// acumulado de toda la temporada).
class _TablaJornadaUnica extends ConsumerWidget {
  const _TablaJornadaUnica({required this.filas, required this.jornadaId});

  final List<RankingModel> filas;
  final int jornadaId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final miUsuarioId = ref.watch(authProvider).user?.userId;

    final filasDeEstaJornada = filas
        .map((f) => (
              fila: f,
              jornada: f.jornadas.firstWhere((j) => j.jornadaId == jornadaId),
            ))
        .toList()
      ..sort((a, b) => b.jornada.puntos.compareTo(a.jornada.puntos));

    final controladorScroll = ScrollController();

    return Scrollbar(
      controller: controladorScroll,
      thumbVisibility: true,
      trackVisibility: true,
      child: SingleChildScrollView(
      controller: controladorScroll,
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 0,
        horizontalMargin: 12,
        columns: [
          DataColumn(label: _conDivisor(const Text('Participante'))),
          DataColumn(label: _conDivisor(const Text('Puntos'))),
          const DataColumn(label: Text('%')),
        ],
        rows: filasDeEstaJornada.asMap().entries.map((entry) {
          final posicion = entry.key + 1;
          final fila = entry.value.fila;
          final jornada = entry.value.jornada;
          final esMio = fila.usuarioId == miUsuarioId;

          final porcentaje = jornada.calificados > 0
              ? (jornada.puntos / (jornada.calificados * 3) * 100).toStringAsFixed(0)
              : '0';

          return DataRow(
            color: esMio ? WidgetStateProperty.all(Colors.amber.withValues(alpha: 0.25)) : null,
            cells: [
              DataCell(_celdaNombre(fila.nombre, posicion, esMio)),
              DataCell(
                _conDivisor(
                  Text(jornada.puntos.toString(), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              DataCell(Text('$porcentaje%')),
            ],
          );
        }).toList(),
      ),
      ),
    );
  }
}
