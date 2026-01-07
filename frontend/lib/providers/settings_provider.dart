import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../models/country.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class SettingsProvider with ChangeNotifier {
  final AuthProvider _authProvider;
  late final ApiService _api;

  SettingsProvider(this._authProvider) {
    _api = ApiService(onAuthenticationExpired: () => _authProvider.logout());
  }

  Country _defaultRegion = supportedCountries.firstWhere((c) => c.code == 'US');
  Country? _suggestedRegion;
  int _suggestedRegionCount = 0;
  int _currentRegionCount = 0;
  bool _initialized = false;

  Country get defaultRegion => _defaultRegion;
  Country? get suggestedRegion => _suggestedRegion;
  int get suggestedRegionCount => _suggestedRegionCount;
  int get currentRegionCount => _currentRegionCount;
  bool get hasBetterSuggestion =>
      _suggestedRegion != null && _suggestedRegionCount > _currentRegionCount;

  /// Initialize settings by detecting device locale
  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;

    // Get device locale - platform-aware
    String? deviceLocale;
    String countryCode = 'US'; // Default fallback

    try {
      if (kIsWeb) {
        // On web, try to get locale from browser
        // For now, we'll skip and just use US as default
        // The region suggestion will still work via _analyzeRegions()
        debugPrint('Running on web - using default region US');
      } else {
        // On mobile, use Platform.localeName
        deviceLocale = Platform.localeName;
        debugPrint('Device locale: $deviceLocale');
      }

      // Extract country code from locale (e.g., "en_US" -> "US")
      if (deviceLocale != null) {
        if (deviceLocale.contains('_')) {
          countryCode = deviceLocale.split('_').last.toUpperCase();
        } else if (deviceLocale.length == 2) {
          countryCode = deviceLocale.toUpperCase();
        }
      }
    } catch (e) {
      debugPrint('Error getting locale: $e - using default US');
    }

    // Find matching country
    final country = getCountryByCode(countryCode);
    if (country != null) {
      _defaultRegion = country;
    }

    debugPrint('Selected country: ${_defaultRegion.code}');
    notifyListeners();

    // Analyze regions to find best suggestion
    await _analyzeRegions();
  }

  /// Analyze regions and suggest better option if available
  Future<void> _analyzeRegions() async {
    try {
      final idToken = await _authProvider.getIdToken();
      final result = await _api.analyzeRegions(idToken);
      final regions = result['regions'] as List<dynamic>?;

      if (regions == null || regions.isEmpty) return;

      // Find current region's count
      for (final r in regions) {
        if (r['region'] == _defaultRegion.code) {
          _currentRegionCount = r['count'] as int;
          break;
        }
      }

      // Find top region
      final topRegion = regions.first;
      final topRegionCode = topRegion['region'] as String;
      final topRegionCount = topRegion['count'] as int;

      // If top region is different and has more contacts, suggest it
      if (topRegionCode != _defaultRegion.code &&
          topRegionCount > _currentRegionCount) {
        final suggested = getCountryByCode(topRegionCode);
        if (suggested != null) {
          _suggestedRegion = suggested;
          _suggestedRegionCount = topRegionCount;
          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('Failed to analyze regions: $e');
    }
  }

  /// Set the default region
  void setDefaultRegion(Country country) {
    _defaultRegion = country;
    _suggestedRegion = null; // Clear suggestion when user picks
    notifyListeners();

    // Re-analyze to update counts
    _analyzeRegions();
  }

  /// Accept the suggested region
  void acceptSuggestion() {
    if (_suggestedRegion != null) {
      _defaultRegion = _suggestedRegion!;
      _currentRegionCount = _suggestedRegionCount;
      _suggestedRegion = null;
      notifyListeners();
    }
  }

  /// Dismiss the suggestion
  void dismissSuggestion() {
    _suggestedRegion = null;
    notifyListeners();
  }
}
