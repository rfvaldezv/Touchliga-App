import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/cuenta_corriente_model.dart';
import '../models/estatus_pago_model.dart';
import '../models/resumen_financiero_model.dart';
import '../models/resumen_pago_model.dart';
import '../services/pagos_service.dart';

final pagosServiceProvider = Provider<PagosService>((ref) {
  return PagosService(apiClient: ApiClient());
});

final resumenFinancieroProvider =
    FutureProvider.autoDispose.family<ResumenFinancieroModel, int>((ref, temporadaId) async {
  return ref.read(pagosServiceProvider).getResumenFinanciero(temporadaId);
});

final miPagoProvider = FutureProvider.autoDispose.family<ResumenPagoModel, int>((ref, temporadaId) async {
  return ref.read(pagosServiceProvider).getMiPago(temporadaId);
});

final cuentaCorrienteProvider =
    FutureProvider.autoDispose.family<CuentaCorrienteModel, int>((ref, usuarioId) async {
  return ref.read(pagosServiceProvider).getCuentaCorriente(usuarioId);
});

final estatusPagosProvider =
    FutureProvider.autoDispose.family<List<EstatusPagoModel>, int>((ref, temporadaId) async {
  return ref.read(pagosServiceProvider).getEstatusPagos(temporadaId);
});
