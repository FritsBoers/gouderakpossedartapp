import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
