import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
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

      // Activate App Check to prevent unauthorized API access
      await FirebaseAppCheck.instance.activate(
        webProvider: kDebugMode
            ? ReCaptchaV3Provider('6LeIxAcTAAAAAJcZVRqyHh71UMIEGNQ_MXjiZKhI') // debug key
            : ReCaptchaV3Provider('6LfcVeUsAAAAAAAnG2hzR_AIRn8JXJ3i0KQloqYr'),
      );

      firebaseInitialized = true;

      // Handle Google sign-in redirect result (for iOS/Safari)
      await AuthService().handleRedirectResult();

      // One-time migration: strip email field from all user documents
      _migrateRemoveEmails();
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

/// One-time migration: remove email field from all user documents.
/// Safe to run multiple times — no-op if field already absent.
void _migrateRemoveEmails() async {
  try {
    final firestore = FirebaseFirestore.instance;
    final snapshot = await firestore.collection('users').get();
    for (final doc in snapshot.docs) {
      final data = doc.data();
      if (data.containsKey('email')) {
        await doc.reference.update({'email': FieldValue.delete()});
      }
    }
    debugPrint('Migration: removed email field from ${snapshot.docs.length} user docs');
  } catch (e) {
    debugPrint('Migration failed (non-critical): $e');
  }
}
