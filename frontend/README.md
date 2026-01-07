# Contact Fixer Frontend

A Flutter application designed to standardize and format phone numbers in your Google Contacts.

## Project Structure

The project follows a modular architecture separating screens into logical components:

```
lib/
├── models/             # Data models (Contact, Country, etc.)
├── providers/          # State management (ContactsProvider, AuthProvider)
├── services/           # Backend API communication
├── widgets/            # Shared widgets
│   └── region/         # Region selection components
└── screens/
    ├── home/           # Main dashboard
    │   └── widgets/    # Home-specific widgets (ActionCard, etc.)
    ├── phone_fixer/    # Fixer flow (Swipe UI)
    │   ├── dialogs/    # Edit dialogs
    │   ├── utils/      # Sorters and helpers
    │   └── widgets/    # Cards, toolbars, chips
    └── contacts_preview/ # List of identified issues
```

## Key Features

- **Google Sign-In**: Securely access your contacts.
- **Smart Formatting**: Uses `libphonenumber` (via backend) to standardize numbers to E.164.
- **Swipe Interface**: Easily Accept/Reject changes with a Tinder-like interface.
- **Region Detection**: Automatically suggests default region based on contact analysis.
- **Batch Processing**: Fix all contacts with one tap.

## Development

Run the app:
```bash
flutter run
```

## Dependencies
- `flutter_card_swiper`: For the swipe interface.
- `provider`: State management.
- `google_sign_in`: Authentication.
