import 'package:flutter/material.dart';
import '../../../widgets/neumorphic_container.dart';
import '../../../widgets/neumorphic_button.dart';

class ActionCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBgColor;
  final String title;
  final String subtitle;
  final bool isLoading;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ActionCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.title,
    required this.subtitle,
    this.isLoading = false,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    if (onTap != null) {
      return NeumorphicButton(
        onTap: onTap!,
        padding: const EdgeInsets.all(24),
        borderRadius: BorderRadius.circular(32),
        child: _buildContent(context),
      );
    }

    return NeumorphicContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(32),
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    return Row(
      children: [
        // Inset Well for Icon
        NeumorphicContainer(
          width: 56,
          height: 56,
          borderRadius: BorderRadius.circular(16),
          isPressed: true, // Inset look
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: iconColor,
                    ),
                  )
                : Icon(icon, color: iconColor, size: 28),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
        if (trailing == null && onTap != null)
          Icon(
            Icons.chevron_right_rounded,
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.5),
          ),
      ],
    );
  }
}
