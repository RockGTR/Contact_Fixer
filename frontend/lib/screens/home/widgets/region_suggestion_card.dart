import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/contacts_provider.dart';
import '../../../providers/settings_provider.dart';

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
          padding: const EdgeInsets.only(top: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF10b981).withOpacity(0.1),
                  const Color(0xFF059669).withOpacity(0.05),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF10b981).withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.lightbulb_outline,
                      size: 18,
                      color: const Color(0xFF10b981),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Most of your contacts are from ${settings.suggestedRegion!.name}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${settings.suggestedRegion!.flag} ${settings.suggestedRegion!.name} has ${settings.suggestedRegionCount} contacts vs ${settings.currentRegionCount} for ${settings.defaultRegion.name}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => settings.dismissSuggestion(),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey.shade300),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: const Text(
                          'Keep Current',
                          style: TextStyle(color: Color(0xFF6b7280)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          final suggested = settings.suggestedRegion!;
                          settings.acceptSuggestion();
                          Provider.of<ContactsProvider>(
                            context,
                            listen: false,
                          ).loadContactsNeedingFix(regionCode: suggested.code);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10b981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Switch to ${settings.suggestedRegion!.code}',
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
