import 'package:flutter/material.dart';
import '../utils/phone_fixer_utils.dart';

class ControlToolbar extends StatelessWidget {
  final SortOption sortOption;
  final bool isAscending;
  final bool isSwipeView;
  final VoidCallback onToggleView;
  final Function(dynamic) onSortSelected;
  final VoidCallback onAcceptAll;
  final int contactCount;

  const ControlToolbar({
    super.key,
    required this.sortOption,
    required this.isAscending,
    required this.isSwipeView,
    required this.onToggleView,
    required this.onSortSelected,
    required this.onAcceptAll,
    required this.contactCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Accept All Button
          ElevatedButton.icon(
            onPressed: contactCount > 0 ? onAcceptAll : null,
            icon: const Icon(Icons.done_all, size: 18),
            label: const Text('Accept All'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF10b981),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          Row(
            children: [
              // Sort Menu
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: PopupMenuButton<dynamic>(
                  icon: const Icon(Icons.sort, color: Colors.black54),
                  tooltip: 'Sort Contacts',
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: onSortSelected,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: SortOption.name,
                      child: Row(
                        children: [
                          const Text('Name'),
                          if (sortOption == SortOption.name)
                            Icon(
                              isAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: SortOption.phone,
                      child: Row(
                        children: [
                          const Text('Phone'),
                          if (sortOption == SortOption.phone)
                            Icon(
                              isAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: SortOption.lastModified,
                      child: Row(
                        children: [
                          const Text('Last Modified'),
                          if (sortOption == SortOption.lastModified)
                            Icon(
                              isAscending
                                  ? Icons.arrow_upward
                                  : Icons.arrow_downward,
                              size: 16,
                            ),
                        ],
                      ),
                    ),
                    const PopupMenuDivider(),
                    CheckedPopupMenuItem(
                      checked: isAscending,
                      value: 'ASC',
                      child: const Text('Ascending'),
                    ),
                    CheckedPopupMenuItem(
                      checked: !isAscending,
                      value: 'DESC',
                      child: const Text('Descending'),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Toggle View Button
              ActionChip(
                avatar: Icon(
                  isSwipeView ? Icons.view_list : Icons.style,
                  size: 18,
                ),
                label: Text(isSwipeView ? 'List View' : 'Swipe View'),
                onPressed: onToggleView,
                backgroundColor: const Color(0xFFE8EAF6),
                labelStyle: const TextStyle(color: Color(0xFF3949AB)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
