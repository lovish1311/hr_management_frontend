import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for use with your Firebase apps.
///
/// Generated & maintained based on Firebase Console registration.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for iOS - '
          're-register in Firebase Console if iOS is required.',
        );
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macOS.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for Linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBavWMVLgC520xhWr9UNePrfwr-Svv2yzU',
    appId: '1:700146522997:android:ca8a48449e17121baf913c',
    messagingSenderId: '700146522997',
    projectId: 'hr-management-eecf8',
    storageBucket: 'hr-management-eecf8.firebasestorage.app',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCq376YdLcwA5tNGFJoijyHQc8S9oGOdCI',
    appId: '1:700146522997:web:072cc33584064864af913c',
    messagingSenderId: '700146522997',
    projectId: 'hr-management-eecf8',
    authDomain: 'hr-management-eecf8.firebaseapp.com',
    storageBucket: 'hr-management-eecf8.firebasestorage.app',
    measurementId: 'G-J9HQYR5G0K',
  );
}
