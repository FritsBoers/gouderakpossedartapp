import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'app.dart';

/// Whether Firebase was successfully initialized with real credentials.
bool firebaseInitialized = false;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Check if Firebase is actually configured (not placeholder values)
  final isConfigured = DefaultFirebaseOptions.web.apiKey != 'YOUR_API_KEY';

  if (isConfigured) {
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      firebaseInitialized = true;
    } catch (e) {
      debugPrint('Firebase initialization failed: $e');
      firebaseInitialized = false;
    }
  } else {
    debugPrint('Firebase not configured, running in offline/local mode.');
  }

  runApp(
    const ProviderScope(
      child: GouderakDartsApp(),
    ),
  );
}
