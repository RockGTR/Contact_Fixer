import 'package:flutter/material.dart';
import '../../../widgets/neumorphic_container.dart';
import '../utils/phone_fixer_utils.dart';

class ContactCard extends StatelessWidget {
  final Map<String, dynamic> contact;
  final double percentX;
  final double percentY;

  const ContactCard({
    super.key,
    required this.contact,
    this.percentX = 0.0,
    this.percentY = 0.0,
  });

  @override
  Widget build(BuildContext context) {
    // 0 = center, 1 = right (accept), -1 = left (reject)
    // "Travel" threshold increased to 0.4 to prevent accidental triggers
    // Exclusive logic: check primary direction dominance
    final isSwipingRight = percentX > 0.4 && percentX.abs() > percentY.abs();
    final isSwipingLeft = percentX < -0.4 && percentX.abs() > percentY.abs();
    final isSwipingUp = percentY < -0.4 && percentY.abs() > percentX.abs();

    return NeumorphicContainer(
      borderRadius: BorderRadius.circular(32),
      padding: EdgeInsets.zero, // Content padding handled inside
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Swipe indicators
          if (isSwipingRight)
            Positioned(
              top: 40,
              left: 20,
              child: Transform.rotate(
                angle: -0.2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border.all(
                      color: const Color(0xFF10b981),
                      width: 4,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10b981).withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'ACCEPT',
                    style: TextStyle(
                      color: Color(0xFF10b981),
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          if (isSwipingLeft)
            Positioned(
              top: 40,
              right: 20,
              child: Transform.rotate(
                angle: 0.2,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    border: Border.all(
                      color: const Color(0xFFef4444),
                      width: 4,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFef4444).withOpacity(0.2),
                        blurRadius: 8,
                        offset: const Offset(2, 2),
                      ),
                    ],
                  ),
                  child: const Text(
                    'SKIP',
                    style: TextStyle(
                      color: Color(0xFFef4444),
                      fontWeight: FontWeight.w900,
                      fontSize: 24,
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          if (isSwipingUp)
            Positioned(
              bottom: 40,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  border: Border.all(color: const Color(0xFF667eea), width: 4),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF667eea).withOpacity(0.2),
                      blurRadius: 8,
                      offset: const Offset(2, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'EDIT',
                  style: TextStyle(
                    color: Color(0xFF667eea),
                    fontWeight: FontWeight.w900,
                    fontSize: 24,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
            ),

          // Card content
          Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar with Neumorphic surround
                NeumorphicContainer(
                  padding: const EdgeInsets.all(8),
                  shape: BoxShape.circle,
                  child: CircleAvatar(
                    radius: 50,
                    backgroundColor: getColorForName(
                      contact['name'],
                    ).withOpacity(0.15),
                    child: Text(
                      contact['name']
                              ?.toString()
                              .substring(0, 1)
                              .toUpperCase() ??
                          '?',
                      style: TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: getColorForName(contact['name']),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Name
                Text(
                  contact['name'] ?? 'Unknown',
                  style: Theme.of(context).textTheme.displaySmall?.copyWith(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),

                // Current phone (Inset)
                NeumorphicContainer(
                  padding: const EdgeInsets.all(16),
                  isPressed: true, // Inset
                  borderRadius: BorderRadius.circular(16),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.phone_disabled,
                        color: Color(0xFFef4444),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        contact['phone'] ?? '',
                        style: const TextStyle(
                          fontSize: 18,
                          decoration: TextDecoration.lineThrough,
                          color: Color(0xFFef4444),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Arrow
                Icon(
                  Icons.arrow_downward_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                const SizedBox(height: 16),

                // Suggested phone (Extruded or different style? Inset looks good for data fields. Let's make this one pop or also inset for consistency but green)
                NeumorphicContainer(
                  padding: const EdgeInsets.all(16),
                  // isPressed: false, // Extruded to show "Proposed"
                  // Or Inset to show "New Value Slot"
                  // I'll use Extruded to make it stand out as the 'solution'
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFF10b981).withOpacity(
                    0.05,
                  ), // Subtle tint? Neumorphism usually prefers solid.
                  // I'll stick to base color
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.phone, color: Color(0xFF10b981)),
                      const SizedBox(width: 12),
                      Text(
                        contact['suggested'] ?? '',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF10b981),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
