import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;

class ApiService {
  // Callback for when authentication expires (401 error)
  final Function()? onAuthenticationExpired;

  ApiService({this.onAuthenticationExpired});

  // Use localhost for web, 10.0.2.2 for Android emulator
  // For physical device, use your computer's IP address
  static String get _baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    } else {
      return 'http://10.0.2.2:8000';
    }
  }

  /// Get authentication headers with Google ID token
  Future<Map<String, String>> _getHeaders(String? idToken) async {
    final headers = <String, String>{'Content-Type': 'application/json'};

    if (idToken != null) {
      headers['Authorization'] = 'Bearer $idToken';
    }

    return headers;
  }

  /// Handle HTTP response and check for authentication errors
  void _handleResponse(http.Response response) {
    if (response.statusCode == 401) {
      // Token expired or invalid
      if (onAuthenticationExpired != null) {
        onAuthenticationExpired!();
      }
      throw Exception('Authentication expired. Please sign in again.');
    }
  }

  /// Syncs contacts from Google to the local database.
  Future<Map<String, dynamic>> syncContacts(String? idToken) async {
    final headers = await _getHeaders(idToken);
    final response = await http.post(
      Uri.parse('$_baseUrl/contacts/sync'),
      headers: headers,
    );

    _handleResponse(response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to sync contacts: ${response.statusCode}');
    }
  }

  /// Gets all contacts from the local database.
  Future<List<dynamic>> getContacts(String? idToken) async {
    final headers = await _getHeaders(idToken);
    final response = await http.get(
      Uri.parse('$_baseUrl/contacts/'),
      headers: headers,
    );

    _handleResponse(response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch contacts: ${response.statusCode}');
    }
  }

  /// Gets contacts that need phone number standardization (excluding staged).
  Future<Map<String, dynamic>> getMissingExtensionContacts({
    required String? idToken,
    String regionCode = 'US',
  }) async {
    final headers = await _getHeaders(idToken);
    final response = await http.get(
      Uri.parse('$_baseUrl/contacts/missing_extension?region=$regionCode'),
      headers: headers,
    );

    _handleResponse(response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch contacts: ${response.statusCode}');
    }
  }

  /// Checks the backend authentication status (public endpoint).
  Future<Map<String, dynamic>> getAuthStatus() async {
    final response = await http.get(Uri.parse('$_baseUrl/auth/status'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to check auth status: ${response.statusCode}');
    }
  }

  /// Analyzes contacts across multiple regions and returns counts.
  Future<Map<String, dynamic>> analyzeRegions(String? idToken) async {
    final headers = await _getHeaders(idToken);
    final response = await http.get(
      Uri.parse('$_baseUrl/contacts/analyze_regions'),
      headers: headers,
    );

    _handleResponse(response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to analyze regions: ${response.statusCode}');
    }
  }

  // ============= STAGING API METHODS =============

  /// Stage a contact fix for later pushing to Google.
  /// [action] should be 'accept', 'reject', or 'edit'
  Future<Map<String, dynamic>> stageFix({
    required String? idToken,
    required String resourceName,
    required String contactName,
    required String originalPhone,
    required String newPhone,
    required String action,
    String? newName,
  }) async {
    final headers = await _getHeaders(idToken);
    final response = await http.post(
      Uri.parse('$_baseUrl/contacts/stage_fix'),
      headers: headers,
      body: jsonEncode({
        'resource_name': resourceName,
        'contact_name': contactName,
        'original_phone': originalPhone,
        'new_phone': newPhone,
        'action': action,
        'new_name': newName,
      }),
    );

    _handleResponse(response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to stage fix: ${response.statusCode}');
    }
  }

  /// Get all pending staged changes.
  Future<Map<String, dynamic>> getPendingChanges(String? idToken) async {
    final headers = await _getHeaders(idToken);
    final response = await http.get(
      Uri.parse('$_baseUrl/contacts/pending_changes'),
      headers: headers,
    );

    _handleResponse(response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get pending changes: ${response.statusCode}');
    }
  }

  /// Remove a specific staged change.
  Future<void> removeStagedChange(String? idToken, String resourceName) async {
    final headers = await _getHeaders(idToken);
    final encodedName = Uri.encodeQueryComponent(resourceName);
    final response = await http.delete(
      Uri.parse('$_baseUrl/contacts/staged/remove?resource_name=$encodedName'),
      headers: headers,
    );

    _handleResponse(response);

    if (response.statusCode != 200) {
      throw Exception('Failed to remove staged: ${response.statusCode}');
    }
  }

  /// Clear all staged changes.
  Future<void> clearStaged(String? idToken) async {
    final headers = await _getHeaders(idToken);
    final response = await http.delete(
      Uri.parse('$_baseUrl/contacts/staged'),
      headers: headers,
    );

    _handleResponse(response);

    if (response.statusCode != 200) {
      throw Exception('Failed to clear staged: ${response.statusCode}');
    }
  }

  /// Push all staged changes to Google Contacts.
  Future<Map<String, dynamic>> pushToGoogle(String? idToken) async {
    final headers = await _getHeaders(idToken);
    final response = await http.post(
      Uri.parse('$_baseUrl/contacts/push_to_google'),
      headers: headers,
    );

    _handleResponse(response);

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to push to Google: ${response.statusCode}');
    }
  }
}
