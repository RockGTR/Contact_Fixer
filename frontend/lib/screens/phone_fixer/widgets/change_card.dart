import 'package:flutter/material.dart';

/// Card displaying a single pending change with edit and delete actions.
class ChangeCard extends StatelessWidget {
  final Map<String, dynamic> change;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ChangeCard({
    super.key,
    required this.change,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final action = change['action'];
    final Color actionColor = action == 'accept'
        ? const Color(0xFF10b981)
        : action == 'reject'
        ? const Color(0xFFef4444)
        : const Color(0xFF667eea);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: actionColor.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: actionColor.withOpacity(0.1),
            child: Icon(
              action == 'accept'
                  ? Icons.check
                  : action == 'reject'
                  ? Icons.close
                  : Icons.edit,
              color: actionColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  change['contact_name'] ?? 'Unknown',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                if (action != 'reject') ...[
                  if (change['new_name'] != null &&
                      change['new_name'] != change['contact_name'])
                    Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Row(
                        children: [
                          Text(
                            change['contact_name'],
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey.shade400,
                              fontSize: 12,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 4),
                            child: Icon(
                              Icons.arrow_forward,
                              size: 12,
                              color: Colors.grey,
                            ),
                          ),
                          Text(
                            change['new_name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        change['original_phone'],
                        style: TextStyle(
                          color: Colors.red.shade300,
                          decoration: TextDecoration.lineThrough,
                          fontSize: 13,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                        child: Icon(
                          Icons.arrow_forward,
                          size: 16,
                          color: Colors.grey,
                        ),
                      ),
                      Text(
                        change['new_phone'],
                        style: const TextStyle(
                          color: Color(0xFF10b981),
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ] else
                  Text(
                    'Skipped',
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF667eea)),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.grey),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
