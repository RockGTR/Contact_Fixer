import 'package:flutter/material.dart';
import '../../../widgets/neumorphic_container.dart';

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: NeumorphicContainer(
        padding: const EdgeInsets.all(20),
        borderRadius: BorderRadius.circular(20),
        child: Row(
          children: [
            NeumorphicContainer(
              padding: const EdgeInsets.all(10),
              shape: BoxShape.circle,
              isPressed: true, // Inset
              child: Icon(
                action == 'accept'
                    ? Icons.check_rounded
                    : action == 'reject'
                    ? Icons.close_rounded
                    : Icons.edit_rounded,
                color: actionColor,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    change['contact_name'] ?? 'Unknown',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
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
                                color: Theme.of(
                                  context,
                                ).colorScheme.secondary.withOpacity(0.5),
                                fontSize: 12,
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Icon(
                                Icons.arrow_forward_rounded,
                                size: 12,
                                color: Theme.of(context).colorScheme.secondary,
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
                            color: const Color(0xFFef4444).withOpacity(0.7),
                            decoration: TextDecoration.lineThrough,
                            fontSize: 13,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            size: 16,
                            color: Theme.of(context).colorScheme.secondary,
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
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.secondary,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit_rounded, color: Color(0xFF667eea)),
              onPressed: onEdit,
              visualDensity: VisualDensity.compact,
            ),
            IconButton(
              icon: Icon(
                Icons.delete_outline_rounded,
                color: Theme.of(context).colorScheme.secondary,
              ),
              onPressed: onDelete,
              visualDensity: VisualDensity.compact,
            ),
          ],
        ),
      ),
    );
  }
}
