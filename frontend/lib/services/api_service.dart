import 'dart:convert';
import 'package:http/http.dart' as http;

class ApiService {
  // Use 10.0.2.2 for Android emulator to reach host machine's localhost
  // For physical device, use your computer's IP address
  static const String _baseUrl = 'http://10.0.2.2:8000';

  /// Syncs contacts from Google to the local database.
  Future<Map<String, dynamic>> syncContacts() async {
    final response = await http.post(Uri.parse('$_baseUrl/contacts/sync'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to sync contacts: ${response.statusCode}');
    }
  }

  /// Gets all contacts from the local database.
  Future<List<dynamic>> getContacts() async {
    final response = await http.get(Uri.parse('$_baseUrl/contacts/'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch contacts: ${response.statusCode}');
    }
  }

  /// Gets contacts that need phone number standardization (excluding staged).
  Future<Map<String, dynamic>> getMissingExtensionContacts({
    String regionCode = 'US',
  }) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/contacts/missing_extension?region=$regionCode'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to fetch contacts: ${response.statusCode}');
    }
  }

  /// Checks the backend authentication status.
  Future<Map<String, dynamic>> getAuthStatus() async {
    final response = await http.get(Uri.parse('$_baseUrl/auth/status'));

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to check auth status: ${response.statusCode}');
    }
  }

  /// Analyzes contacts across multiple regions and returns counts.
  Future<Map<String, dynamic>> analyzeRegions() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/contacts/analyze_regions'),
    );

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
    required String resourceName,
    required String contactName,
    required String originalPhone,
    required String newPhone,
    required String action,
    String? newName,
  }) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/contacts/stage_fix'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'resource_name': resourceName,
        'contact_name': contactName,
        'original_phone': originalPhone,
        'new_phone': newPhone,
        'action': action,
        'new_name': newName,
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to stage fix: ${response.statusCode}');
    }
  }

  /// Get all pending staged changes.
  Future<Map<String, dynamic>> getPendingChanges() async {
    final response = await http.get(
      Uri.parse('$_baseUrl/contacts/pending_changes'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get pending changes: ${response.statusCode}');
    }
  }

  /// Remove a specific staged change.
  Future<void> removeStagedChange(String resourceName) async {
    final encodedName = Uri.encodeQueryComponent(resourceName);
    final response = await http.delete(
      Uri.parse('$_baseUrl/contacts/staged/remove?resource_name=$encodedName'),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove staged: ${response.statusCode}');
    }
  }

  /// Clear all staged changes.
  Future<void> clearStaged() async {
    final response = await http.delete(Uri.parse('$_baseUrl/contacts/staged'));

    if (response.statusCode != 200) {
      throw Exception('Failed to clear staged: ${response.statusCode}');
    }
  }

  /// Push all staged changes to Google Contacts.
  Future<Map<String, dynamic>> pushToGoogle() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/contacts/push_to_google'),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to push to Google: ${response.statusCode}');
    }
  }
}
