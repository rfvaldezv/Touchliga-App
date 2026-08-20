import '../../../core/network/api_client.dart';
import '../models/configuracion_smtp_model.dart';

class ConfiguracionSmtpService {
  ConfiguracionSmtpService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<ConfiguracionSmtpModel> obtener() async {
    final response = await _apiClient.get('/api/configuracion/smtp');
    final data = response.data;
    if (data == null || data.isEmpty) return ConfiguracionSmtpModel.vacia();
    return ConfiguracionSmtpModel.fromJson(data);
  }

  Future<void> guardar(ConfiguracionSmtpModel configuracion) async {
    await _apiClient.put('/api/configuracion/smtp', body: configuracion.toJson());
  }
}
