import 'package:dio/dio.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../../app/constants/api_constants.dart';
import '../storage/secure_storage.dart';
import 'api_exception.dart';
import 'api_response.dart';

/// Cliente HTTP centralizado sobre Dio.
///
/// Antes este archivo usaba `package:http` directamente, un paquete que
/// ni siquiera estaba declarado en pubspec.yaml (rompía la compilación),
/// mientras `dio` y `pretty_dio_logger` estaban instalados pero sin usar.
/// Ahora se usa Dio, lo que además permite:
///  - Inyectar el token de sesión automáticamente en cada petición.
///  - Loguear requests/responses en desarrollo.
///  - Centralizar el manejo de errores 401/403/etc.
class ApiClient {
  /// Se dispara UNA vez cuando el token expira de verdad (ni el
  /// access token ni el refresh token sirven ya). La app lo conecta
  /// al arrancar (ver AuthNotifier) para mandar al usuario al login
  /// con un mensaje claro, en vez de dejar que cada pantalla falle
  /// distinto y en silencio.
  static void Function(String mensaje)? onSesionExpirada;

  ApiClient({Dio? dio})
    : _dio =
          dio ??
          Dio(
            BaseOptions(
              baseUrl: ApiConstants.baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              headers: const {
                'Accept': 'application/json',
                'Content-Type': 'application/json',
              },
            ),
          ) {
    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStorage.getAccessToken();

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          handler.next(options);
        },

        // Cuando el access token expira (60 min), el backend responde
        // 401. En vez de dejar que el error le llegue a la pantalla y
        // obligar al usuario a loguearse de nuevo, usamos el refresh
        // token (dura 30 días) para pedir un access token nuevo de
        // forma transparente, y reintentamos la petición original.
        onError: (error, handler) async {
          final esNoAutorizado = error.response?.statusCode == 401;
          final esEndpointDeAuth = error.requestOptions.path.contains(
            '/api/auth/',
          );
          final yaSeReintento = error.requestOptions.extra['retried'] == true;

          if (esNoAutorizado && !esEndpointDeAuth && !yaSeReintento) {
            final renovado = await _tryRefreshToken();

            if (renovado) {
              final nuevoToken = await SecureStorage.getAccessToken();
              final opciones = error.requestOptions;

              opciones.headers['Authorization'] = 'Bearer $nuevoToken';
              opciones.extra['retried'] = true;

              try {
                final respuesta = await _dio.fetch(opciones);
                return handler.resolve(respuesta);
              } catch (_) {
                // Si el reintento también falla, seguimos con el
                // error original en vez de ocultarlo.
              }
            }

            // Ni el token actual ni el refresh sirvieron -- la sesión
            // ya no es válida de verdad. En vez de dejar que cada
            // pantalla falle con un error críptico distinto, se avisa
            // una sola vez, claro, y se manda al usuario al login.
            await SecureStorage.clearSession();
            onSesionExpirada?.call('Tu sesión expiró — por favor inicia sesión de nuevo.');
          }

          handler.next(error);
        },
      ),
    );

    if (!ApiConstants.production) {
      _dio.interceptors.add(
        PrettyDioLogger(
          requestHeader: true,
          requestBody: true,
          responseBody: true,
          error: true,
          compact: true,
        ),
      );
    }
  }

  final Dio _dio;

  // Compartido entre todas las instancias de ApiClient: si varias
  // peticiones fallan con 401 al mismo tiempo, solo se dispara UNA
  // renovación (no una por cada petición que estaba en vuelo).
  static Future<String?>? _refreshFuture;

  Future<bool> _tryRefreshToken() async {
    _refreshFuture ??= _performRefresh();

    final nuevoAccessToken = await _refreshFuture;

    _refreshFuture = null;

    return nuevoAccessToken != null;
  }

  Future<String?> _performRefresh() async {
    final refreshToken = await SecureStorage.getRefreshToken();

    if (refreshToken == null || refreshToken.isEmpty) return null;

    try {
      // Dio aparte, sin los interceptores de arriba: si usáramos
      // _dio normal, un 401 aquí mismo entraría en el mismo
      // onError y podría causar un ciclo.
      final dioSinInterceptores = Dio(
        BaseOptions(baseUrl: ApiConstants.baseUrl),
      );

      final respuesta = await dioSinInterceptores.post(
        ApiConstants.refreshToken,
        data: {'refreshToken': refreshToken},
      );

      final data = respuesta.data as Map<String, dynamic>;
      final nuevoAccessToken = data['accessToken'] as String;
      final nuevoRefreshToken = data['refreshToken'] as String;

      await SecureStorage.saveAccessToken(nuevoAccessToken);
      await SecureStorage.saveRefreshToken(nuevoRefreshToken);

      return nuevoAccessToken;
    } catch (_) {
      // El refresh token también expiró o es inválido: no hay forma
      // de renovar la sesión sin que el usuario vuelva a loguearse.
      await SecureStorage.clearSession();

      return null;
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> get(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    String? token,
  }) {
    return _request(
      () => _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: _optionsFor(token),
      ),
    );
  }

  /// Para endpoints que devuelven un arreglo JSON en la raíz
  /// (p. ej. `GET /api/ligas` -> `[{...}, {...}]`), a diferencia de
  /// [get] que asume un objeto JSON en la raíz.
  Future<ApiResponse<List<dynamic>>> getList(
    String endpoint, {
    Map<String, dynamic>? queryParameters,
    String? token,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        queryParameters: queryParameters,
        options: _optionsFor(token),
      );

      final data = response.data;

      return ApiResponse.success(
        data is List ? data : <dynamic>[],
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> post(
    String endpoint, {
    Object? body,
    String? token,
  }) {
    return _request(
      () => _dio.post(endpoint, data: body, options: _optionsFor(token)),
    );
  }

  /// Para endpoints que devuelven un valor "pelón" en la raíz
  /// (p. ej. `POST /api/jornadas` -> `5`, solo el id como número),
  /// a diferencia de [post] que asume un objeto JSON en la raíz.
  Future<T> postForValue<T>(
    String endpoint, {
    Object? body,
    String? token,
  }) async {
    try {
      final response = await _dio.post(
        endpoint,
        data: body,
        options: _optionsFor(token),
      );

      return response.data as T;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Para endpoints que regresan un valor simple (int, bool, string),
  /// no un objeto ni una lista -- ej. un conteo.
  Future<T> getForValue<T>(
    String endpoint, {
    String? token,
  }) async {
    try {
      final response = await _dio.get(
        endpoint,
        options: _optionsFor(token),
      );

      return response.data as T;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  /// Para descargar archivos binarios (PDF, imágenes, etc.) -- regresa
  /// los bytes crudos, no los intenta parsear como JSON.
  Future<List<int>> getBytes(
    String endpoint, {
    String? token,
  }) async {
    try {
      final opciones = _optionsFor(token) ?? Options();
      final response = await _dio.get<List<int>>(
        endpoint,
        options: opciones.copyWith(responseType: ResponseType.bytes),
      );

      return response.data!;
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<ApiResponse<Map<String, dynamic>>> put(
    String endpoint, {
    Object? body,
    String? token,
  }) {
    return _request(
      () => _dio.put(endpoint, data: body, options: _optionsFor(token)),
    );
  }

  Future<ApiResponse<Map<String, dynamic>>> delete(
    String endpoint, {
    String? token,
  }) {
    return _request(() => _dio.delete(endpoint, options: _optionsFor(token)));
  }

  /// Permite forzar un token específico (por ejemplo, durante el login
  /// o pruebas); si no se pasa, el interceptor usa el de SecureStorage.
  Options? _optionsFor(String? token) {
    if (token == null) return null;

    return Options(headers: {'Authorization': 'Bearer $token'});
  }

  Future<ApiResponse<Map<String, dynamic>>> _request(
    Future<Response> Function() call,
  ) async {
    try {
      final response = await call();

      final data = response.data;

      return ApiResponse.success(
        data is Map<String, dynamic> ? data : <String, dynamic>{},
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  ApiException _mapError(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    final message = (data is Map)
        ? (data['message']?.toString() ?? data['title']?.toString())
        : null;

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException.network('Tiempo de espera agotado.');
      case DioExceptionType.connectionError:
        return ApiException.network();
      default:
        break;
    }

    switch (status) {
      case 400:
        return ApiException.badRequest(message);
      case 401:
        return ApiException.unauthorized(message);
      case 403:
        return ApiException.forbidden(message);
      case 404:
        return ApiException.notFound(message);
      case 422:
        return ApiException.validation(message);
      default:
        if (status != null && status >= 500) {
          return ApiException.server(message);
        }
        return ApiException(
          statusCode: status,
          message: message ?? 'Error del servidor',
        );
    }
  }

  void dispose() {
    _dio.close();
  }
}
