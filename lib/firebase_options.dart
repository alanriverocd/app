// IMPORTANTE: Este archivo debe generarse con FlutterFire CLI.
// Ejecuta el siguiente comando en la carpeta app/ para generarlo:
//
//   dart pub global activate flutterfire_cli
//   flutterfire configure --project=finatiol
//
// Ese comando genera este archivo automaticamente con los valores correctos.
// Por ahora se incluye un placeholder para que compile.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions no esta configurado para esta plataforma. '
          'Ejecuta: flutterfire configure --project=finatiol',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAGY5_Gsv73QAhA7J3cOjoEeshjxQ5cR5w',
    appId: '1:590804727431:web:908b07f0e2980e58c8aa22',
    messagingSenderId: '590804727431',
    projectId: 'finatiol',
    authDomain: 'finatiol.firebaseapp.com',
    storageBucket: 'finatiol.firebasestorage.app',
    measurementId: 'G-75DEBNKD0F',
  );

  // TODO: Reemplazar estos valores ejecutando: flutterfire configure --project=finatiol

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAr3ezTEnhlcw2uILwZfsfJL9JpDBrmqkQ',
    appId: '1:590804727431:android:39fa1d54eb289d22c8aa22',
    messagingSenderId: '590804727431',
    projectId: 'finatiol',
    storageBucket: 'finatiol.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyADM5918et-j-Z5AtmgKnjQzAwmUKA3wgo',
    appId: '1:590804727431:ios:064c08a67e8ca277c8aa22',
    messagingSenderId: '590804727431',
    projectId: 'finatiol',
    storageBucket: 'finatiol.firebasestorage.app',
    iosBundleId: 'com.finatiol.finatiol',
  );

}