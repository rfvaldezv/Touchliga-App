class ApiException implements Exception {
  const ApiException({required this.message, this.statusCode, this.details});

  final String message;

  final int? statusCode;

  final Object? details;

  bool get unauthorized => statusCode == 401;

  bool get forbidden => statusCode == 403;

  bool get notFound => statusCode == 404;

  bool get validationError => statusCode == 422;

  bool get serverError => statusCode != null && statusCode! >= 500;

  @override
  String toString() {
    if (statusCode == null) {
      return message;
    }

    return 'ApiException($statusCode): $message';
  }

  factory ApiException.badRequest([String? message]) {
    return ApiException(
      statusCode: 400,
      message: message ?? 'Solicitud incorrecta.',
    );
  }

  factory ApiException.unauthorized([String? message]) {
    return ApiException(
      statusCode: 401,
      message: message ?? 'Debe iniciar sesión.',
    );
  }

  factory ApiException.forbidden([String? message]) {
    return ApiException(
      statusCode: 403,
      message: message ?? 'Acceso denegado.',
    );
  }

  factory ApiException.notFound([String? message]) {
    return ApiException(
      statusCode: 404,
      message: message ?? 'Recurso no encontrado.',
    );
  }

  factory ApiException.validation([String? message]) {
    return ApiException(
      statusCode: 422,
      message: message ?? 'Error de validación.',
    );
  }

  factory ApiException.server([String? message]) {
    return ApiException(
      statusCode: 500,
      message: message ?? 'Error interno del servidor.',
    );
  }

  factory ApiException.network([String? message]) {
    return ApiException(
      message: message ?? 'No fue posible conectar con el servidor.',
    );
  }
}
