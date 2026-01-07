import 'package:flutter/material.dart';
import '../utils/phone_fixer_utils.dart';

class ContactCard extends StatelessWidget {
  final Map<String, dynamic> contact;
  final double percentX;

  const ContactCard({super.key, required this.contact, this.percentX = 0.0});

  @override
  Widget build(BuildContext context) {
    // 0 = center, 1 = right (accept), -1 = left (reject)
    // We want to show "ACCEPT" if swiping right, "SKIP" if swiping left
    final isSwipingRight = percentX > 0.2;
    final isSwipingLeft = percentX < -0.2;

    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.zero,
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
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFF10b981),
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(12),
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
                      color: Colors.white,
                      border: Border.all(
                        color: const Color(0xFFef4444),
                        width: 4,
                      ),
                      borderRadius: BorderRadius.circular(12),
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

            // Card content
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Avatar with alphabet color
                  CircleAvatar(
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
                  const SizedBox(height: 20),

                  // Name
                  Text(
                    contact['name'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1f2937),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Current phone (with strikethrough)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFef4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                  const SizedBox(height: 12),

                  // Arrow
                  const Icon(Icons.arrow_downward, color: Colors.grey),
                  const SizedBox(height: 12),

                  // Suggested phone
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10b981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
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
      ),
    );
  }
}
