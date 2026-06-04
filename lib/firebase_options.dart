// ⚠️ PLANTILLA — NO uses estos valores en producción.
//
// Genera el archivo real con FlutterFire CLI (recomendado):
//   dart pub global activate flutterfire_cli
//   flutterfire configure
//
// Eso sobrescribe este archivo con las claves reales de tu proyecto Firebase.
// Los valores de abajo son marcadores de posición para que el proyecto
// compile mientras configuras Firebase.
import 'package:firebase_core/firebase_core.dart'
    show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB0VOW4vXpqM7ik3o7FH_k3ozqrfhiusto',
    appId: '1:370036482652:android:5051baac9e69f4e23a7c99',
    messagingSenderId: '370036482652',
    projectId: 'vinca-data',
    storageBucket: 'vinca-data.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'TU_API_KEY_IOS',
    appId: 'TU_APP_ID_IOS',
    messagingSenderId: 'TU_SENDER_ID',
    projectId: 'vinca-data',
    storageBucket: 'vinca-data.appspot.com',
    iosBundleId: 'com.vincadata.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCIaDJ-UHfOkWm_qgnthuB_JrYNlOvBtE0',
    appId: '1:370036482652:web:2286fdb1f84224dd3a7c99',
    messagingSenderId: '370036482652',
    projectId: 'vinca-data',
    authDomain: 'vinca-data.firebaseapp.com',
    storageBucket: 'vinca-data.firebasestorage.app',
    measurementId: 'G-B95MJVDH8P',
  );

}