// Simplified web ID token provider using backend token exchange.
// Instead of complex GIS integration, uses access_token exchange.
import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, debugPrint;
import 'package:http/http.dart' as http;

class WebIdTokenProvider {
  static String? _cachedIdToken;
  static String? _cachedEmail;

  /// Exchange web access_token for an ID token via backend
  static Future<String?> exchangeToken(
    String accessToken, {
    required String backendUrl,
  }) async {
    if (!kIsWeb) return null;

    // If we have a cached token, return it
    if (_cachedIdToken != null) {
      return _cachedIdToken;
    }

    try {
      final url = Uri.parse('$backendUrl/auth/exchange_token');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'access_token': accessToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _cachedIdToken = data['id_token'] as String?;
        _cachedEmail = data['email'] as String?;

        debugPrint('WebIdTokenProvider: Exchanged token for $_cachedEmail');
        return _cachedIdToken;
      } else {
        debugPrint(
          'WebIdTokenProvider: Token exchange failed: ${response.statusCode}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('WebIdTokenProvider error: $e');
      return null;
    }
  }

  /// Clear cached token (on logout)
  static void clearToken() {
    _cachedIdToken = null;
    _cachedEmail = null;
  }
}
