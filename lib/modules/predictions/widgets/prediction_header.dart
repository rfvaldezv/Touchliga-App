import 'package:flutter/material.dart';

import '../models/prediction_day_model.dart';

class PredictionHeader extends StatelessWidget {
  const PredictionHeader({super.key, required this.predictionDay});

  final PredictionDayModel predictionDay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              predictionDay.leagueName,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              predictionDay.tournamentName,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Jornada ${predictionDay.round}',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            LinearProgressIndicator(
              value: predictionDay.progress,
              minHeight: 10,
              borderRadius: BorderRadius.circular(8),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${predictionDay.completedMatches} de '
                    '${predictionDay.totalMatches} partidos capturados',
                  ),
                ),
                Text(
                  '${predictionDay.progressPercentage}%',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Pendientes: ${predictionDay.pendingMatches}',
              style: TextStyle(
                color: predictionDay.pendingMatches == 0
                    ? Colors.green
                    : Colors.orange,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
