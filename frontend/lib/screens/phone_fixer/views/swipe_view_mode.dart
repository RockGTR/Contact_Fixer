import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import '../widgets/contact_card.dart';
import '../widgets/stat_chip.dart';

/// Swipe-based card view for processing contacts with gestures.
/// Right swipe = Accept, Left swipe = Reject, Up swipe = Edit
class SwipeViewMode extends StatelessWidget {
  final CardSwiperController controller;
  final List<Map<String, dynamic>> contacts;
  final int acceptCount;
  final int rejectCount;
  final int editCount;
  final Function(Map<String, dynamic>, CardSwiperDirection) onSwipe;
  final VoidCallback onEndReached;
  final Function(Map<String, dynamic>) onEditPressed;

  const SwipeViewMode({
    super.key,
    required this.controller,
    required this.contacts,
    required this.acceptCount,
    required this.rejectCount,
    required this.editCount,
    required this.onSwipe,
    required this.onEndReached,
    required this.onEditPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Progress indicator
        Container(
          height: 120,
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              StatChip(
                label: 'Accepted',
                count: acceptCount,
                color: const Color(0xFF10b981),
                icon: Icons.check_rounded,
              ),
              StatChip(
                label: 'Skipped',
                count: rejectCount,
                color: const Color(0xFFef4444),
                icon: Icons.close_rounded,
              ),
              StatChip(
                label: 'Edited',
                count: editCount,
                color: const Color(0xFF667eea),
                icon: Icons.edit_rounded,
              ),
              StatChip(
                label: 'Left',
                count: contacts.length,
                color: Colors.grey,
                icon: Icons.list_rounded,
              ),
            ],
          ),
        ),

        // Swipe instructions
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _InstructionItem(
                text: 'Skip',
                icon: Icons.swipe_left,
                color: const Color(0xFFef4444),
              ),
              Container(
                width: 1,
                height: 12,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              _InstructionItem(
                text: 'Edit',
                icon: Icons.swipe_up,
                color: const Color(0xFF667eea),
              ),
              Container(
                width: 1,
                height: 12,
                color: Colors.grey.shade300,
                margin: const EdgeInsets.symmetric(horizontal: 12),
              ),
              _InstructionItem(
                text: 'Accept',
                icon: Icons.swipe_right,
                color: const Color(0xFF10b981),
              ),
            ],
          ),
        ),

        // Card swiper
        Expanded(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: CardSwiper(
                controller: controller,
                cardsCount: contacts.length,
                numberOfCardsDisplayed: contacts.length > 1 ? 2 : 1,
                backCardOffset: const Offset(0, 40),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                allowedSwipeDirection: const AllowedSwipeDirection.only(
                  left: true,
                  right: true,
                  up: true,
                ),
                onSwipe: (prev, curr, direction) {
                  final contact = contacts[prev];
                  if (direction == CardSwiperDirection.top) {
                    onEditPressed(contact);
                    return false; // Don't auto-advance, dialog will handle it
                  }
                  onSwipe(contact, direction);
                  return true;
                },
                onEnd: onEndReached,
                cardBuilder: (context, index, percentX, percentY) {
                  return Center(
                    child: ContactCard(
                      contact: contacts[index],
                      percentX: percentX.toDouble(),
                      percentY: percentY.toDouble(),
                    ),
                  );
                },
              ),
            ),
          ),
        ),

        // Action buttons
        Padding(
          padding: const EdgeInsets.fromLTRB(40, 0, 40, 32),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _ActionButton(
                icon: Icons.close,
                color: const Color(0xFFef4444),
                onTap: () => controller.swipe(CardSwiperDirection.left),
              ),
              _ActionButton(
                icon: Icons.edit,
                color: const Color(0xFF667eea),
                size: 50,
                onTap: () {
                  if (contacts.isNotEmpty) {
                    onEditPressed(contacts[0]);
                  }
                },
              ),
              _ActionButton(
                icon: Icons.check,
                color: const Color(0xFF10b981),
                onTap: () => controller.swipe(CardSwiperDirection.right),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final double size;

  const _ActionButton({
    required this.icon,
    required this.color,
    required this.onTap,
    this.size = 64,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}

class _InstructionItem extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;

  const _InstructionItem({
    required this.text,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color.withOpacity(0.8)),
        const SizedBox(width: 4),
        Text(
          text,
          style: TextStyle(
            color: color.withOpacity(0.8),
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}
