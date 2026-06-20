// ignore_for_file: lines_longer_than_80_chars, avoid_classes_with_only_static_members
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
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
      case TargetPlatform.macOS:
        return macos;
      default:
        return web;
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBOAraJbQRJ_0Keqb6kyHByjCZhdG2WVXA',
    appId: '1:953750850312:web:c461d798e62670daafbabd',
    messagingSenderId: '953750850312',
    projectId: 'spendless-276d9',
    authDomain: 'spendless-276d9.firebaseapp.com',
    storageBucket: 'spendless-276d9.appspot.com',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBOAraJbQRJ_0Keqb6kyHByjCZhdG2WVXA',
    appId: '1:953750850312:android:c461d798e62670daafbabd',
    messagingSenderId: '953750850312',
    projectId: 'spendless-276d9',
    storageBucket: 'spendless-276d9.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyBOAraJbQRJ_0Keqb6kyHByjCZhdG2WVXA',
    appId: '1:953750850312:ios:c461d798e62670daafbabd',
    messagingSenderId: '953750850312',
    projectId: 'spendless-276d9',
    storageBucket: 'spendless-276d9.appspot.com',
    iosBundleId: 'com.spendlens.spendlens',
  );

  // macOS uses the same project; Firebase for macOS shares the iOS config
  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyBOAraJbQRJ_0Keqb6kyHByjCZhdG2WVXA',
    appId: '1:953750850312:ios:c461d798e62670daafbabd',
    messagingSenderId: '953750850312',
    projectId: 'spendless-276d9',
    storageBucket: 'spendless-276d9.appspot.com',
    iosBundleId: 'com.spendlens.spendlens',
  );
}
