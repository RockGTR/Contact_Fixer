import 'package:flutter/material.dart';
import '../../models/country.dart';
import '../../services/api_service.dart';
import '../../mixins/auth_token_mixin.dart';

class CountryPickerSheet extends StatefulWidget {
  final Country selectedCountry;
  final ValueChanged<Country> onSelected;

  const CountryPickerSheet({
    super.key,
    required this.selectedCountry,
    required this.onSelected,
  });

  @override
  State<CountryPickerSheet> createState() => _CountryPickerSheetState();
}

class _CountryPickerSheetState extends State<CountryPickerSheet>
    with AuthTokenMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _suggestedRegions = [];
  late final ApiService _api;

  @override
  void initState() {
    super.initState();
    _api = createApiService(context);
    _loadSuggestedRegions();
  }

  Future<void> _loadSuggestedRegions() async {
    try {
      final idToken = await getIdToken(context);
      final result = await _api.analyzeRegions(idToken);
      setState(() {
        _suggestedRegions = List<Map<String, dynamic>>.from(
          result['regions'] ?? [],
        );
      });
    } catch (e) {
      // Silently fail - suggestions are optional
    }
  }

  List<Country> get filteredCountries {
    if (_searchQuery.isEmpty) return supportedCountries;

    final query = _searchQuery.toLowerCase();
    return supportedCountries.where((country) {
      return country.name.toLowerCase().contains(query) ||
          country.code.toLowerCase().contains(query) ||
          country.dialCode.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Title
          Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Select Default Region',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _searchQuery = value),
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
              decoration: InputDecoration(
                hintText: 'Search countries...',
                hintStyle: TextStyle(
                  color: Theme.of(
                    context,
                  ).colorScheme.secondary.withOpacity(0.5),
                ),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: Theme.of(context).colorScheme.secondary,
                ),
                filled: true,
                fillColor: Theme.of(
                  context,
                ).colorScheme.surface, // Or just a slightly darker shade
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Suggested Regions Section (only show when not searching)
          if (_searchQuery.isEmpty && _suggestedRegions.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF667eea).withOpacity(0.05),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: const Color(0xFF667eea).withOpacity(0.1),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: Color(0xFF667eea),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Suggested for your contacts',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF667eea),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...(_suggestedRegions.take(3).map((r) {
                      final regionCode = r['region'] as String;
                      final count = r['count'] as int;
                      final country = getCountryByCode(regionCode);
                      if (country == null) return const SizedBox.shrink();

                      final isSelected =
                          country.code == widget.selectedCountry.code;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: InkWell(
                          onTap: () => widget.onSelected(country),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFF667eea).withOpacity(0.15)
                                  : Theme.of(context).scaffoldBackgroundColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Text(
                                  country.flag,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        country.name,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              fontWeight: isSelected
                                                  ? FontWeight.bold
                                                  : FontWeight.w500,
                                            ),
                                      ),
                                      Text(
                                        country.dialCode,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.secondary,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(
                                      0xFF10b981,
                                    ).withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '$count contacts',
                                    style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF10b981),
                                    ),
                                  ),
                                ),
                                if (isSelected) ...[
                                  const SizedBox(width: 8),
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Color(0xFF667eea),
                                    size: 20,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      );
                    })),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Divider(color: Theme.of(context).dividerColor),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'All Countries',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  Expanded(
                    child: Divider(color: Theme.of(context).dividerColor),
                  ),
                ],
              ),
            ),
          ],

          // Country list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredCountries.length,
              itemBuilder: (context, index) {
                final country = filteredCountries[index];
                final isSelected = country.code == widget.selectedCountry.code;

                return ListTile(
                  onTap: () => widget.onSelected(country),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  selected: isSelected,
                  selectedTileColor: const Color(0xFF667eea).withOpacity(0.1),
                  leading: Text(
                    country.flag,
                    style: const TextStyle(fontSize: 28),
                  ),
                  title: Text(
                    country.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: isSelected
                          ? FontWeight.bold
                          : FontWeight.w500,
                    ),
                  ),
                  subtitle: Text(
                    country.dialCode,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.secondary,
                    ),
                  ),
                  trailing: isSelected
                      ? const Icon(
                          Icons.check_circle_rounded,
                          color: Color(0xFF667eea),
                        )
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
