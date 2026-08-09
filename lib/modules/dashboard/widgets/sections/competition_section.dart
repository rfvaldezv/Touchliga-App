import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/router/app_route_names.dart';
import '../../models/current_round_model.dart';
import '../../models/pending_predictions_model.dart';
import '../current_round_card.dart';
import '../pending_predictions_card.dart';

class CompetitionSection extends StatelessWidget {
  const CompetitionSection({
    super.key,
    required this.round,
    required this.pending,
  });

  final CurrentRoundModel round;
  final PendingPredictionsModel pending;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CurrentRoundCard(
          model: round,
          onPressed: () => context.go(AppRouteNames.predictions),
        ),

        const SizedBox(height: 16),

        PendingPredictionsCard(model: pending),
      ],
    );
  }
}
