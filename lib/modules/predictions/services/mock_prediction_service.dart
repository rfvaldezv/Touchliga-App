import '../models/match_prediction_model.dart';
import '../models/prediction_day_model.dart';
import 'prediction_service.dart';

class MockPredictionService implements PredictionService {
  @override
  Future<PredictionDayModel> loadPredictionDay({required int jornadaId}) async {
    await Future.delayed(const Duration(milliseconds: 500));

    return PredictionDayModel(
      jornadaId: jornadaId,
      leagueId: 1,
      leagueName: 'Touchliga',
      tournamentId: 1,
      tournamentName: 'Apertura 2026',
      round: jornadaId,
      isOpen: true,
      matches: [
        MatchPredictionModel(
          matchId: 1,
          localTeamId: 1,
          visitorTeamId: 2,
          localTeam: 'América',
          visitorTeam: 'Chivas',
          matchDate: DateTime(2026, 7, 24, 20),
          round: jornadaId,
        ),
        MatchPredictionModel(
          matchId: 2,
          localTeamId: 3,
          visitorTeamId: 4,
          localTeam: 'Cruz Azul',
          visitorTeam: 'Pumas',
          matchDate: DateTime(2026, 7, 25, 19),
          round: jornadaId,
        ),
      ],
    );
  }

  @override
  Future<bool> savePredictions(PredictionDayModel predictionDay) async {
    await Future.delayed(const Duration(milliseconds: 700));

    return predictionDay.isComplete;
  }
}
