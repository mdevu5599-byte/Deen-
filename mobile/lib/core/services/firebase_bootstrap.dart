import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

/// Tracks whether Firebase was configured at build time. When google-services.json
/// (Android) / GoogleService-Info.plist (iOS) / --dart-define keys (web) are absent,
/// the app still runs in local-only (guest) mode.
class Fb {
  static bool ready = false;

  static const _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const _appId = String.fromEnvironment('FIREBASE_APP_ID');
  static const _senderId = String.fromEnvironment('FIREBASE_MESSAGING_SENDER_ID');
  static const _projectId = String.fromEnvironment('FIREBASE_PROJECT_ID');
  static const _authDomain = String.fromEnvironment('FIREBASE_AUTH_DOMAIN');

  static Future<void> init() async {
    try {
      if (kIsWeb) {
        if (_apiKey.isEmpty || _projectId.isEmpty || _appId.isEmpty) return;
        await Firebase.initializeApp(
          options: FirebaseOptions(
            apiKey: _apiKey,
            appId: _appId,
            messagingSenderId: _senderId,
            projectId: _projectId,
            authDomain: _authDomain.isEmpty ? null : _authDomain,
          ),
        );
      } else {
        await Firebase.initializeApp();
      }
      ready = true;
    } catch (_) {
      ready = false;
    }
  }

  static String? get uid => ready ? FirebaseAuth.instance.currentUser?.uid : null;
}
