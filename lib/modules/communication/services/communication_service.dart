import '../../../core/network/api_client.dart';
import '../models/anuncio_model.dart';
import '../models/contacto_model.dart';
import '../models/mensaje_model.dart';

class CommunicationService {
  CommunicationService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<List<AnuncioModel>> getAnuncios() async {
    final response = await _apiClient.getList('/api/anuncios');
    return response.data!.map((j) => AnuncioModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> reaccionarAnuncio({required int anuncioId, required String emoji}) async {
    await _apiClient.post('/api/anuncios/$anuncioId/reaccionar', body: {'emoji': emoji});
  }

  Future<void> crearAnuncio({
    required String titulo,
    required String contenido,
    String? imagenUrl,
  }) async {
    await _apiClient.post(
      '/api/anuncios',
      body: {'titulo': titulo, 'contenido': contenido, 'imagenUrl': imagenUrl},
    );
  }

  Future<void> editarAnuncio({
    required int id,
    required String titulo,
    required String contenido,
    required bool reenviarPush,
    String? imagenUrl,
  }) async {
    await _apiClient.put(
      '/api/anuncios/$id',
      body: {
        'id': id,
        'titulo': titulo,
        'contenido': contenido,
        'reenviarPush': reenviarPush,
        'imagenUrl': imagenUrl,
      },
    );
  }

  Future<void> eliminarAnuncio(int id) async {
    await _apiClient.delete('/api/anuncios/$id');
  }

  Future<List<ContactoModel>> getMisContactos() async {
    final response = await _apiClient.getList('/api/mensajes/contactos');
    return response.data!.map((j) => ContactoModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<ContactoModel>> getOrganizadores() async {
    final response = await _apiClient.getList('/api/mensajes/organizadores');
    return response.data!.map((j) => ContactoModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<ContactoModel>> getTodosLosParticipantes() async {
    final response = await _apiClient.getList('/api/mensajes/participantes');
    return response.data!.map((j) => ContactoModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<List<MensajeModel>> getConversacion(int otroUsuarioId) async {
    final response = await _apiClient.getList('/api/mensajes/conversacion/$otroUsuarioId');
    return response.data!.map((j) => MensajeModel.fromJson(j as Map<String, dynamic>)).toList();
  }

  Future<void> enviarMensaje({
    required int destinatarioId,
    required String contenido,
    String? imagenUrl,
  }) async {
    await _apiClient.post(
      '/api/mensajes',
      body: {'destinatarioId': destinatarioId, 'contenido': contenido, 'imagenUrl': imagenUrl},
    );
  }

  Future<void> editarMensaje({
    required int id,
    required String contenido,
    required bool reenviarPush,
    String? imagenUrl,
  }) async {
    await _apiClient.put(
      '/api/mensajes/$id',
      body: {
        'id': id,
        'contenido': contenido,
        'reenviarPush': reenviarPush,
        'imagenUrl': imagenUrl,
      },
    );
  }

  Future<void> eliminarMensaje(int id) async {
    await _apiClient.delete('/api/mensajes/$id');
  }

  Future<void> marcarConversacionLeida(int otroUsuarioId) async {
    await _apiClient.post('/api/mensajes/conversacion/$otroUsuarioId/marcar-leida');
  }
}
