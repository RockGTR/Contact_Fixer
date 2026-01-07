import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userName;
  String? _userEmail;
  String? _errorMessage;

  // Google Sign-In instance (v6 API)
  // For Android, the OAuth client is matched by package name + SHA-1
  // No serverClientId needed for basic sign-in
  final GoogleSignIn _googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);

  bool get isAuthenticated => _isAuthenticated;
  String? get userName => _userName;
  String? get userEmail => _userEmail;
  String? get errorMessage => _errorMessage;

  Future<void> initialize() async {
    // Listen for account changes
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount? account) {
      if (account != null) {
        _isAuthenticated = true;
        _userName = account.displayName;
        _userEmail = account.email;
        _errorMessage = null;
      } else {
        _isAuthenticated = false;
        _userName = null;
        _userEmail = null;
      }
      notifyListeners();
    });

    // Try silent sign-in (for returning users)
    try {
      await _googleSignIn.signInSilently();
    } catch (e) {
      debugPrint('Silent sign-in skipped: $e');
    }
  }

  Future<void> login() async {
    try {
      _errorMessage = null;
      notifyListeners();

      final account = await _googleSignIn.signIn();
      if (account == null) {
        _errorMessage = 'Sign-in was cancelled';
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      _errorMessage = 'Sign-in failed: ${e.toString()}';
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _googleSignIn.signOut();
    _isAuthenticated = false;
    _userName = null;
    _userEmail = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
