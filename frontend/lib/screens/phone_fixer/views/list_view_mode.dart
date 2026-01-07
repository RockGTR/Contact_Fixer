import 'package:flutter/material.dart';
import '../widgets/stat_chip.dart';
import '../utils/phone_fixer_utils.dart';

/// List-based view for processing contacts with action buttons.
/// Shows all contacts in a scrollable list with Accept/Edit/Reject actions.
class ListViewMode extends StatelessWidget {
  final List<Map<String, dynamic>> contacts;
  final int acceptCount;
  final int rejectCount;
  final int editCount;
  final Function(Map<String, dynamic>) onAccept;
  final Function(Map<String, dynamic>) onReject;
  final Function(Map<String, dynamic>) onEdit;

  const ListViewMode({
    super.key,
    required this.contacts,
    required this.acceptCount,
    required this.rejectCount,
    required this.editCount,
    required this.onAccept,
    required this.onReject,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress indicator
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              StatChip(
                label: 'Accepted',
                count: acceptCount,
                color: const Color(0xFF10b981),
                icon: Icons.check,
              ),
              StatChip(
                label: 'Skipped',
                count: rejectCount,
                color: const Color(0xFFef4444),
                icon: Icons.close,
              ),
              StatChip(
                label: 'Edited',
                count: editCount,
                color: const Color(0xFF667eea),
                icon: Icons.edit,
              ),
              StatChip(
                label: 'Left',
                count: contacts.length,
                color: Colors.grey,
                icon: Icons.list,
              ),
            ],
          ),
        ),

        // List of contacts
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: contacts.length,
            itemBuilder: (context, index) {
              final contact = contacts[index];
              return _ContactListItem(
                contact: contact,
                onAccept: () => onAccept(contact),
                onReject: () => onReject(contact),
                onEdit: () => onEdit(contact),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _ContactListItem extends StatelessWidget {
  final Map<String, dynamic> contact;
  final VoidCallback onAccept;
  final VoidCallback onReject;
  final VoidCallback onEdit;

  const _ContactListItem({
    required this.contact,
    required this.onAccept,
    required this.onReject,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final color = getColorForName(contact['name']);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 28,
              backgroundColor: color.withOpacity(0.15),
              child: Text(
                contact['name']?.toString().substring(0, 1).toUpperCase() ??
                    '?',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(width: 16),

            // Contact info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${contact['phone']} → ${contact['suggested']}',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),

            // Action buttons
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Color(0xFFef4444)),
                  onPressed: onReject,
                ),
                IconButton(
                  icon: const Icon(Icons.edit, color: Color(0xFF667eea)),
                  onPressed: onEdit,
                ),
                IconButton(
                  icon: const Icon(Icons.check, color: Color(0xFF10b981)),
                  onPressed: onAccept,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
