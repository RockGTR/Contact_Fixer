# Frontend Documentation

## Overview
Flutter mobile app for contact phone number standardization with Tinder-style swipe interface.

## Key Features

### Phone Fixer Screen
Two view modes (toggle via app bar icon):

**Swipe View (Default)**
- ➡️ **Right swipe** = Accept fix
- ⬅️ **Left swipe** = Skip/Reject
- ⬆️ **Up swipe** = Edit manually
- Centered cards with swipe indicators

**List View**
- Scrollable list of all contacts
- Action buttons (✗ ✎ ✓) per row

### Visual Features
- **Alphabet-based colors** - Avatar colors vary A-Z (red→green→blue→purple)
- **Progress tracking** - Shows ✓ accepts, ✗ rejects, ✎ edits, N left

### Pending Changes Review
- Summary counts
- Undo individual changes
- "Sync Changes" batch update
- **Fix All**: Batch accept all current suggestions via AppBar icon.
- **Delete All**: Clear all pending staged changes via trash icon in Pending screen.
- **Search & Sort**: Filter/order pending changes

### Search & Sort
- **Search**: Toggleable search bar in AppBar (filters Name/Phone).
- **Sort**: Sort by Name, Phone, Last Modified, or Date Added (Pending Changes only) via AppBar menu. Includes explicit **Ascending / Descending** controls.
- Default from device locale
- Suggestions based on contact counts

### User Interface
- **Default View**: Standard List View for quick scanning.
- **Swipe View**: "Tinder-style" card interface for rapid processing.
- **Switching**: Use the 'Try It' banner or the View Toggle icon in the AppBar.

### Data Editing
- **Manual Region Selection**: Change the contact's country region directly in the edit dialog with a visual flag selector.
- **Smart Phone Input**: Phone extension/dial code is separated from the number for better readability and auto-updates when region changes.
- **Uniform Experience**: Advanced editing features (Region Selector, Split Input, Name Field) are available in both the main fix screen and the Pending Changes review screen.
- **Control Toolbar**: Access "Fix All", "Sort", and "View Toggle" from the dedicated toolbar below the header.

## Project Structure
```
frontend/lib/
├── main.dart
├── models/country.dart
├── services/api_service.dart
├── providers/
│   ├── auth_provider.dart
│   ├── contacts_provider.dart
│   └── settings_provider.dart
├── widgets/region_selector.dart
└── screens/
    ├── login_screen.dart
    ├── home_screen.dart
    └── phone_fixer_screen.dart  # Swipe + List views
```

## Running
```bash
cd frontend && flutter pub get && flutter run
```
