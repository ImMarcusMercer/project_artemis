import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

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
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        return linux;
      case TargetPlatform.fuchsia:
        return android;
    }
  }

  static FirebaseOptions get web => FirebaseOptions(
        apiKey: _env('FIREBASE_WEB_API_KEY'),
        appId: _env('FIREBASE_WEB_APP_ID'),
        messagingSenderId: _env('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _env('FIREBASE_PROJECT_ID'),
        authDomain: dotenv.env['FIREBASE_AUTH_DOMAIN'],
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'],
        measurementId: dotenv.env['FIREBASE_MEASUREMENT_ID'],
      );

  static FirebaseOptions get android => FirebaseOptions(
        apiKey: _env('FIREBASE_ANDROID_API_KEY'),
        appId: _env('FIREBASE_ANDROID_APP_ID'),
        messagingSenderId: _env('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _env('FIREBASE_PROJECT_ID'),
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'],
      );

  static FirebaseOptions get ios => FirebaseOptions(
        apiKey: _env('FIREBASE_IOS_API_KEY'),
        appId: _env('FIREBASE_IOS_APP_ID'),
        messagingSenderId: _env('FIREBASE_MESSAGING_SENDER_ID'),
        projectId: _env('FIREBASE_PROJECT_ID'),
        storageBucket: dotenv.env['FIREBASE_STORAGE_BUCKET'],
        iosBundleId: dotenv.env['FIREBASE_IOS_BUNDLE_ID'] ?? 'com.example.artemis',
      );

  static FirebaseOptions get macos => ios;
  static FirebaseOptions get windows => web;
  static FirebaseOptions get linux => web;

  static String _env(String key) => dotenv.env[key] ?? '${key}_NOT_SET';
}
