import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/match_prediction_model.dart';
import '../models/prediction_day_model.dart';
import '../repositories/prediction_repository.dart';

final predictionRepositoryProvider = Provider<PredictionRepository>((ref) {
  return PredictionRepository();
});

final predictionProvider =
    StateNotifierProvider<PredictionNotifier, AsyncValue<PredictionDayModel>>((
      ref,
    ) {
      return PredictionNotifier(ref.read(predictionRepositoryProvider));
    });

class PredictionNotifier extends StateNotifier<AsyncValue<PredictionDayModel>> {
  PredictionNotifier(this._repository) : super(const AsyncLoading());

  final PredictionRepository _repository;

  Future<void> load({required int jornadaId}) async {
    state = const AsyncLoading();

    try {
      final data = await _repository.loadPredictionDay(jornadaId: jornadaId);

      state = AsyncData(data);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  void updateMatch(MatchPredictionModel updatedMatch) {
    state.whenData((day) {
      final matches = day.matches.map((match) {
        if (match.matchId == updatedMatch.matchId) {
          return updatedMatch;
        }
        return match;
      }).toList();

      state = AsyncData(day.copyWith(matches: matches));
    });
  }

  Future<bool> save() async {
    return state.when(
      loading: () async => false,
      error: (_, __) async => false,
      data: (day) async {
        return _repository.savePredictions(day);
      },
    );
  }
}
