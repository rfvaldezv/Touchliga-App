import '../../../core/network/api_client.dart';
import '../models/prediction_day_model.dart';
import '../services/api_prediction_service.dart';
import '../services/prediction_service.dart';

class PredictionRepository {
  PredictionRepository({PredictionService? service})
    : _service = service ?? ApiPredictionService(apiClient: ApiClient());

  final PredictionService _service;

  PredictionService get service => _service;

  Future<PredictionDayModel> loadPredictionDay({required int jornadaId}) {
    return _service.loadPredictionDay(jornadaId: jornadaId);
  }

  Future<bool> savePredictions(PredictionDayModel predictionDay) {
    return _service.savePredictions(predictionDay);
  }
}
