import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

enum AuthStatus {
  unknown,
  unauthenticated,
  authenticated,
}

class AuthProvider extends ChangeNotifier {
  final AuthService _authService;

  AuthStatus _status = AuthStatus.unknown;
  UserModel? _userModel;
  String? _errorMessage;
  bool _isLoading = false;

  AuthProvider(this._authService) {
    _init();
  }

  AuthStatus get status => _status;
  UserModel? get userModel => _userModel;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  // ─── Init: Listen to Auth State ─────────────────────────────────────────────
  void _init() {
    _authService.authStateChanges.listen((User? user) async {
      if (user == null) {
        _status = AuthStatus.unauthenticated;
        _userModel = null;
      } else {
        try {
          _userModel = await _authService.fetchUserProfile(user.uid);
        } catch (e) {
          debugPrint('Failed to fetch user profile: $e');
        }
        _userModel ??= UserModel(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? '',
          createdAt: DateTime.now(),
        );
        _status = AuthStatus.authenticated;
      }
      notifyListeners();
    });
  }

  // ─── Sign Up ────────────────────────────────────────────────────────────────
  Future<bool> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.signUp(
        email: email,
        password: password,
        displayName: displayName,
      );
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseException catch (e) {
      _setError(_authErrorMessage(e.code));
      return false;
    } catch (e) {
      debugPrint('Sign-up error: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Sign In ────────────────────────────────────────────────────────────────
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    _setLoading(true);
    _clearError();
    try {
      _userModel = await _authService.signIn(email: email, password: password);
      _status = AuthStatus.authenticated;
      notifyListeners();
      return true;
    } on FirebaseException catch (e) {
      _setError(_authErrorMessage(e.code));
      return false;
    } catch (e) {
      debugPrint('Sign-in error: $e');
      _setError(e.toString());
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Sign Out ───────────────────────────────────────────────────────────────
  Future<void> signOut() async {
    _setLoading(true);
    try {
      await _authService.signOut();
      _status = AuthStatus.unauthenticated;
      _userModel = null;
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ─── Resend Verification ────────────────────────────────────────────────────
  Future<bool> resendVerificationEmail() async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.resendVerificationEmail();
      return true;
    } catch (e) {
      _setError('Failed to resend verification email. Try again later.');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Check Verification ─────────────────────────────────────────────────────
  Future<bool> checkEmailVerification() async {
    _setLoading(true);
    try {
      final verified = await _authService.reloadAndCheckVerification();
      if (verified) {
        final user = FirebaseAuth.instance.currentUser!;
        _userModel = await _authService.fetchUserProfile(user.uid);
        _status = AuthStatus.authenticated;
        notifyListeners();
      }
      return verified;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Password Reset ─────────────────────────────────────────────────────────
  Future<bool> sendPasswordReset(String email) async {
    _setLoading(true);
    _clearError();
    try {
      await _authService.sendPasswordResetEmail(email);
      return true;
    } on FirebaseException catch (e) {
      _setError(_authErrorMessage(e.code));
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────
  void _setLoading(bool val) {
    _isLoading = val;
    notifyListeners();
  }

  void _setError(String msg) {
    _errorMessage = msg;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() => _clearError();

  String _authErrorMessage(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Try signing in.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment.';
      case 'email-not-verified':
        return 'Please verify your email before signing in.';
      case 'network-request-failed':
        return 'Network error. Check your connection.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
