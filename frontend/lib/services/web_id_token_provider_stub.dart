// Stub implementation for non-web platforms (Android/iOS/Desktop).
// This file is used when dart.library.io is available, effectively replacing
// the web implementation to avoid compilation errors on non-web platforms.

class WebIdTokenProvider {
  /// Stub for token exchange - should never be called on mobile/desktop
  /// as auth_provider.dart guards calls with kIsWeb check.
  static Future<String?> exchangeToken(
    String accessToken, {
    required String backendUrl,
  }) async {
    throw UnimplementedError(
      'WebIdTokenProvider is not supported on this platform',
    );
  }

  /// Stub for clearing token
  static void clearToken() {
    // No-op on non-web platforms
  }
}
