import 'package:flutter/material.dart';

import '../models/match_prediction_model.dart';
import '../models/prediction_day_model.dart';
import 'prediction_match_card.dart';

class PredictionList extends StatelessWidget {
  const PredictionList({
    super.key,
    required this.predictionDay,
    required this.onMatchChanged,
  });

  final PredictionDayModel predictionDay;

  final ValueChanged<MatchPredictionModel> onMatchChanged;

  @override
  Widget build(BuildContext context) {
    if (predictionDay.matches.isEmpty) {
      return const Center(
        child: Text('No existen partidos para esta jornada.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: predictionDay.matches.length,
      itemBuilder: (context, index) {
        final match = predictionDay.matches[index];

        return PredictionMatchCard(
          key: ValueKey(match.matchId),
          match: match,
          onChanged: onMatchChanged,
        );
      },
    );
  }
}
