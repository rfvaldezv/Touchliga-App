import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/detalle_jornada_model.dart';
import '../models/ranking_model.dart';
import '../models/participante_pendiente_model.dart';
import '../services/reportes_service.dart';

final reportesServiceProvider = Provider<ReportesService>((ref) {
  return ReportesService(apiClient: ApiClient());
});

final detalleJornadaProvider =
    FutureProvider.autoDispose.family<List<DetalleJornadaModel>, int>((ref, jornadaId) async {
  return ref.read(reportesServiceProvider).getDetalleJornada(jornadaId);
});

final rankingProvider = FutureProvider.autoDispose.family<List<RankingModel>, int>((ref, temporadaId) async {
  return ref.read(reportesServiceProvider).getRanking(temporadaId);
});

final participantesPendientesProvider =
    FutureProvider.autoDispose.family<List<ParticipantePendienteModel>, int>((ref, jornadaId) async {
  return ref.read(reportesServiceProvider).getParticipantesPendientes(jornadaId);
});
