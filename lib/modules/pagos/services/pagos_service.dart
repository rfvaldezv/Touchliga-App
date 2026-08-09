import '../../../core/network/api_client.dart';
import '../models/cuenta_corriente_model.dart';
import '../models/estatus_pago_model.dart';
import '../models/pago_model.dart';
import '../models/resumen_financiero_model.dart';
import '../models/resumen_pago_model.dart';

class PagosService {
  PagosService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<ResumenPagoModel> getMiPago(int temporadaId) async {
    final response = await _apiClient.get('/api/pagos/mio/temporada/$temporadaId');
    return ResumenPagoModel.fromJson(response.data!);
  }

  Future<List<EstatusPagoModel>> getEstatusPagos(int temporadaId) async {
    final response = await _apiClient.getList('/api/pagos/temporada/$temporadaId/estatus');
    return response.data!
        .map((j) => EstatusPagoModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  Future<int> registrarPago({
    required int usuarioId,
    required int temporadaId,
    required double monto,
    required String metodoPago,
    required DateTime fechaPago,
    String? referencia,
  }) async {
    return _apiClient.postForValue<int>(
      '/api/pagos',
      body: {
        'usuarioId': usuarioId,
        'temporadaId': temporadaId,
        'monto': monto,
        'metodoPago': metodoPago,
        'fechaPago': fechaPago.toIso8601String(),
        'referencia': referencia,
      },
    );
  }

  Future<void> eliminarPago(int id) async {
    await _apiClient.delete('/api/pagos/$id');
  }

  /// Crea la sesión de pago con tarjeta y regresa la URL de Stripe
  /// Checkout — la app la abre en el navegador, no hay SDK nativo
  /// de por medio. [tipoPago]: "Completo" o "Mitad".
  Future<String> iniciarCheckout(int temporadaId, {required String tipoPago}) async {
    final response = await _apiClient.post(
      '/api/pagos/checkout/temporada/$temporadaId?tipoPago=$tipoPago',
    );
    return response.data!['url'] as String;
  }

  Future<CuentaCorrienteModel> getCuentaCorriente(int usuarioId) async {
    final response = await _apiClient.get('/api/pagos/cuenta-corriente/usuario/$usuarioId');
    return CuentaCorrienteModel.fromJson(response.data!);
  }

  Future<ResumenFinancieroModel> getResumenFinanciero(int temporadaId) async {
    final response = await _apiClient.get('/api/pagos/resumen/temporada/$temporadaId');
    return ResumenFinancieroModel.fromJson(response.data!);
  }
}
