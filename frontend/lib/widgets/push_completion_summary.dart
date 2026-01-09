import 'package:flutter/material.dart';
import 'neumorphic_button.dart';

/// Completion summary showing synced/failed/skipped counts
class PushCompletionSummary extends StatelessWidget {
  final int pushed;
  final int failed;
  final int skipped;
  final VoidCallback onDone;

  const PushCompletionSummary({
    super.key,
    required this.pushed,
    required this.failed,
    required this.skipped,
    required this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 8),
        // Stats row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _StatItem(
              label: '✓ Synced',
              count: pushed,
              color: const Color(0xFF10b981),
            ),
            _StatItem(
              label: '✗ Failed',
              count: failed,
              color: const Color(0xFFef4444),
            ),
            _StatItem(
              label: '○ Skipped',
              count: skipped,
              color: const Color(0xFF9CA3AF),
            ),
          ],
        ),
        const SizedBox(height: 24),
        // Done button
        NeumorphicButton(
          onTap: onDone,
          height: 48,
          color: const Color(0xFF10b981),
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: const Text(
            'Done',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatItem({
    required this.label,
    required this.count,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }
}
