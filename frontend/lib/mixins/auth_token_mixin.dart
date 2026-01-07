import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../providers/auth_provider.dart';

/// Helper mixin to get ID token from AuthProvider
/// Use this in screens/widgets that need to make API calls directly
mixin AuthTokenMixin {
  Future<String?> getIdToken(BuildContext context) async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return await authProvider.getIdToken();
  }

  ApiService createApiService(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    return ApiService(
      onAuthenticationExpired: () {
        authProvider.logout();
      },
    );
  }
}
