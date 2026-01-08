import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/rate_limit_tracker.dart';

/// Animated rate limit indicator showing proximity to 100 req/min limit
class RateLimitIndicator extends StatelessWidget {
  const RateLimitIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RateLimitTracker>(
      builder: (context, tracker, _) {
        final percentage = tracker.usagePercentage;
        final isWarning = tracker.isApproachingLimit;
        final isLimit = tracker.isAtLimit;

        // Color based on usage
        Color color;
        IconData icon;

        if (isLimit) {
          color = Colors.red;
          icon = Icons.error;
        } else if (isWarning) {
          color = Colors.orange;
          icon = Icons.warning_amber;
        } else {
          color = Colors.green;
          icon = Icons.check_circle;
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with icon and status
              Row(
                children: [
                  Icon(icon, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      tracker.statusText,
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  Text(
                    '${(percentage * 100).toInt()}%',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Animated progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeOut,
                  tween: Tween(begin: 0.0, end: percentage),
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 6,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    );
                  },
                ),
              ),

              // Help text
              if (isLimit || isWarning) ...[
                const SizedBox(height: 6),
                Text(
                  isLimit
                      ? 'Please wait a minute before making more requests'
                      : 'Approaching rate limit - slow down to avoid errors',
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 11),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}

/// Compact rate limit badge for app bar
class RateLimitBadge extends StatelessWidget {
  const RateLimitBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RateLimitTracker>(
      builder: (context, tracker, _) {
        final isWarning = tracker.isApproachingLimit;
        final isLimit = tracker.isAtLimit;

        // Only show if approaching or at limit
        if (!isWarning && !isLimit) {
          return const SizedBox.shrink();
        }

        Color color = isLimit ? Colors.red : Colors.orange;

        return Container(
          margin: const EdgeInsets.only(right: 8),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isLimit ? Icons.error : Icons.warning_amber,
                color: color,
                size: 16,
              ),
              const SizedBox(width: 4),
              Text(
                '${tracker.remainingRequests}',
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
