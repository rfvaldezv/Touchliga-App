import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../models/anuncio_model.dart';
import '../models/contacto_model.dart';
import '../services/communication_service.dart';

final communicationServiceProvider = Provider<CommunicationService>((ref) {
  return CommunicationService(apiClient: ApiClient());
});

final anunciosProvider = FutureProvider.autoDispose<List<AnuncioModel>>((ref) async {
  return ref.read(communicationServiceProvider).getAnuncios();
});

final misContactosProvider = FutureProvider.autoDispose<List<ContactoModel>>((ref) async {
  return ref.read(communicationServiceProvider).getMisContactos();
});

final organizadoresProvider = FutureProvider.autoDispose<List<ContactoModel>>((ref) async {
  return ref.read(communicationServiceProvider).getOrganizadores();
});

final todosLosParticipantesProvider = FutureProvider.autoDispose<List<ContactoModel>>((ref) async {
  return ref.read(communicationServiceProvider).getTodosLosParticipantes();
});

/// Total de mensajes sin leer -- para el globo/badge de la barra de
/// navegación inferior. Se recalcula cada vez que algo lo invalida
/// (por ejemplo, al volver de la pantalla de Mensajes).
final mensajesNoLeidosProvider = FutureProvider.autoDispose<int>((ref) async {
  return ref.read(communicationServiceProvider).getMensajesNoLeidos();
});
