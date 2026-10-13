// ignore_for_file: type=lint
// Generado (de verdad) por el comando `flutterfire configure`.
//
// Este archivo es una PLANTILLA. Tiene que ser reemplazado automáticamente
// cuando corrés `flutterfire configure` en la carpeta del proyecto (ver el
// paso a paso en README.md). No edites estos valores a mano: no son reales,
// la app no va a poder conectarse a Firebase hasta que el comando los
// reemplace por los de tu propio proyecto.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'Este proyecto todavía no corrió `flutterfire configure`.\n'
        'Seguí el paso a paso de README.md antes de ejecutar la app.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no está configurado para esta plataforma.\n'
          'Corré `flutterfire configure` (ver README.md).',
        );
    }
  }

  // Valores de ejemplo: flutterfire configure va a sobrescribir TODO este
  // archivo con los datos reales de tu proyecto de Firebase.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'TU_API_KEY_ANDROID',
    appId: 'TU_APP_ID_ANDROID',
    messagingSenderId: 'TU_SENDER_ID',
    projectId: 'TU_PROJECT_ID',
    storageBucket: 'TU_PROJECT_ID.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TU_API_KEY_IOS',
    appId: 'TU_APP_ID_IOS',
    messagingSenderId: 'TU_SENDER_ID',
    projectId: 'TU_PROJECT_ID',
    storageBucket: 'TU_PROJECT_ID.appspot.com',
    iosBundleId: 'com.example.softGabi',
  );
}
