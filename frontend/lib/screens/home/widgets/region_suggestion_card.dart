import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/contacts_provider.dart';
import '../../../providers/settings_provider.dart';
import '../../../widgets/neumorphic_container.dart';
import '../../../widgets/neumorphic_button.dart';

class RegionSuggestionCard extends StatelessWidget {
  const RegionSuggestionCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsProvider>(
      builder: (context, settings, _) {
        if (!settings.hasBetterSuggestion) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 24),
          child: NeumorphicContainer(
            padding: const EdgeInsets.all(24),
            borderRadius: BorderRadius.circular(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    NeumorphicContainer(
                      width: 40,
                      height: 40,
                      isPressed: true,
                      shape: BoxShape.circle,
                      child: const Center(
                        child: Icon(
                          Icons.lightbulb_outline,
                          size: 20,
                          color: Color(0xFF10b981),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        'Most of your contacts are from ${settings.suggestedRegion!.name}',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  '${settings.suggestedRegion!.flag} ${settings.suggestedRegion!.name} has ${settings.suggestedRegionCount} contacts vs ${settings.currentRegionCount} for ${settings.defaultRegion.name}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: NeumorphicButton(
                        onTap: () => settings.dismissSuggestion(),
                        color: Theme.of(
                          context,
                        ).scaffoldBackgroundColor, // Secondary look
                        child: Text(
                          'Keep Current',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: NeumorphicButton(
                        onTap: () {
                          final suggested = settings.suggestedRegion!;
                          settings.acceptSuggestion();
                          Provider.of<ContactsProvider>(
                            context,
                            listen: false,
                          ).loadContactsNeedingFix(regionCode: suggested.code);
                        },
                        // Accent simulation via text color or specialized button
                        child: Text(
                          'Switch to ${settings.suggestedRegion!.code}',
                          style: const TextStyle(
                            color: Color(0xFF10b981),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
