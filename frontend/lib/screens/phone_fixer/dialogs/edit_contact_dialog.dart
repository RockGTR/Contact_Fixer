import 'package:flutter/material.dart';
import '../../../models/country.dart';
import '../../../widgets/region/country_picker_sheet.dart';

class EditContactDialog extends StatefulWidget {
  final Map<String, dynamic> contact;
  final String regionCode;
  final Future<void> Function(String newName, String newPhone) onSave;

  const EditContactDialog({
    super.key,
    required this.contact,
    required this.regionCode,
    required this.onSave,
  });

  @override
  State<EditContactDialog> createState() => _EditContactDialogState();
}

class _EditContactDialogState extends State<EditContactDialog> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late Country _selectedCountry;

  @override
  void initState() {
    super.initState();
    _selectedCountry =
        getCountryByCode(widget.regionCode) ??
        supportedCountries.firstWhere(
          (c) => c.code == 'US',
          orElse: () => supportedCountries.first,
        );

    // Initial stripping logic
    String initialPhone =
        widget.contact['suggested'] ?? widget.contact['phone'] ?? '';
    // Clean initial phone if it starts with dial code
    if (initialPhone.startsWith(_selectedCountry.dialCode)) {
      initialPhone = initialPhone
          .substring(_selectedCountry.dialCode.length)
          .trim();
    }

    _phoneController = TextEditingController(text: initialPhone);
    _nameController = TextEditingController(text: widget.contact['name']);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Text('Edit ${widget.contact['name']}'),
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
                    onTap: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => CountryPickerSheet(
                          selectedCountry: _selectedCountry,
                          onSelected: (c) {
                            setState(() {
                              _selectedCountry = c;
                            });
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
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
            final fullNumber =
                _selectedCountry.dialCode + _phoneController.text.trim();

            // Pass back to parent
            Navigator.pop(context);
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
