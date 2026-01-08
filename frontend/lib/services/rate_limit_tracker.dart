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
    // Cleanup old requests every 2 seconds for smoother countdown
    _cleanupTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      _cleanupOldRequests();
    });

    // Update UI every 500ms for smooth countdown animation
    _refreshTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      notifyListeners();
    });
  }

  /// Record a new API request (with limit enforcement)
  void recordRequest() {
    _cleanupOldRequests();

    // Don't allow recording if at limit
    if (_requests.length >= maxRequestsPerMinute) {
      debugPrint('⚠️ Rate limit reached - request blocked');
      return;
    }

    _requests.add(DateTime.now());
    notifyListeners();
  }

  /// Get number of requests in the current window
  int get requestCount {
    _cleanupOldRequests();
    return _requests.length.clamp(0, maxRequestsPerMinute);
  }

  /// Get percentage of rate limit used (0.0 to 1.0, capped at 1.0)
  double get usagePercentage {
    return (requestCount / maxRequestsPerMinute).clamp(0.0, 1.0);
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

  /// Get remaining requests before hitting limit (never negative)
  int get remainingRequests {
    return (maxRequestsPerMinute - requestCount).clamp(0, maxRequestsPerMinute);
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

  /// Get number of requests that will expire in the next 10 seconds
  int get requestsExpiringNext10s {
    if (_requests.isEmpty) return 0;

    final now = DateTime.now();
    final next10s = now.add(const Duration(seconds: 10));

    return _requests.where((time) {
      final expiryTime = time.add(windowDuration);
      return expiryTime.isBefore(next10s) && expiryTime.isAfter(now);
    }).length;
  }

  /// Get human-readable time until refresh with dynamic countdown
  String get refreshCountdown {
    final duration = timeUntilRefresh;
    if (duration == null) return '';

    final seconds = duration.inSeconds;
    if (seconds <= 0) {
      return 'Freeing quota...';
    }

    final expiringCount = requestsExpiringNext10s;
    if (expiringCount > 0 && seconds <= 10) {
      return '${expiringCount} slot${expiringCount > 1 ? 's' : ''} free in ${seconds}s';
    }

    return 'Next slot in ${seconds}s';
  }

  /// Get human-readable status
  String get statusText {
    if (isAtLimit) {
      return 'At limit! ($requestCount/$maxRequestsPerMinute)';
    } else if (isApproachingLimit) {
      return '$remainingRequests slots remaining';
    } else {
      return '$requestCount/$maxRequestsPerMinute used';
    }
  }

  /// Remove requests older than 1 minute
  void _cleanupOldRequests() {
    final cutoff = DateTime.now().subtract(windowDuration);
    final oldCount = _requests.length;
    _requests.removeWhere((time) => time.isBefore(cutoff));

    // Notify if requests were cleaned up (quota freed)
    if (_requests.length < oldCount) {
      debugPrint(
        '✅ Rate limit cleanup: ${oldCount - _requests.length} slots freed',
      );
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
