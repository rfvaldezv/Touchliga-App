import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../core/network/api_client.dart';
import '../../main.dart' show container;
import '../../modules/communication/providers/communication_provider.dart';

/// Registra este dispositivo para recibir notificaciones push, y
/// las procesa cuando llegan con la app abierta (primer plano).
///
/// Funciona en Android y en Web. En Windows desktop (donde se
/// desarrolla normalmente) no existe soporte de Firebase, así que
/// se sale de inmediato sin tronar nada.
class PushNotificationService {
  // TODO: pegar aquí la VAPID key generada en Firebase →
  // Configuración del proyecto → Cloud Messaging → Configuración
  // web → "Generar par de claves". Sin esto, getToken() no
  // funciona en el navegador (Android no la necesita).
  static const String _vapidKeyWeb =
      'BB4AXwFethwxeaw3HcqN_s8icGGh6cbjQx9A3e5xpIX9BnJeK-FGY6rATrDxMaCVCpezde-r_abRKeJ6Io-pWdE';

  static bool _yaInicializado = false;

  static bool get _soportado =>
      kIsWeb || defaultTargetPlatform == TargetPlatform.android;

  static Future<void> inicializar() async {
    if (!_soportado) return;
    if (_yaInicializado) return;

    try {
      final mensajeria = FirebaseMessaging.instance;

      await mensajeria.requestPermission();

      final token = kIsWeb
          ? await mensajeria.getToken(vapidKey: _vapidKeyWeb)
          : await mensajeria.getToken();

      if (token != null) {
        await _registrarEnBackend(token);
      }

      mensajeria.onTokenRefresh.listen(_registrarEnBackend);

      // Con la app abierta, Firebase no muestra la notificación del
      // sistema sola — pero sí actualizamos de inmediato el globo de
      // mensajes sin leer, para que se note algo cambió.
      FirebaseMessaging.onMessage.listen((mensaje) {
        debugPrint('Push recibido en primer plano: ${mensaje.notification?.title}');
        container.invalidate(mensajesNoLeidosProvider);
      });

      _yaInicializado = true;
    } catch (e) {
      debugPrint('No se pudo inicializar push: $e');
    }
  }

  static Future<void> _registrarEnBackend(String token) async {
    try {
      await ApiClient().post(
        '/api/notificaciones/dispositivo',
        body: {'token': token, 'plataforma': kIsWeb ? 'web' : 'android'},
      );
    } catch (e) {
      debugPrint('No se pudo registrar el token de push: $e');
    }
  }

  /// Se llama al cerrar sesión, para que este dispositivo deje de
  /// recibir notificaciones hasta que alguien vuelva a iniciar sesión.
  static Future<void> eliminarDelBackend() async {
    if (!_soportado) return;

    try {
      final token = kIsWeb
          ? await FirebaseMessaging.instance.getToken(vapidKey: _vapidKeyWeb)
          : await FirebaseMessaging.instance.getToken();

      if (token != null) {
        await ApiClient().delete('/api/notificaciones/dispositivo/$token');
      }
    } catch (e) {
      debugPrint('No se pudo eliminar el token de push: $e');
    }
  }
}
