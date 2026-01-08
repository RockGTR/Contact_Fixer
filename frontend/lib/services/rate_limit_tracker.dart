import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// Optimized rate limit tracker using event-driven timers
///
/// Performance improvements over original:
/// - Uses Queue for O(1) removal from front
/// - Event-driven expiry timer (only fires when requests expire)
/// - Lazy UI refresh timer (only runs when indicator is visible)
/// - Eliminates ~150 timer fires/minute when idle
class RateLimitTracker extends ChangeNotifier {
  static const int maxRequestsPerMinute = 60;
  static const Duration windowDuration = Duration(minutes: 1);

  // Use a Queue for O(1) removal from front (requests are always chronological)
  final Queue<DateTime> _requests = Queue();

  // Event-driven timer that fires exactly when oldest request expires
  Timer? _expiryTimer;

  // UI refresh timer - only active when indicator should be visible
  Timer? _uiRefreshTimer;

  // Track if UI timer is running to avoid redundant starts
  bool _uiTimerActive = false;

  /// Record a new API request (with limit enforcement)
  void recordRequest() {
    // Cleanup any expired requests first
    _cleanupExpired();

    // Don't allow recording if at limit
    if (_requests.length >= maxRequestsPerMinute) {
      debugPrint('⚠️ Rate limit reached - request blocked');
      return;
    }

    _requests.add(DateTime.now());
    _scheduleNextExpiry();
    _updateUiTimer();
    notifyListeners();
  }

  /// Schedule timer for exactly when the oldest request expires
  void _scheduleNextExpiry() {
    _expiryTimer?.cancel();

    if (_requests.isEmpty) return;

    final oldestRequest = _requests.first;
    final expiryTime = oldestRequest.add(windowDuration);
    final delay = expiryTime.difference(DateTime.now());

    if (delay.isNegative || delay == Duration.zero) {
      // Already expired, clean up immediately
      _cleanupExpired();
      // Reschedule for next oldest if any remain
      if (_requests.isNotEmpty) {
        _scheduleNextExpiry();
      }
    } else {
      // Schedule cleanup for exact expiry time (+100ms buffer for precision)
      _expiryTimer = Timer(delay + const Duration(milliseconds: 100), () {
        _cleanupExpired();
        _scheduleNextExpiry(); // Schedule next expiry
        _updateUiTimer();
      });
    }
  }

  /// Start or stop UI refresh timer based on whether indicator should be visible
  void _updateUiTimer() {
    final shouldRun = shouldShowIndicator;

    if (shouldRun && !_uiTimerActive) {
      // Start the UI timer for smooth countdown animations
      _uiRefreshTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
        notifyListeners();
        // Auto-stop when no longer needed
        if (!shouldShowIndicator) {
          _stopUiTimer();
        }
      });
      _uiTimerActive = true;
    } else if (!shouldRun && _uiTimerActive) {
      _stopUiTimer();
    }
  }

  void _stopUiTimer() {
    _uiRefreshTimer?.cancel();
    _uiRefreshTimer = null;
    _uiTimerActive = false;
  }

  /// Remove only expired requests from front of queue - O(k) where k = expired count
  void _cleanupExpired() {
    final cutoff = DateTime.now().subtract(windowDuration);
    int freed = 0;

    // O(k) where k = number of expired items (usually 1-2 at a time)
    while (_requests.isNotEmpty && _requests.first.isBefore(cutoff)) {
      _requests.removeFirst();
      freed++;
    }

    if (freed > 0) {
      debugPrint('✅ Rate limit cleanup: $freed edits freed');
      notifyListeners();
    }
  }

  /// Get number of requests in the current window
  int get requestCount => _requests.length.clamp(0, maxRequestsPerMinute);

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
      return '$expiringCount edit${expiringCount > 1 ? 's' : ''} free in ${seconds}s';
    }

    return 'Next edit in ${seconds}s';
  }

  /// Get human-readable status
  String get statusText {
    if (isAtLimit) {
      return 'At limit! ($requestCount/$maxRequestsPerMinute)';
    } else if (isApproachingLimit) {
      return '$remainingRequests edits remaining';
    } else {
      return '$requestCount/$maxRequestsPerMinute used';
    }
  }

  /// Reset the tracker (for testing)
  void reset() {
    _requests.clear();
    _expiryTimer?.cancel();
    _expiryTimer = null;
    _stopUiTimer();
    notifyListeners();
  }

  @override
  void dispose() {
    _expiryTimer?.cancel();
    _stopUiTimer();
    super.dispose();
  }
}
