import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/rate_limit_tracker.dart';

/// Animated rate limit indicator showing proximity to 100 req/min limit
/// Only appears after 75% usage
class RateLimitIndicator extends StatelessWidget {
  const RateLimitIndicator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RateLimitTracker>(
      builder: (context, tracker, _) {
        // Only show after 75% usage
        if (!tracker.shouldShowIndicator) {
          return const SizedBox.shrink();
        }

        final percentage = tracker.usagePercentage;
        final isWarning = tracker.isApproachingLimit;
        final isLimit = tracker.isAtLimit;
        final countdown = tracker.refreshCountdown;

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
          color = Colors.amber;
          icon = Icons.info;
        }

        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
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
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tracker.statusText,
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                        if (countdown.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                size: 12,
                                color: color.withOpacity(0.7),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                countdown,
                                style: TextStyle(
                                  color: color.withOpacity(0.9),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${(percentage * 100).toInt()}%',
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                      if (tracker.remainingRequests >= 0) ...[
                        Text(
                          '${tracker.remainingRequests} left',
                          style: TextStyle(
                            color: color.withOpacity(0.7),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Animated progress bar with gradient
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: TweenAnimationBuilder<double>(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  tween: Tween(begin: 0.0, end: percentage),
                  builder: (context, value, child) {
                    return Stack(
                      children: [
                        // Background
                        Container(
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        // Animated progress with pulse effect when near limit
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          height: 8,
                          width: MediaQuery.of(context).size.width * value,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isLimit
                                  ? [Colors.red.shade700, Colors.red]
                                  : isWarning
                                  ? [Colors.orange.shade700, Colors.orange]
                                  : [Colors.amber.shade700, Colors.amber],
                            ),
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: isLimit || isWarning
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ]
                                : null,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // Help text with dynamic info
              if (isLimit || isWarning) ...[
                const SizedBox(height: 8),
                Text(
                  isLimit
                      ? 'At capacity - requests will auto-resume as edits free up'
                      : 'High usage - quota refreshes on a rolling 60-second window',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                  ),
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
/// Only shows when approaching or at limit (>75%)
class RateLimitBadge extends StatelessWidget {
  const RateLimitBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<RateLimitTracker>(
      builder: (context, tracker, _) {
        // Only show after 75% usage
        if (!tracker.shouldShowIndicator) {
          return const SizedBox.shrink();
        }

        final isWarning = tracker.isApproachingLimit;
        final isLimit = tracker.isAtLimit;

        Color color = isLimit
            ? Colors.red
            : (isWarning ? Colors.orange : Colors.amber);

        return AnimatedOpacity(
          duration: const Duration(milliseconds: 300),
          opacity: 1.0,
          child: Container(
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
          ),
        );
      },
    );
  }
}
