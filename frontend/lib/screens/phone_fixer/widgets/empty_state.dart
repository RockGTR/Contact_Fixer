import 'package:flutter/material.dart';

/// Empty state widget shown when all contacts have been processed.
class EmptyState extends StatelessWidget {
  final int totalProcessed;
  final VoidCallback? onSyncPressed;

  const EmptyState({
    super.key,
    required this.totalProcessed,
    this.onSyncPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle, size: 80, color: Colors.green.shade400),
          const SizedBox(height: 16),
          const Text(
            'All Done!',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'No more contacts need fixing',
            style: TextStyle(color: Colors.grey.shade600),
          ),
          if (totalProcessed > 0 && onSyncPressed != null) ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onSyncPressed,
              icon: const Icon(Icons.cloud_upload),
              label: Text('Sync $totalProcessed Changes'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10b981),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 12,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
