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
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyDummy-Web-Key',
    appId: '1:1234567890:web:abcdef123456',
    messagingSenderId: '1234567890',
    projectId: 'offline-first-test',
    authDomain: 'offline-first-test.firebaseapp.com',
    storageBucket: 'offline-first-test.appspot.com',
    measurementId: 'G-DUMMY',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDummy-Android-Key',
    appId: '1:1234567890:android:abcdef123456',
    messagingSenderId: '1234567890',
    projectId: 'offline-first-test',
    storageBucket: 'offline-first-test.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDummy-iOS-Key',
    appId: '1:1234567890:ios:abcdef123456',
    messagingSenderId: '1234567890',
    projectId: 'offline-first-test',
    storageBucket: 'offline-first-test.appspot.com',
    iosBundleId: 'com.example.offlineFirst',
  );
}
