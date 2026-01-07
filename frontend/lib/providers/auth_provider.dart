import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/web_id_token_provider.dart'
    if (dart.library.io) '../services/web_id_token_provider_stub.dart';

class AuthProvider with ChangeNotifier {
  bool _isAuthenticated = false;
  String? _userName;
  String? _userEmail;
  String? _userPhotoUrl;
  String? _errorMessage;

  // Google Sign-In instance (v6 API)
  // serverClientId is ONLY supported on mobile (Android/iOS), NOT on web
  // For web, ID tokens are handled differently via the meta tag in index.html
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
    // Only set serverClientId on mobile platforms
    serverClientId: kIsWeb
        ? null
        : '508004432990-iremf8omgfljq5kj02ifjimg8k96o79a.apps.googleusercontent.com',
  );

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

  /// Get the Google ID token for backend authentication
  /// Returns null if user is not signed in
  /// Uses platform-specific implementations:
  /// - Web: Google Identity Services (GIS)
  /// - Mobile: google_sign_in package
  Future<String?> getIdToken() async {
    try {
      // On web, use Google Identity Services to get ID token
      if (kIsWeb) {
        return await _getWebIdToken();
      }

      // On mobile, use google_sign_in package
      final currentUser = _googleSignIn.currentUser;
      if (currentUser == null) {
        debugPrint('No user signed in, cannot get ID token');
        return null;
      }

      final auth = await currentUser.authentication;
      final idToken = auth.idToken;

      if (idToken == null) {
        debugPrint('ID token is null, user may need to re-authenticate');
        return null;
      }

      return idToken;
    } catch (e) {
      debugPrint('Error getting ID token: $e');
      return null;
    }
  }

  /// Web-specific ID token retrieval using backend token exchange
  /// Web google_sign_in provides access_token but not ID tokens
  /// So we exchange the access_token via backend for an ID token
  Future<String?> _getWebIdToken() async {
    try {
      // Get current user's access token
      final currentUser = _googleSignIn.currentUser;
      if (currentUser == null) {
        debugPrint('No user signed in on web');
        return null;
      }

      final auth = await currentUser.authentication;
      final accessToken = auth.accessToken;

      if (accessToken == null) {
        debugPrint('No access token available');
        return null;
      }

      // Exchange access_token for ID token via backend
      final idToken = await WebIdTokenProvider.exchangeToken(
        accessToken,
        backendUrl: 'http://localhost:8000', // TODO: Make configurable
      );

      if (idToken != null) {
        debugPrint('Got ID token from backend exchange');
        return idToken;
      }

      debugPrint('Token exchange failed');
      return null;
    } catch (e) {
      debugPrint('Web ID token error: $e');
      return null;
    }
  }
}
