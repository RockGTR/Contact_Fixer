import 'package:flutter/material.dart';

/// Neumorphic progress bar with animated fill and glow effect
class NeumorphicProgressBar extends StatelessWidget {
  final double progress;
  final bool isBackingOff;
  final Animation<double> pulseAnimation;

  const NeumorphicProgressBar({
    super.key,
    required this.progress,
    this.isBackingOff = false,
    required this.pulseAnimation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 20,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E5EC),
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(163, 177, 198, 0.6),
            offset: Offset(3, 3),
            blurRadius: 6,
          ),
          BoxShadow(
            color: Color.fromRGBO(255, 255, 255, 0.5),
            offset: Offset(-3, -3),
            blurRadius: 6,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Stack(
          children: [
            // Inset background gradient
            Container(
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFD1D5DB), Color(0xFFE0E5EC)],
                ),
              ),
            ),
            // Animated progress fill
            AnimatedBuilder(
              animation: pulseAnimation,
              builder: (context, child) {
                return FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isBackingOff
                            ? const [Color(0xFFf59e0b), Color(0xFFf97316)]
                            : [
                                const Color(0xFF10b981),
                                Color.lerp(
                                  const Color(0xFF10b981),
                                  const Color(0xFF34d399),
                                  pulseAnimation.value,
                                )!,
                              ],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Color.fromRGBO(
                            isBackingOff ? 245 : 16,
                            isBackingOff ? 158 : 185,
                            isBackingOff ? 11 : 129,
                            0.4,
                          ),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
