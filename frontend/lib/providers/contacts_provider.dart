import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class ContactsProvider with ChangeNotifier {
  late final ApiService _apiService;
  final AuthProvider _authProvider;

  ContactsProvider(this._authProvider) {
    _apiService = ApiService(
      onAuthenticationExpired: () {
        // Handle authentication expiry
        debugPrint('Authentication expired, signing out user');
        _authProvider.logout();
      },
    );
  }

  List<dynamic> _contacts = [];
  List<dynamic> _contactsNeedingFix = [];
  bool _isLoading = false;
  String? _errorMessage;
  DateTime? _lastSyncTime;
  int _syncedCount = 0;
  String _currentRegion = 'US';

  // Getters
  List<dynamic> get contacts => _contacts;
  List<dynamic> get contactsNeedingFix => _contactsNeedingFix;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DateTime? get lastSyncTime => _lastSyncTime;
  int get syncedCount => _syncedCount;
  int get needsFixCount => _contactsNeedingFix.length;
  String get currentRegion => _currentRegion;

  /// Syncs contacts from Google to local database
  Future<void> syncFromGoogle({String? regionCode}) async {
    _isLoading = true;
    _errorMessage = null;
    if (regionCode != null) _currentRegion = regionCode;
    notifyListeners();

    try {
      final idToken = await _authProvider.getIdToken();
      final result = await _apiService.syncContacts(idToken);
      _syncedCount = result['synced_count'] ?? 0;
      _lastSyncTime = DateTime.now();

      // Automatically load contacts needing fix after sync
      await loadContactsNeedingFix(regionCode: _currentRegion);
    } catch (e) {
      _errorMessage = 'Sync failed: $e';
      debugPrint('Sync error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Loads contacts that need phone number standardization
  /// [regionCode] - ISO country code for default region (e.g., "US", "IN")
  Future<void> loadContactsNeedingFix({String? regionCode}) async {
    if (regionCode != null) _currentRegion = regionCode;

    try {
      final idToken = await _authProvider.getIdToken();
      final result = await _apiService.getMissingExtensionContacts(
        idToken: idToken,
        regionCode: _currentRegion,
      );
      _contactsNeedingFix = result['contacts'] ?? [];
      notifyListeners();
    } catch (e) {
      _errorMessage = 'Failed to load contacts: $e';
      debugPrint('Load contacts error: $e');
      notifyListeners();
    }
  }

  /// Loads all contacts from local database
  Future<void> loadAllContacts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final idToken = await _authProvider.getIdToken();
      _contacts = await _apiService.getContacts(idToken);
    } catch (e) {
      _errorMessage = 'Failed to load contacts: $e';
      debugPrint('Load all contacts error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clears the error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
