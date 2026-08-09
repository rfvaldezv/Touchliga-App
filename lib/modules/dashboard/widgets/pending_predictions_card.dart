import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../models/pending_predictions_model.dart';
import '../../../app/router/app_route_names.dart';
import '../../../shared/design_system/widgets/cards/app_card.dart';

class PendingPredictionsCard extends StatelessWidget {
  const PendingPredictionsCard({super.key, required this.model});

  final PendingPredictionsModel model;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      title: 'Pronósticos Pendientes',
      icon: Icons.edit_note,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Tienes ${model.pendingMatches} partidos pendientes.',
            style: const TextStyle(fontSize: 16),
          ),

          const SizedBox(height: 16),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.go(AppRouteNames.predictions),
              icon: const Icon(Icons.sports_soccer),
              label: const Text('Capturar pronósticos'),
            ),
          ),
        ],
      ),
    );
  }
}
