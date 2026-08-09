import 'welcome_model.dart';
import 'current_round_model.dart';
import 'pending_predictions_model.dart';

class DashboardModel {
  const DashboardModel({
    required this.welcome,
    required this.currentRound,
    required this.pendingPredictions,
  });

  final WelcomeModel welcome;
  final CurrentRoundModel currentRound;
  final PendingPredictionsModel pendingPredictions;
}
