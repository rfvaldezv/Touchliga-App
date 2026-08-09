import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../shared/design_system/tokens/app_spacing.dart';
import '../../temporadas/providers/temporada_provider.dart';
import '../models/configuracion_premio_model.dart';
import '../providers/premios_provider.dart';

/// Administración → configurar los montos/regalos de cada posición,
/// tanto "por jornada" (1°-3° lugar, se reparte cada jornada) como
/// "final de temporada" (1°-10° lugar, se reparte una sola vez).
class AdminConfiguracionPremiosPage extends ConsumerStatefulWidget {
  const AdminConfiguracionPremiosPage({super.key});

  @override
  ConsumerState<AdminConfiguracionPremiosPage> createState() =>
      _AdminConfiguracionPremiosPageState();
}

class _AdminConfiguracionPremiosPageState extends ConsumerState<AdminConfiguracionPremiosPage> {
  int? _temporadaId;
  String _ambito = 'Jornada';
  bool _guardando = false;

  int get _numeroDePosiciones => _ambito == 'Jornada' ? 3 : 10;

  @override
  Widget build(BuildContext context) {
    final temporadasAsync = ref.watch(temporadasProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurar premios'),
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

          _temporadaId ??= temporadas.first.id;

          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  children: [
                    DropdownButtonFormField<int>(
                      initialValue: _temporadaId,
                      decoration: const InputDecoration(labelText: 'Temporada'),
                      items: temporadas
                          .map((t) => DropdownMenuItem(value: t.id, child: Text(t.nombre)))
                          .toList(),
                      onChanged: (value) => setState(() => _temporadaId = value),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(value: 'Jornada', label: Text('Por jornada (1°-3°)')),
                        ButtonSegment(value: 'Final', label: Text('Final (1°-10°)')),
                      ],
                      selected: {_ambito},
                      onSelectionChanged: (nuevo) => setState(() => _ambito = nuevo.first),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _FormularioPosiciones(
                  key: ValueKey('$_temporadaId-$_ambito'),
                  temporadaId: _temporadaId!,
                  ambito: _ambito,
                  numeroDePosiciones: _numeroDePosiciones,
                  guardando: _guardando,
                  onGuardar: (premios) => _guardar(premios),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _guardar(List<ConfiguracionPremioModel> premios) async {
    setState(() => _guardando = true);

    try {
      await ref
          .read(premiosServiceProvider)
          .guardarConfiguracion(_temporadaId!, _ambito, premios);

      ref.invalidate(configuracionPremiosProvider((_temporadaId!, _ambito)));

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Configuración de premios guardada.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo guardar: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _guardando = false);
    }
  }
}

class _FormularioPosiciones extends ConsumerStatefulWidget {
  const _FormularioPosiciones({
    super.key,
    required this.temporadaId,
    required this.ambito,
    required this.numeroDePosiciones,
    required this.guardando,
    required this.onGuardar,
  });

  final int temporadaId;
  final String ambito;
  final int numeroDePosiciones;
  final bool guardando;
  final ValueChanged<List<ConfiguracionPremioModel>> onGuardar;

  @override
  ConsumerState<_FormularioPosiciones> createState() => _FormularioPosicionesState();
}

class _FormularioPosicionesState extends ConsumerState<_FormularioPosiciones> {
  late List<String> _tipos;
  late List<TextEditingController> _montos;
  late List<TextEditingController> _descripciones;
  bool _inicializado = false;

  @override
  void dispose() {
    for (final c in _montos) {
      c.dispose();
    }
    for (final c in _descripciones) {
      c.dispose();
    }
    super.dispose();
  }

  void _inicializar(List<ConfiguracionPremioModel> existentes) {
    if (_inicializado) return;

    _tipos = List.generate(widget.numeroDePosiciones, (i) {
      final pos = i + 1;
      final existente = existentes.where((e) => e.posicion == pos);
      return existente.isNotEmpty ? existente.first.tipoPremio : 'Efectivo';
    });

    _montos = List.generate(widget.numeroDePosiciones, (i) {
      final pos = i + 1;
      final existente = existentes.where((e) => e.posicion == pos);
      final monto = existente.isNotEmpty ? existente.first.monto : 0.0;
      return TextEditingController(text: monto > 0 ? monto.toStringAsFixed(2) : '');
    });

    _descripciones = List.generate(widget.numeroDePosiciones, (i) {
      final pos = i + 1;
      final existente = existentes.where((e) => e.posicion == pos);
      return TextEditingController(text: existente.isNotEmpty ? (existente.first.descripcion ?? '') : '');
    });

    _inicializado = true;
  }

  @override
  Widget build(BuildContext context) {
    final configAsync =
        ref.watch(configuracionPremiosProvider((widget.temporadaId, widget.ambito)));

    return configAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('No fue posible cargar la configuración.\n$e')),
      data: (existentes) {
        _inicializar(existentes);

        return Column(
          children: [
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                itemCount: widget.numeroDePosiciones,
                separatorBuilder: (_, __) => const Divider(),
                itemBuilder: (context, i) {
                  final posicion = i + 1;

                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${_ordinal(posicion)} lugar',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: _tipos[i],
                                decoration: const InputDecoration(labelText: 'Tipo'),
                                items: const [
                                  DropdownMenuItem(value: 'Efectivo', child: Text('Efectivo')),
                                  DropdownMenuItem(value: 'Especie', child: Text('Especie (regalo)')),
                                ],
                                onChanged: (v) => setState(() => _tipos[i] = v!),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: TextField(
                                controller: _montos[i],
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  labelText: _tipos[i] == 'Efectivo' ? 'Monto' : 'Valor aprox.',
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (_tipos[i] == 'Especie') ...[
                          const SizedBox(height: AppSpacing.xs),
                          TextField(
                            controller: _descripciones[i],
                            decoration: const InputDecoration(
                              labelText: 'Descripción del regalo',
                              hintText: 'Ej. Playera oficial, cena para 2...',
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: FilledButton.icon(
                onPressed: widget.guardando ? null : _guardar,
                icon: widget.guardando
                    ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.save),
                label: const Text('Guardar configuración'),
              ),
            ),
          ],
        );
      },
    );
  }

  void _guardar() {
    final premios = <ConfiguracionPremioModel>[];

    for (var i = 0; i < widget.numeroDePosiciones; i++) {
      final monto = double.tryParse(_montos[i].text) ?? 0;
      if (monto <= 0) continue; // posición sin premio configurado, se omite

      premios.add(ConfiguracionPremioModel(
        posicion: i + 1,
        tipoPremio: _tipos[i],
        monto: monto,
        descripcion: _tipos[i] == 'Especie' ? _descripciones[i].text.trim() : null,
      ));
    }

    widget.onGuardar(premios);
  }

  String _ordinal(int n) {
    switch (n) {
      case 1:
        return '1er';
      case 2:
        return '2do';
      case 3:
        return '3er';
      default:
        return '$n°';
    }
  }
}
