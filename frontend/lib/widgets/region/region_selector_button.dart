import 'package:flutter/material.dart';
import '../neumorphic_button.dart';
import 'country_picker_sheet.dart';
import '../../models/country.dart';

class RegionSelector extends StatelessWidget {
  final Country selectedCountry;
  final ValueChanged<Country> onChanged;

  const RegionSelector({
    super.key,
    required this.selectedCountry,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return NeumorphicButton(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (sheetContext) => CountryPickerSheet(
            selectedCountry: selectedCountry,
            onSelected: (country) {
              Navigator.pop(sheetContext); // Close sheet first
              onChanged(country);
            },
          ),
        );
      },
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      borderRadius: BorderRadius.circular(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(selectedCountry.flag, style: const TextStyle(fontSize: 24)),
          const SizedBox(width: 8),
          Text(
            selectedCountry.code,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            color: Theme.of(context).colorScheme.secondary,
            size: 20,
          ),
        ],
      ),
    );
  }
}
