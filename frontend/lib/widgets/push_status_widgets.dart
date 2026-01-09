import 'package:flutter/material.dart';

/// Status indicator widget showing current sync status
class PushStatusIndicator extends StatelessWidget {
  final String status;
  final bool isBackingOff;

  const PushStatusIndicator({
    super.key,
    required this.status,
    this.isBackingOff = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE0E5EC),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isBackingOff)
            const Icon(
              Icons.hourglass_top_rounded,
              size: 16,
              color: Color(0xFFf59e0b),
            )
          else
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF10b981),
              ),
            ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              status,
              style: const TextStyle(fontSize: 13, color: Color(0xFF6B7280)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// Estimated time remaining display
class EstimatedTimeDisplay extends StatelessWidget {
  final int current;
  final int total;

  const EstimatedTimeDisplay({
    super.key,
    required this.current,
    required this.total,
  });

  String get _estimatedTime {
    if (total == 0 || current == 0) return '--:--';
    final remaining = total - current;
    final minutes = remaining ~/ 60;
    final seconds = remaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.timer_outlined, size: 16, color: Color(0xFF9CA3AF)),
        const SizedBox(width: 6),
        Text(
          'Est. $_estimatedTime remaining',
          style: const TextStyle(fontSize: 12, color: Color(0xFF9CA3AF)),
        ),
      ],
    );
  }
}
