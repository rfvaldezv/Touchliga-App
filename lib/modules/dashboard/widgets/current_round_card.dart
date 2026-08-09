import 'package:flutter/material.dart';

import '../models/current_round_model.dart';
import '../../../shared/design_system/widgets/cards/app_card.dart';

class CurrentRoundCard extends StatelessWidget {
  const CurrentRoundCard({super.key, required this.model, this.onPressed});

  final CurrentRoundModel model;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Jornada Actual',
      icon: Icons.sports_soccer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Jornada ${model.round}',
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          _Item(
            icon: Icons.calendar_today,
            text: '${model.totalMatches} partidos programados',
          ),

          _Item(
            icon: Icons.check_circle,
            text: '${model.completedMatches} resultados capturados',
          ),

          _Item(
            icon: Icons.hourglass_bottom,
            text: '${model.pendingMatches} pendientes',
          ),

          const SizedBox(height: 20),

          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              value: model.progress,
              minHeight: 10,
            ),
          ),

          const SizedBox(height: 8),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${(model.progress * 100).toStringAsFixed(0)} %',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),

          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onPressed,
              icon: const Icon(Icons.arrow_forward),
              label: const Text('Ver Jornada'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Item extends StatelessWidget {
  const _Item({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
