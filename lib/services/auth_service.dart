import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ─── Auth State Stream ──────────────────────────────────────────────────────
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // ─── Sign Up ────────────────────────────────────────────────────────────────
  Future<UserModel> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final credential = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user!;

    // Update display name in Firebase Auth
    await user.updateDisplayName(displayName.trim());

    // Send email verification
    await user.sendEmailVerification();

    // Create user profile in Firestore
    final userModel = UserModel(
      uid: user.uid,
      email: email.trim(),
      displayName: displayName.trim(),
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(userModel.toMap());

    return userModel;
  }

  // ─── Sign In ────────────────────────────────────────────────────────────────
  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user!;

    // Reload to get latest verification status
    await user.reload();
    final refreshed = _auth.currentUser!;

    if (!refreshed.emailVerified) {
      throw FirebaseAuthException(
        code: 'email-not-verified',
        message:
            'Please verify your email before signing in. Check your inbox.',
      );
    }

    // Fetch or create user profile
    final doc = await _firestore.collection('users').doc(refreshed.uid).get();
    if (doc.exists) {
      return UserModel.fromMap(doc.data()!, refreshed.uid);
    }

    // Fallback: create profile if missing
    final userModel = UserModel(
      uid: refreshed.uid,
      email: refreshed.email ?? email.trim(),
      displayName: refreshed.displayName ?? email.split('@').first,
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection('users')
        .doc(refreshed.uid)
        .set(userModel.toMap());

    return userModel;
  }

  // ─── Sign Out ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ─── Resend Verification Email ──────────────────────────────────────────────
  Future<void> resendVerificationEmail() async {
    final user = _auth.currentUser;
    if (user != null && !user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  // ─── Reload Current User ────────────────────────────────────────────────────
  Future<bool> reloadAndCheckVerification() async {
    final user = _auth.currentUser;
    if (user == null) return false;
    await user.reload();
    return _auth.currentUser?.emailVerified ?? false;
  }

  // ─── Fetch User Profile ─────────────────────────────────────────────────────
  Future<UserModel?> fetchUserProfile(String uid) async {
    final doc = await _firestore.collection('users').doc(uid).get();
    if (!doc.exists) return null;
    return UserModel.fromMap(doc.data()!, uid);
  }

  // ─── Password Reset ─────────────────────────────────────────────────────────
  Future<void> sendPasswordResetEmail(String email) async {
    await _auth.sendPasswordResetEmail(email: email.trim());
  }
}
