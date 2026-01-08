import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'neumorphic_container.dart';

class NeumorphicButton extends StatefulWidget {
  final VoidCallback onTap;
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final BoxShape shape;
  final Color? color;

  const NeumorphicButton({
    super.key,
    required this.onTap,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
    this.color,
  });

  @override
  State<NeumorphicButton> createState() => _NeumorphicButtonState();
}

class _NeumorphicButtonState extends State<NeumorphicButton> {
  bool _isPressed = false;

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _isPressed = true;
    });
    HapticFeedback.lightImpact();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() {
      _isPressed = false;
    });
    widget.onTap();
  }

  void _handleTapCancel() {
    setState(() {
      _isPressed = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: _handleTapUp,
      onTapCancel: _handleTapCancel,
      child: AnimatedScale(
        scale: _isPressed ? 0.98 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeInOut,
        child: NeumorphicContainer(
          width: widget.width,
          height: widget.height,
          padding: widget.padding ?? const EdgeInsets.all(16),
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16),
          shape: widget.shape,
          color: widget.color,
          isPressed: _isPressed,
          alignment: Alignment.center,
          child: widget.child,
        ),
      ),
    );
  }
}
