import 'package:flutter/material.dart';
import '../../../widgets/neumorphic_container.dart';
import '../../../widgets/neumorphic_button.dart';
import '../utils/phone_fixer_utils.dart';

class ControlToolbar extends StatelessWidget {
  final SortOption sortOption;
  final bool isAscending;
  final bool isSwipeView;
  final VoidCallback onToggleView;
  final Function(dynamic) onSortSelected;
  final VoidCallback? onAcceptAll; // Optional parameter
  final int contactCount;

  const ControlToolbar({
    super.key,
    required this.sortOption,
    required this.isAscending,
    required this.isSwipeView,
    required this.onToggleView,
    required this.onSortSelected,
    this.onAcceptAll,
    required this.contactCount,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              // Sort Menu in Neumorphic Container
              NeumorphicContainer(
                borderRadius: BorderRadius.circular(12),
                child: PopupMenuButton<dynamic>(
                  icon: Icon(
                    Icons.sort_rounded,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  tooltip: 'Sort Contacts',
                  color: Theme.of(context).scaffoldBackgroundColor,
                  elevation:
                      4, // Popup menu elevation can't be easily neumorphicized without custom popup
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
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
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
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
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
                                  ? Icons.arrow_upward_rounded
                                  : Icons.arrow_downward_rounded,
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
              const SizedBox(width: 16),

              // Toggle View Button using NeumorphicButton
              NeumorphicButton(
                onTap: onToggleView,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                borderRadius: BorderRadius.circular(24),
                child: Row(
                  children: [
                    Icon(
                      isSwipeView
                          ? Icons.view_list_rounded
                          : Icons.style_outlined,
                      size: 18,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isSwipeView ? 'List View' : 'Card View',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
