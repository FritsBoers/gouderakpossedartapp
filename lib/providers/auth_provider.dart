import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';

/// Provides the AuthService instance.
final authServiceProvider = Provider<AuthService>((ref) => AuthService());

/// Stream provider for Firebase auth state.
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

/// Provider for the current user's Firestore profile.
/// Auto-creates the Firestore document if it doesn't exist (e.g. after Google redirect).
/// Syncs emailVerified status from Auth to Firestore.
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return null;

  final authService = ref.read(authServiceProvider);
  // Ensure Firestore profile exists (handles redirect-based sign-in)
  await authService.ensureUserDocument(user);
  // Sync emailVerified status from Auth to Firestore
  if (user.emailVerified) {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({'emailVerified': true});
  }
  return authService.getUserProfile(user.uid);
});

/// Provider for all registered (and verified) users.
final allUsersProvider = FutureProvider<List<UserModel>>((ref) async {
  final snapshot = await FirebaseFirestore.instance.collection('users').get();
  return snapshot.docs
      .map((doc) => UserModel.fromFirestore(doc))
      .where((user) => user.emailVerified)
      .toList();
});

/// Provider to check if email is verified.
final isEmailVerifiedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull?.emailVerified ?? false;
});
