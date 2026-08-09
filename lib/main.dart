import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'app/bootstrap.dart';
import 'core/storage/preferences_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializa la configuración de la aplicación.
  await AppBootstrap.initialize();

  // Inicializa SharedPreferences una sola vez.
  await PreferencesStorage.init();

  // Firebase (para notificaciones push) hoy solo tiene soporte real
  // en Android/iOS/Web — en Windows desktop directamente no existe
  // esa implementación nativa. Sin este resguardo, la app no
  // arrancaría en Windows.
  if (kIsWeb) {
    try {
      await Firebase.initializeApp(
        options: const FirebaseOptions(
          apiKey: 'AIzaSyDhvodzRm-t8iWbTsqAXs0Gq2srkErJBas',
          authDomain: 'touchliga-1a796.firebaseapp.com',
          projectId: 'touchliga-1a796',
          storageBucket: 'touchliga-1a796.firebasestorage.app',
          messagingSenderId: '371860469223',
          appId: '1:371860469223:web:cc19def30a5d1810917942',
          measurementId: 'G-F846LYGJJW',
        ),
      );
    } catch (_) {
      // Si falla, la app sigue funcionando normal, solo sin push.
    }
  } else if (defaultTargetPlatform == TargetPlatform.android) {
    try {
      await Firebase.initializeApp();
    } catch (_) {
      // Si falla (por ejemplo, google-services.json ausente o mal
      // configurado), la app sigue funcionando normal, solo sin push.
    }
  }

  runApp(const ProviderScope(child: TouchligaApp()));
}
