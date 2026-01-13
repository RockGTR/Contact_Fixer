import 'package:flutter/material.dart';
import '../../../widgets/neumorphic_container.dart';

class HowItWorksCard extends StatelessWidget {
  const HowItWorksCard({super.key});

  @override
  Widget build(BuildContext context) {
    return NeumorphicContainer(
      padding: const EdgeInsets.all(24),
      borderRadius: BorderRadius.circular(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              NeumorphicContainer(
                padding: const EdgeInsets.all(8),
                borderRadius: BorderRadius.circular(12),
                isPressed: true, // Inset feel for icon background
                child: const Icon(
                  Icons.info_outline_rounded,
                  size: 20,
                  color: Color(0xFF667eea),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'How it works',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildInfoItem(context, '1', 'Sync your Google contacts'),
          const SizedBox(height: 12),
          _buildInfoItem(context, '2', 'Review numbers needing fixes'),
          const SizedBox(height: 12),
          _buildInfoItem(context, '3', 'Apply standardized E.164 format'),
        ],
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, String number, String text) {
    return Row(
      children: [
        NeumorphicContainer(
          width: 28,
          height: 28,
          shape: BoxShape.circle,
          isPressed: true,
          child: Center(
            child: Text(
              number,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFF667eea),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.secondary,
            ),
          ),
        ),
      ],
    );
  }
}
