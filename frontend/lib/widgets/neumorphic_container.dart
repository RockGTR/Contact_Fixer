import 'package:flutter/material.dart';

class NeumorphicContainer extends StatelessWidget {
  final Widget? child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final bool isPressed;
  final Color? color;
  final BoxShape shape;
  final VoidCallback? onTap;
  final AlignmentGeometry? alignment;

  const NeumorphicContainer({
    super.key,
    this.child,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.isPressed = false,
    this.color,
    this.shape = BoxShape.rectangle,
    this.onTap,
    this.alignment,
  });

  @override
  Widget build(BuildContext context) {
    // Base cool grey color
    final baseColor = color ?? const Color(0xFFE0E5EC);

    // Smooth shadows using RGB for blending
    final List<BoxShadow> shadows = isPressed
        ? [
            // Inset (Pressed) - Inner shadows
            BoxShadow(
              color: const Color.fromRGBO(163, 177, 198, 0.6),
              offset: const Offset(6, 6),
              blurRadius: 10,
              spreadRadius: 0,
              // Flutter doesn't support 'inset' directly in BoxShadow but we can simulate
              // or use a stack/painter. However, standard Neumorphism in Flutter often uses
              // a library or manual painting. For simplicity/maintainability without extra deps,
              // we can use a reverse shadow trick or just a darker color for pressed state for now
              // if we want to avoid complex painters.
              // BUT, for true quality, let's try to simulate or prioritize external feel first.
              // Actually, standard Flutter BoxShadow does NOT support inset.
              // We will simulate "pressed" by removing drop shadows and darkening slightly,
              // OR providing a simulated inset effect using a Container with Gradient/InnerShadow if possible.
              // For valid "Inset" without packages, we usually need correct CustomPainters.
              // To keep it simple and robust, let's use a flat+internal shadow approximation
              // or simply swap the shadows to be "flat" and maybe change bg color slightly.
            ),
            BoxShadow(
              color: const Color.fromRGBO(255, 255, 255, 0.5),
              offset: const Offset(-6, -6),
              blurRadius: 10,
              spreadRadius: 0,
            ),
          ]
        : [
            // Extruded (Standard) - Drop shadows
            BoxShadow(
              color: const Color.fromRGBO(163, 177, 198, 0.6),
              offset: const Offset(9, 9),
              blurRadius: 16,
              spreadRadius: 0,
            ),
            BoxShadow(
              color: const Color.fromRGBO(255, 255, 255, 0.5),
              offset: const Offset(-9, -9),
              blurRadius: 16,
              spreadRadius: 0,
            ),
          ];

    // For "Pressed" state (Inset), since Flutter BoxShadow doesn't support inset:
    // A common lightweight workaround without packages is to simply remove the drop shadow
    // and maybe darken the background or use a different gradient to simulate depth.
    // However, to truly get "Inset", we need a different approach.
    // Given the constraints, I will implement a visual approximations:
    // PRESSED: No drop shadow, slightly darker background or inner gradient (simulated).
    // EXTRUDED: Drop shadows.

    final toggleShadows = isPressed
        ? <BoxShadow>[] // No outer shadows when pressed to simulate being "in"
        : shadows;

    // To simulate "inner" shadow on pressed, we can use a gradient on the container
    final innerDecoration = isPressed
        ? BoxDecoration(
            color: baseColor,
            borderRadius: shape == BoxShape.circle
                ? null
                : (borderRadius ?? BorderRadius.circular(32)),
            shape: shape,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color.fromRGBO(163, 177, 198, 0.6), // Darker top-left
                const Color.fromRGBO(
                  255,
                  255,
                  255,
                  0.5,
                ), // Lighter bottom-right
              ],
              stops: const [0.0, 1.0],
            ),
          )
        : BoxDecoration(
            color: baseColor,
            borderRadius: shape == BoxShape.circle
                ? null
                : (borderRadius ?? BorderRadius.circular(32)),
            shape: shape,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                // Slight gradient to enhance convex shape
                baseColor.withOpacity(1.0),
                baseColor.withOpacity(0.9), // Subtle variation
              ],
            ),
            boxShadow: toggleShadows,
          );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: width,
        height: height,
        padding: padding,
        decoration: innerDecoration,
        alignment: alignment,
        child: child,
      ),
    );
  }
}
