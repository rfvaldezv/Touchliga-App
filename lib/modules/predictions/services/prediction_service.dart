import '../models/prediction_day_model.dart';

/// Contrato para cualquier origen de datos de pronósticos.
///
/// Implementaciones:
///
/// - MockPredictionService
/// - ApiPredictionService
abstract class PredictionService {
  const PredictionService();

  Future<PredictionDayModel> loadPredictionDay({required int jornadaId});

  Future<bool> savePredictions(PredictionDayModel predictionDay);
}
