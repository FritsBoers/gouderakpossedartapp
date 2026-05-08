import 'package:firebase_auth/firebase_auth.dart';
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
final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final authState = ref.watch(authStateProvider);
  final user = authState.valueOrNull;
  if (user == null) return null;

  final authService = ref.read(authServiceProvider);
  return authService.getUserProfile(user.uid);
});

/// Provider to check if email is verified.
final isEmailVerifiedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.valueOrNull?.emailVerified ?? false;
});
