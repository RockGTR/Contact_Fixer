import 'dart:async';
import 'package:flutter/foundation.dart';

/// Tracks API request rate to prevent hitting rate limits
/// Limit: 100 requests per minute
class RateLimitTracker extends ChangeNotifier {
  static const int maxRequestsPerMinute = 100;
  static const Duration windowDuration = Duration(minutes: 1);

  final List<DateTime> _requests = [];
  Timer? _cleanupTimer;

  RateLimitTracker() {
    // Start periodic cleanup of old requests
    _cleanupTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _cleanupOldRequests();
    });
  }

  /// Record a new API request
  void recordRequest() {
    _requests.add(DateTime.now());
    _cleanupOldRequests();
    notifyListeners();
  }

  /// Get number of requests in the current window
  int get requestCount {
    _cleanupOldRequests();
    return _requests.length;
  }

  /// Get percentage of rate limit used (0.0 to 1.0)
  double get usagePercentage {
    return requestCount / maxRequestsPerMinute;
  }

  /// Check if we're approaching the rate limit (>80%)
  bool get isApproachingLimit {
    return usagePercentage > 0.8;
  }

  /// Check if we've hit the rate limit
  bool get isAtLimit {
    return requestCount >= maxRequestsPerMinute;
  }

  /// Get remaining requests before hitting limit
  int get remainingRequests {
    return maxRequestsPerMinute - requestCount;
  }

  /// Get human-readable status
  String get statusText {
    if (isAtLimit) {
      return 'Rate limit reached! Wait 60s';
    } else if (isApproachingLimit) {
      return '$remainingRequests requests remaining';
    } else {
      return '$requestCount / $maxRequestsPerMinute requests';
    }
  }

  /// Remove requests older than 1 minute
  void _cleanupOldRequests() {
    final cutoff = DateTime.now().subtract(windowDuration);
    _requests.removeWhere((time) => time.isBefore(cutoff));
  }

  /// Reset the tracker (for testing)
  void reset() {
    _requests.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    super.dispose();
  }
}
