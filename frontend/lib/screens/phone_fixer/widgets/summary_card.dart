import 'package:flutter/material.dart';
import '../../../widgets/neumorphic_container.dart';

/// Summary card showing counts of accepts, rejects, and edits.
class SummaryCard extends StatelessWidget {
  final int accepts;
  final int rejects;
  final int edits;

  const SummaryCard({
    super.key,
    required this.accepts,
    required this.rejects,
    required this.edits,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: NeumorphicContainer(
        padding: const EdgeInsets.all(24),
        borderRadius: BorderRadius.circular(32),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _SummaryItem(
              label: 'Accepts',
              count: accepts,
              color: const Color(0xFF10b981),
            ),
            _SummaryItem(
              label: 'Skipped',
              count: rejects,
              color: const Color(0xFFef4444),
            ),
            _SummaryItem(
              label: 'Edits',
              count: edits,
              color: const Color(0xFF667eea),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryItem extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _SummaryItem({
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
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(label, style: TextStyle(color: Colors.grey.shade600)),
      ],
    );
  }
}
