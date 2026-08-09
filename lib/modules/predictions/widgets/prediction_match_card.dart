import 'package:flutter/material.dart';

import '../../../shared/design_system/tokens/app_colors.dart';
import '../models/match_prediction_model.dart';

class PredictionMatchCard extends StatefulWidget {
  const PredictionMatchCard({
    super.key,
    required this.match,
    required this.onChanged,
  });

  final MatchPredictionModel match;

  final ValueChanged<MatchPredictionModel> onChanged;

  @override
  State<PredictionMatchCard> createState() => _PredictionMatchCardState();
}

class _PredictionMatchCardState extends State<PredictionMatchCard> {
  late final TextEditingController _totalController;
  late final TextEditingController _diferenciaController;

  @override
  void initState() {
    super.initState();
    _totalController = TextEditingController(
      text: widget.match.puntosTotalesPredichos?.toString() ?? '',
    );
    _diferenciaController = TextEditingController(
      text: widget.match.diferenciaPuntosPredicha?.toString() ?? '',
    );
  }

  @override
  void dispose() {
    _totalController.dispose();
    _diferenciaController.dispose();
    super.dispose();
  }

  void _elegirGanador(int equipoId) {
    if (!widget.match.editable) return;
    widget.onChanged(widget.match.copyWith(winnerTeamId: equipoId));
  }

  void _notificarTotal() {
    widget.onChanged(
      widget.match.copyWith(puntosTotalesPredichos: int.tryParse(_totalController.text)),
    );
  }

  void _notificarDiferencia() {
    widget.onChanged(
      widget.match.copyWith(diferenciaPuntosPredicha: int.tryParse(_diferenciaController.text)),
    );
  }

  String _formatDia(DateTime fecha) {
    const dias = ['', 'lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    return '${dias[fecha.weekday]} ${fecha.day}/${fecha.month}';
  }

  String _formatHora(DateTime fecha) {
    final hora = fecha.hour.toString().padLeft(2, '0');
    final minuto = fecha.minute.toString().padLeft(2, '0');
    return '$hora:$minuto';
  }

  @override
  Widget build(BuildContext context) {
    final editable = widget.match.editable;
    final ganadorElegido = widget.match.winnerTeamId;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: widget.match.completed ? AppColors.secondary : Colors.transparent,
          width: 1.5,
        ),
      ),

      child: Padding(
        padding: const EdgeInsets.all(14),

        child: Column(
          children: [
            if (widget.match.esDesempate)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    'PARTIDO DE DESEMPATE ⭐',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.secondaryDark),
                  ),
                ),
              ),

            Row(
              children: [
                Expanded(
                  child: _EquipoSeleccionable(
                    nombre: widget.match.localTeam,
                    apodo: widget.match.localTeamApodo,
                    escudoUrl: widget.match.localTeamCrest,
                    seleccionado: ganadorElegido == widget.match.localTeamId,
                    habilitado: editable,
                    onTap: () => _elegirGanador(widget.match.localTeamId),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    'vs',
                    style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.textSecondary),
                  ),
                ),
                Expanded(
                  child: _EquipoSeleccionable(
                    nombre: widget.match.visitorTeam,
                    apodo: widget.match.visitorTeamApodo,
                    escudoUrl: widget.match.visitorTeamCrest,
                    seleccionado: ganadorElegido == widget.match.visitorTeamId,
                    habilitado: editable,
                    onTap: () => _elegirGanador(widget.match.visitorTeamId),
                  ),
                ),
              ],
            ),

            if (widget.match.esDesempate) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _totalController,
                enabled: editable,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: 'Suma de puntos total del partido',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _notificarTotal(),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _diferenciaController,
                enabled: editable,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                decoration: const InputDecoration(
                  labelText: 'Diferencia de puntos del partido',
                  helperText: 'Quien quede más cerca de suma + diferencia real gana 1 punto extra',
                  isDense: true,
                  border: OutlineInputBorder(),
                ),
                onChanged: (_) => _notificarDiferencia(),
              ),
            ],

            const SizedBox(height: 12),
            const Divider(height: 1),
            const SizedBox(height: 10),

            Wrap(
              alignment: WrapAlignment.center,
              spacing: 14,
              runSpacing: 2,
              children: [
                _Detallito(
                  icono: Icons.event,
                  color: Colors.blueAccent,
                  texto: _formatDia(widget.match.matchDate),
                ),
                _Detallito(
                  icono: widget.match.locked ? Icons.lock_outline : Icons.access_time_filled,
                  color: Colors.redAccent,
                  texto: _formatHora(widget.match.matchDate),
                ),
                if (widget.match.cancha != null)
                  _Detallito(
                    icono: Icons.location_on,
                    color: Colors.pinkAccent,
                    texto: widget.match.cancha!,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Un equipo que se elige tocándolo -- reemplaza los 2 campos de
/// marcador que usaba FutLiga, ya que en Touchliga solo se predice
/// quién gana, no el marcador exacto.
class _EquipoSeleccionable extends StatelessWidget {
  const _EquipoSeleccionable({
    required this.nombre,
    required this.escudoUrl,
    required this.seleccionado,
    required this.habilitado,
    required this.onTap,
    this.apodo,
  });

  final String nombre;
  final String? apodo;
  final String? escudoUrl;
  final bool seleccionado;
  final bool habilitado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final escudo = CircleAvatar(
      radius: 22,
      backgroundColor: Colors.grey.shade200,
      backgroundImage: (escudoUrl != null && escudoUrl!.isNotEmpty)
          ? NetworkImage(escudoUrl!)
          : null,
      child: (escudoUrl == null || escudoUrl!.isEmpty)
          ? Text(
              nombre.isNotEmpty ? nombre[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 15),
            )
          : null,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: habilitado ? onTap : null,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: seleccionado ? AppColors.secondary.withValues(alpha: 0.18) : Colors.transparent,
          border: Border.all(
            color: seleccionado ? AppColors.secondary : Colors.grey.shade300,
            width: seleccionado ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            escudo,
            const SizedBox(height: 6),
            Text(
              nombre,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              style: TextStyle(
                fontSize: 13,
                fontWeight: seleccionado ? FontWeight.bold : FontWeight.w600,
              ),
            ),
            if (apodo != null && apodo!.isNotEmpty)
              Text(
                apodo!,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            if (seleccionado)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Icon(Icons.check_circle, size: 16, color: AppColors.secondaryDark),
              ),
          ],
        ),
      ),
    );
  }
}

/// Un dato pequeño con su ícono (fecha, hora o cancha) — para que la
/// tarjeta se sienta menos como un formulario y más como algo
/// divertido, en vez de solo texto plano.
class _Detallito extends StatelessWidget {
  const _Detallito({required this.icono, required this.texto, this.color});

  final IconData icono;
  final String texto;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icono, size: 14, color: color ?? AppColors.secondaryDark),
        const SizedBox(width: 3),
        Text(texto, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
      ],
    );
  }
}
