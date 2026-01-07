import 'package:flutter/material.dart';

/// Data class for country information
class Country {
  final String code; // ISO 3166-1 alpha-2 code (e.g., "US")
  final String name; // Full name (e.g., "United States")
  final String dialCode; // Phone prefix (e.g., "+1")
  final String flag; // Emoji flag (e.g., "🇺🇸")

  const Country({
    required this.code,
    required this.name,
    required this.dialCode,
    required this.flag,
  });
}

/// List of commonly used countries for phone number formatting
const List<Country> supportedCountries = [
  Country(code: 'US', name: 'United States', dialCode: '+1', flag: '🇺🇸'),
  Country(code: 'IN', name: 'India', dialCode: '+91', flag: '🇮🇳'),
  Country(code: 'GB', name: 'United Kingdom', dialCode: '+44', flag: '🇬🇧'),
  Country(code: 'CA', name: 'Canada', dialCode: '+1', flag: '🇨🇦'),
  Country(code: 'AU', name: 'Australia', dialCode: '+61', flag: '🇦🇺'),
  Country(code: 'DE', name: 'Germany', dialCode: '+49', flag: '🇩🇪'),
  Country(code: 'FR', name: 'France', dialCode: '+33', flag: '🇫🇷'),
  Country(code: 'IT', name: 'Italy', dialCode: '+39', flag: '🇮🇹'),
  Country(code: 'ES', name: 'Spain', dialCode: '+34', flag: '🇪🇸'),
  Country(code: 'BR', name: 'Brazil', dialCode: '+55', flag: '🇧🇷'),
  Country(code: 'MX', name: 'Mexico', dialCode: '+52', flag: '🇲🇽'),
  Country(code: 'JP', name: 'Japan', dialCode: '+81', flag: '🇯🇵'),
  Country(code: 'CN', name: 'China', dialCode: '+86', flag: '🇨🇳'),
  Country(code: 'KR', name: 'South Korea', dialCode: '+82', flag: '🇰🇷'),
  Country(code: 'RU', name: 'Russia', dialCode: '+7', flag: '🇷🇺'),
  Country(code: 'ZA', name: 'South Africa', dialCode: '+27', flag: '🇿🇦'),
  Country(code: 'AE', name: 'UAE', dialCode: '+971', flag: '🇦🇪'),
  Country(code: 'SG', name: 'Singapore', dialCode: '+65', flag: '🇸🇬'),
  Country(code: 'NZ', name: 'New Zealand', dialCode: '+64', flag: '🇳🇿'),
  Country(code: 'PH', name: 'Philippines', dialCode: '+63', flag: '🇵🇭'),
  Country(code: 'ID', name: 'Indonesia', dialCode: '+62', flag: '🇮🇩'),
  Country(code: 'MY', name: 'Malaysia', dialCode: '+60', flag: '🇲🇾'),
  Country(code: 'TH', name: 'Thailand', dialCode: '+66', flag: '🇹🇭'),
  Country(code: 'VN', name: 'Vietnam', dialCode: '+84', flag: '🇻🇳'),
  Country(code: 'PK', name: 'Pakistan', dialCode: '+92', flag: '🇵🇰'),
  Country(code: 'BD', name: 'Bangladesh', dialCode: '+880', flag: '🇧🇩'),
  Country(code: 'NG', name: 'Nigeria', dialCode: '+234', flag: '🇳🇬'),
  Country(code: 'EG', name: 'Egypt', dialCode: '+20', flag: '🇪🇬'),
  Country(code: 'SA', name: 'Saudi Arabia', dialCode: '+966', flag: '🇸🇦'),
  Country(code: 'IL', name: 'Israel', dialCode: '+972', flag: '🇮🇱'),
];

/// Get a country by its ISO code
Country? getCountryByCode(String code) {
  try {
    return supportedCountries.firstWhere(
      (c) => c.code.toUpperCase() == code.toUpperCase(),
    );
  } catch (_) {
    return null;
  }
}
