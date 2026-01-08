import 'dart:async';
import 'package:flutter/foundation.dart';

/// Tracks API request rate to prevent hitting rate limits
/// Limit: 100 requests per minute (rolling window)
class RateLimitTracker extends ChangeNotifier {
  static const int maxRequestsPerMinute = 100;
  static const Duration windowDuration = Duration(minutes: 1);

  final List<DateTime> _requests = [];
  Timer? _cleanupTimer;
  Timer? _refreshTimer;

  RateLimitTracker() {
    // Start periodic cleanup of old requests
    _cleanupTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _cleanupOldRequests();
    });

    // Update UI every second to show countdown
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      notifyListeners();
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

  /// Check if we should show the indicator (>75%)
  bool get shouldShowIndicator {
    return usagePercentage > 0.75;
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

  /// Get time until oldest request expires (quota frees up)
  Duration? get timeUntilRefresh {
    if (_requests.isEmpty) return null;

    final oldestRequest = _requests.first;
    final expiryTime = oldestRequest.add(windowDuration);
    final now = DateTime.now();

    if (expiryTime.isAfter(now)) {
      return expiryTime.difference(now);
    }
    return null;
  }

  /// Get human-readable time until refresh
  String get refreshCountdown {
    final duration = timeUntilRefresh;
    if (duration == null) return '';

    final seconds = duration.inSeconds;
    if (seconds <= 0) return 'Refreshing...';

    return '${seconds}s until quota refresh';
  }

  /// Get human-readable status
  String get statusText {
    if (isAtLimit) {
      return 'Rate limit reached!';
    } else if (isApproachingLimit) {
      return '$remainingRequests requests remaining';
    } else {
      return '$requestCount / $maxRequestsPerMinute requests used';
    }
  }

  /// Remove requests older than 1 minute
  void _cleanupOldRequests() {
    final cutoff = DateTime.now().subtract(windowDuration);
    final oldCount = _requests.length;
    _requests.removeWhere((time) => time.isBefore(cutoff));

    // Notify if requests were cleaned up (quota freed)
    if (_requests.length < oldCount) {
      notifyListeners();
    }
  }

  /// Reset the tracker (for testing)
  void reset() {
    _requests.clear();
    notifyListeners();
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    _refreshTimer?.cancel();
    super.dispose();
  }
}
