import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError('Firebase web nije konfigurisan.');
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError('Platforma nije podržana.');
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAqBVAyB1IBPbRlDelT5rU0tmWu57EfPbc',
    appId: '1:273314954521:android:37e04ff6b00b4651ae1988',
    messagingSenderId: '273314954521',
    projectId: 'bkic-saff',
    storageBucket: 'bkic-saff.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDHbfJKgoHgLC2gaxzZrjY0hlIRJ2D7C-I',
    appId: '1:273314954521:ios:4ec61c20f7b9eb9fae1988',
    messagingSenderId: '273314954521',
    projectId: 'bkic-saff',
    storageBucket: 'bkic-saff.firebasestorage.app',
    iosBundleId: 'com.example.bkicApp',
  );

}