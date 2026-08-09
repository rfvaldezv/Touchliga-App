import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;

class ApiConstants {
  ApiConstants._();

  /// Ambiente — normalmente false (usa tu computadora, para
  /// desarrollo día a día). Para compilar apuntando al servidor real
  /// (por ejemplo, al generar el APK para tus amigos), se activa SIN
  /// tocar este archivo:
  ///
  ///   flutter build apk --dart-define=PRODUCTION=true
  ///
  /// Así nunca se te queda "pegado" en producción por accidente
  /// mientras sigues desarrollando normal con `flutter run`.
  static const bool production = bool.fromEnvironment('PRODUCTION', defaultValue: false);

  /// Puerto real de tu API local (según launchSettings.json de Touchliga.Api).
  static const String _devPort = '5024';

  /// Cambia esto a `true` cuando estés probando en un **celular físico**
  /// conectado por USB, y a `false` cuando vuelvas a usar el emulador.
  /// Android no permite distinguir automáticamente entre emulador y
  /// dispositivo físico, así que este es el único punto que debes
  /// tocar a mano al cambiar de uno a otro.
  static const bool usePhysicalDevice = true;

  /// IP de tu PC en la red local (ipconfig → Dirección IPv4), usada
  /// solo cuando usePhysicalDevice = true. Tu celular y tu PC deben
  /// estar conectados a la misma red WiFi.
  static const String _lanIp = '192.168.1.14';

  /// Desarrollo — detecta automáticamente la dirección correcta según
  /// dónde estés corriendo la app, para no tener que editar esto cada
  /// vez que cambias de dispositivo:
  ///  - Emulador Android: 10.0.2.2 (localhost del emulador apunta a
  ///    sí mismo, no a tu PC).
  ///  - Windows / Web (Chrome/Edge) / iOS simulator: localhost sí
  ///    funciona directo, porque corren en la misma máquina que la API.
  ///  - Celular físico: ninguno de estos funciona — usa la IP de tu
  ///    PC en la red local (ver usePhysicalDevice arriba).
  static String get devBaseUrl {
    if (defaultTargetPlatform == TargetPlatform.android) {
      return usePhysicalDevice
          ? 'http://$_lanIp:$_devPort'
          : 'http://10.0.2.2:$_devPort';
    }

    return 'http://localhost:$_devPort';
  }

  /// Producción
  static const String prodBaseUrl = 'https://rfvaldezv-001-site32.ltempurl.com';

  /// URL utilizada por la aplicación
  static String get baseUrl => production ? prodBaseUrl : devBaseUrl;

  //=========================
  // AUTH
  //=========================

  static const String login = '/api/auth/login';

  static const String refreshToken = '/api/auth/refresh';

  static const String logout = '/api/auth/logout';

  //=========================
  // DASHBOARD
  //=========================

  static const String dashboard = '/api/dashboard';

  //=========================
  // LIGAS
  //=========================

  static const String ligas = '/api/ligas';

  //=========================
  // TEMPORADAS
  //=========================

  static const String temporadas = '/api/temporadas';

  //=========================
  // JORNADAS
  //=========================

  static const String jornadas = '/api/jornadas';

  static String cerrarJornada(int jornadaId) => '/api/jornadas/$jornadaId/cerrar';

  //=========================
  // EQUIPOS
  //=========================

  static const String equipos = '/api/equipos';

  //=========================
  // PARTIDOS
  //=========================

  static const String partidos = '/api/partidos';

  static String partidosPorJornada(int jornadaId) => '/api/partidos/jornada/$jornadaId';

  static String capturarResultado(int partidoId) => '/api/partidos/$partidoId/resultado';

  static String marcarDesempate(int partidoId) => '/api/partidos/$partidoId/desempate';

  //=========================
  // PRONÓSTICOS
  //=========================

  static const String pronosticos = '/api/pronosticos';

  static String guardarPronosticosLote(int jornadaId) =>
      '/api/pronosticos/jornada/$jornadaId/lote';

  static String misPronosticosPorJornada(int jornadaId) =>
      '/api/pronosticos/mios/jornada/$jornadaId';

  //=========================
  // TABLA GENERAL
  //=========================

  static String estandaresPorTemporada(int temporadaId) =>
      '/api/estandares/temporada/$temporadaId';

  //=========================
  // PERFIL
  //=========================

  static const String profile = '/api/profile';
}
