// Placeholder for Firebase configuration.
// Generate this file by running: flutterfire configure
// See README for setup instructions.

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
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
      case TargetPlatform.linux:
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCEJYsWCdPDZ0oHk68vPRb9cSB__KggZSQ',
    appId: '1:211642743133:web:b3e97271b3bd51d94650b4',
    messagingSenderId: '211642743133',
    projectId: 'grakpossedartapp',
    authDomain: 'grakpossedartapp.firebaseapp.com',
    storageBucket: 'grakpossedartapp.firebasestorage.app',
    measurementId: 'G-YEBT14VTY9',
  );
}