import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../app/constants/api_constants.dart';
import '../../core/storage/secure_storage.dart';

/// Servicio genérico de subida de archivos — sirve para la foto de
/// perfil, escudos de equipo, banners de patrocinador, etc. Sube el
/// archivo y regresa una URL que ya se puede usar directamente en
/// cualquier campo "URL de imagen" existente.
///
/// A propósito trabaja con bytes (no con `dart:io.File` ni
/// `Platform`) — eso es lo que permite que funcione igual en
/// Android, Windows y Web. `dart:io` no tiene acceso real al
/// sistema de archivos en la web.
class ArchivoService {
  /// Usa su propio Dio (no el ApiClient normal) porque una subida de
  /// archivo va como multipart/form-data, no como JSON.
  Future<String> subir(Uint8List bytes, String nombreArchivo) async {
    final token = await SecureStorage.getAccessToken();

    final dio = Dio(BaseOptions(baseUrl: ApiConstants.baseUrl));

    final formData = FormData.fromMap({
      'archivo': MultipartFile.fromBytes(bytes, filename: nombreArchivo),
    });

    final response = await dio.post(
      '/api/archivos',
      data: formData,
      options: Options(
        headers: {'Authorization': 'Bearer $token'},
      ),
    );

    return response.data['url'] as String;
  }
}
