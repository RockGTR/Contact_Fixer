import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/contacts_provider.dart';
import '../providers/settings_provider.dart';
import '../widgets/region/region_selector_button.dart';
import 'home/widgets/action_card.dart';
import 'home/widgets/home_header.dart';
import 'home/widgets/how_it_works_card.dart';
import 'home/widgets/region_suggestion_card.dart';
import 'phone_fixer_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final settings = Provider.of<SettingsProvider>(context, listen: false);
      Provider.of<ContactsProvider>(
        context,
        listen: false,
      ).loadContactsNeedingFix(regionCode: settings.defaultRegion.code);
    });
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  @override
  Widget build(BuildContext context) {
    final contacts = Provider.of<ContactsProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      body: CustomScrollView(
        slivers: [
          // Extracted Header
          const HomeHeader(),

          // Content
          SliverPadding(
            padding: const EdgeInsets.all(20),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Sync Card
                ActionCard(
                  icon: Icons.sync_rounded,
                  iconColor: const Color(0xFF667eea),
                  iconBgColor: const Color(0xFF667eea).withOpacity(0.1),
                  title: contacts.isLoading ? 'Syncing...' : 'Sync Contacts',
                  subtitle: contacts.lastSyncTime != null
                      ? '${contacts.syncedCount} contacts • ${_formatTime(contacts.lastSyncTime!)}'
                      : 'Download contacts from Google',
                  isLoading: contacts.isLoading,
                  onTap: contacts.isLoading
                      ? null
                      : () {
                          final settings = Provider.of<SettingsProvider>(
                            context,
                            listen: false,
                          );
                          contacts.syncFromGoogle(
                            regionCode: settings.defaultRegion.code,
                          );
                        },
                ),

                const SizedBox(height: 16),

                // Section Title: Default Region
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.public,
                        size: 18,
                        color: Color(0xFF667eea),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Default Region',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1f2937),
                        ),
                      ),
                    ],
                  ),
                ),

                // Default Region Selector
                Consumer<SettingsProvider>(
                  builder: (context, settings, _) {
                    return RegionSelector(
                      selectedCountry: settings.defaultRegion,
                      onChanged: (country) {
                        settings.setDefaultRegion(country);
                        // Reload contacts with new region
                        final contactsProvider = Provider.of<ContactsProvider>(
                          context,
                          listen: false,
                        );
                        contactsProvider.loadContactsNeedingFix(
                          regionCode: country.code,
                        );
                      },
                    );
                  },
                ),

                // Extracted Region Suggestion
                const RegionSuggestionCard(),

                const SizedBox(height: 16),

                // Contacts Needing Fix Card
                ActionCard(
                  icon: contacts.needsFixCount > 0
                      ? Icons.warning_amber_rounded
                      : Icons.check_circle_rounded,
                  iconColor: contacts.needsFixCount > 0
                      ? const Color(0xFFf59e0b)
                      : const Color(0xFF10b981),
                  iconBgColor: contacts.needsFixCount > 0
                      ? const Color(0xFFf59e0b).withOpacity(0.1)
                      : const Color(0xFF10b981).withOpacity(0.1),
                  title: contacts.needsFixCount > 0
                      ? '${contacts.needsFixCount} Need Fixing'
                      : 'All Good!',
                  subtitle: contacts.needsFixCount > 0
                      ? 'Phone numbers need standardization'
                      : 'No formatting issues found',
                  onTap: () async {
                    final settings = Provider.of<SettingsProvider>(
                      context,
                      listen: false,
                    );
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PhoneFixerScreen(
                          regionCode: settings.defaultRegion.code,
                        ),
                      ),
                    );
                    // Refresh count on return
                    if (context.mounted) {
                      Provider.of<ContactsProvider>(
                        context,
                        listen: false,
                      ).loadContactsNeedingFix(
                        regionCode: settings.defaultRegion.code,
                      );
                    }
                  },
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: contacts.needsFixCount > 0
                          ? const Color(0xFFf59e0b).withOpacity(0.1)
                          : const Color(0xFF10b981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'View',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: contacts.needsFixCount > 0
                            ? const Color(0xFFf59e0b)
                            : const Color(0xFF10b981),
                      ),
                    ),
                  ),
                ),

                // Error Message
                if (contacts.errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFef4444).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: const Color(0xFFef4444).withOpacity(0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.error_outline,
                          color: Color(0xFFef4444),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            contacts.errorMessage!,
                            style: const TextStyle(color: Color(0xFFef4444)),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 20),
                          onPressed: () => contacts.clearError(),
                          color: const Color(0xFFef4444),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 32),

                // Extracted Info Section
                const HowItWorksCard(),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}
