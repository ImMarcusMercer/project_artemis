import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../firebase_options.dart';

class BackendState {
  const BackendState({
    required this.firebaseReady,
    required this.supabaseReady,
    required this.messages,
  });

  final bool firebaseReady;
  final bool supabaseReady;
  final List<String> messages;

  bool get isMockMode => !firebaseReady;
}

class BackendBootstrap {
  static Future<BackendState> initialize() async {
    final messages = <String>[];

    try {
      await dotenv.load(fileName: '.env');
    } catch (_) {
      messages.add('No .env file was found. The app is running in mock mode.');
    }

    var firebaseReady = false;
    var supabaseReady = false;

    if (_hasFirebaseConfig()) {
      try {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        firebaseReady = true;
      } catch (error) {
        messages.add('Firebase was not initialized: $error');
      }
    } else {
      messages.add('Firebase placeholders are still present. Auth and Firestore are using mock data.');
    }

    if (_hasSupabaseConfig()) {
      try {
        await Supabase.initialize(
          url: dotenv.env['SUPABASE_URL']!,
          anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
        );
        supabaseReady = true;
      } catch (error) {
        messages.add('Supabase Storage was not initialized: $error');
      }
    } else {
      messages.add('Supabase placeholders are still present. File upload is disabled until configured.');
    }

    return BackendState(
      firebaseReady: firebaseReady,
      supabaseReady: supabaseReady,
      messages: messages,
    );
  }

  static bool _hasFirebaseConfig() {
    final required = [
      dotenv.env['FIREBASE_PROJECT_ID'],
      dotenv.env['FIREBASE_MESSAGING_SENDER_ID'],
      dotenv.env['FIREBASE_WEB_APP_ID'] ?? dotenv.env['FIREBASE_ANDROID_APP_ID'],
    ];
    return required.every((value) => _isRealValue(value));
  }

  static bool _hasSupabaseConfig() {
    return _isRealValue(dotenv.env['SUPABASE_URL']) &&
        _isRealValue(dotenv.env['SUPABASE_ANON_KEY']);
  }

  static bool _isRealValue(String? value) {
    if (value == null || value.trim().isEmpty) return false;
    final lower = value.toLowerCase();
    return !lower.contains('your_') &&
        !lower.contains('placeholder') &&
        !lower.contains('not_set') &&
        !lower.contains('xxxx');
  }
}
