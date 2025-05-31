import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
      );
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAmXiddm0vXH1QCkt3q5FPNQ0GYXZKMeSc',
    appId: '1:262065166385:android:36f9162928fafd8528dd10',
    messagingSenderId: '262065166385',
    projectId: 'sifter-v20',
    storageBucket: 'sifter-v20.firebasestorage.app',
    databaseURL: 'https://sifter-v20-default-rtdb.firebaseio.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyAmXiddm0vXH1QCkt3q5FPNQ0GYXZKMeSc',
    appId: '1:262065166385:ios:f484f369d141b9ba28dd10',
    messagingSenderId: '262065166385',
    projectId: 'sifter-v20',
    databaseURL: 'https://sifter-v20-default-rtdb.firebaseio.com',
    storageBucket: 'sifter-v20.firebasestorage.app',
    iosClientId: '262065166385-knkte1sgtg4lbani5euvueno1kcduup5.apps.googleusercontent.com',
    iosBundleId: 'com.example.sifter',
  );
} 