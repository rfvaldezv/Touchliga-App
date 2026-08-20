import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/configuracion_smtp_model.dart';
import '../services/configuracion_smtp_service.dart';

final configuracionSmtpServiceProvider = Provider<ConfiguracionSmtpService>((ref) {
  return ConfiguracionSmtpService(apiClient: ApiClient());
});

final configuracionSmtpProvider = FutureProvider.autoDispose<ConfiguracionSmtpModel>((ref) async {
  return ref.read(configuracionSmtpServiceProvider).obtener();
});
