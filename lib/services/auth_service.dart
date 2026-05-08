import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

/// Handles authentication and user profile management.
/// Supports Google Sign-In and Email/Password with email verification.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of auth state changes.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Current Firebase user.
  User? get currentUser => _auth.currentUser;

  /// Sign in with email and password.
  Future<UserCredential> signInWithEmail(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Ensure user document exists (may have failed during signup)
    final user = credential.user;
    if (user != null) {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) {
        await _createUserDocument(
          uid: user.uid,
          email: user.email ?? email.trim(),
          displayName: user.displayName ?? 'Player',
          provider: 'email',
        );
      }
    }

    return credential;
  }

  /// Create account with email and password.
  /// Sends verification email and creates Firestore user document.
  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    // Update display name
    await credential.user?.updateDisplayName(displayName);

    // Send verification email
    await credential.user?.sendEmailVerification();

    // Create user document in Firestore
    await _createUserDocument(
      uid: credential.user!.uid,
      email: email.trim(),
      displayName: displayName,
      provider: 'email',
    );

    return credential;
  }

  /// Sign in with Google.
  Future<UserCredential> signInWithGoogle() async {
    final googleProvider = GoogleAuthProvider();
    googleProvider.addScope('email');
    googleProvider.addScope('profile');

    final credential = await _auth.signInWithPopup(googleProvider);

    // Create or update user document
    final user = credential.user!;
    final docRef = _firestore.collection('users').doc(user.uid);
    final doc = await docRef.get();

    if (!doc.exists) {
      await _createUserDocument(
        uid: user.uid,
        email: user.email ?? '',
        displayName: user.displayName ?? 'Player',
        provider: 'google',
        avatarUrl: user.photoURL,
      );
    }

    return credential;
  }

  /// Send email verification to current user.
  Future<void> sendEmailVerification() async {
    await _auth.currentUser?.sendEmailVerification();
  }

  /// Send password reset email.
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }

  /// Reload user to check email verification status.
  Future<void> reloadUser() async {
    await _auth.currentUser?.reload();
  }

  /// Sign out.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  /// Delete account and associated Firestore data.
  Future<void> deleteAccount() async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Delete Firestore user document
    await _firestore.collection('users').doc(user.uid).delete();

    // Delete the auth account
    await user.delete();
  }

  /// Get user profile from Firestore.
  Future<UserModel?> getUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromFirestore(doc);
  }

  /// Update user display name.
  Future<void> updateDisplayName(String displayName) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await user.updateDisplayName(displayName);
    await _firestore.collection('users').doc(user.uid).update({
      'displayName': displayName,
    });
  }

  /// Create user document in Firestore.
  Future<void> _createUserDocument({
    required String uid,
    required String email,
    required String displayName,
    required String provider,
    String? avatarUrl,
  }) async {
    final userModel = UserModel(
      uid: uid,
      displayName: displayName,
      avatarUrl: avatarUrl,
      email: email,
      provider: provider,
      emailVerified: provider == 'google', // Google accounts are pre-verified
      createdAt: DateTime.now(),
      stats: const PlayerStats(),
    );

    await _firestore.collection('users').doc(uid).set(userModel.toFirestore());
  }
}
