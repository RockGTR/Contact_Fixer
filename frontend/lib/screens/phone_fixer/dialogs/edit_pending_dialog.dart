import 'package:flutter/material.dart';
import '../../../models/country.dart';
import '../../../widgets/region/country_picker_sheet.dart';

/// Dialog for editing a pending change's name and phone number.
class EditPendingDialog extends StatefulWidget {
  final Map<String, dynamic> change;
  final String initialRegionCode;
  final Future<void> Function(String newName, String newPhone) onSave;

  const EditPendingDialog({
    super.key,
    required this.change,
    required this.initialRegionCode,
    required this.onSave,
  });

  @override
  State<EditPendingDialog> createState() => _EditPendingDialogState();
}

class _EditPendingDialogState extends State<EditPendingDialog> {
  late Country _selectedCountry;
  late TextEditingController _phoneController;
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _selectedCountry =
        getCountryByCode(widget.initialRegionCode) ??
        supportedCountries.firstWhere(
          (c) => c.code == 'US',
          orElse: () => supportedCountries.first,
        );

    // Strip dial code from existing phone for cleaner input
    String initialPhone = widget.change['new_phone'] ?? '';
    if (initialPhone.startsWith(_selectedCountry.dialCode)) {
      initialPhone = initialPhone
          .substring(_selectedCountry.dialCode.length)
          .trim();
    }

    _phoneController = TextEditingController(text: initialPhone);
    _nameController = TextEditingController(
      text: widget.change['new_name'] ?? widget.change['contact_name'],
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CountryPickerSheet(
        selectedCountry: _selectedCountry,
        onSelected: (c) {
          setState(() => _selectedCountry = c);
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Edit ${widget.change['contact_name']}'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _nameController,
              textCapitalization: TextCapitalization.words,
              decoration: InputDecoration(
                labelText: 'Name',
                prefixIcon: const Icon(Icons.person),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                prefixIcon: Container(
                  padding: const EdgeInsets.all(8.0),
                  child: InkWell(
                    onTap: _showCountryPicker,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _selectedCountry.flag,
                          style: const TextStyle(fontSize: 24),
                        ),
                        const Icon(Icons.arrow_drop_down, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          _selectedCountry.dialCode,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.grey.shade700,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 1,
                          height: 24,
                          color: Colors.grey.shade300,
                        ),
                      ],
                    ),
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            Navigator.pop(context);
            final fullNumber =
                _selectedCountry.dialCode + _phoneController.text.trim();
            await widget.onSave(_nameController.text, fullNumber);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF667eea),
          ),
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}

/// Helper function to show the edit pending dialog.
Future<void> showEditPendingDialog({
  required BuildContext context,
  required Map<String, dynamic> change,
  required String regionCode,
  required Future<void> Function(String newName, String newPhone) onSave,
}) {
  return showDialog(
    context: context,
    builder: (context) => EditPendingDialog(
      change: change,
      initialRegionCode: regionCode,
      onSave: onSave,
    ),
  );
}
