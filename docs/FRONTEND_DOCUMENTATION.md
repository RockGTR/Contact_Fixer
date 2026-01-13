# Frontend Documentation

## Overview
Flutter mobile app for contact phone number standardization with Tinder-style swipe interface.

## Key Features

## Design System: Neumorphism (Soft UI)

The application now follows a **Neumorphic** design language, characterized by:

*   **Color Palette**:
    *   **Background**: Cool Grey (`0xFFE0E5EC`) - Use `Theme.of(context).scaffoldBackgroundColor`.
    *   **Text**: Dark Blue-Grey (`0xFF4b5563`) for primary text.
    *   **Accents**:
        *   Green (`0xFF10b981`) for Accept/Success.
        *   Red (`0xFFef4444`) for Reject/Skip.
        *   Blue (`0xFF667eea`) for Edit/Action.

*   **Core Components**:
    *   **`NeumorphicContainer`**: The fundamental building block. Supports `isPressed` state for concave (inset) or convex (extruded) shadow effects.
    *   **`NeumorphicButton`**: an interactive wrapper around `NeumorphicContainer` that animates on press.
    *   **`ContactCard`**: A complex composite widget using multiple neumorphic layers to display contact info elegantly.

### Key Layout Patterns

*   **Swipe View**: Uses `CardSwiper` within a centered, constrained box (max-width 600px) to ensure focus and prevent stretching on large screens.
*   **List View**: Standard list with neumorphic styling for items, automatically activated during search.
*   **Stats Bar**: A `Row` of `StatChip` widgets, evenly spaced to provide a quick summary of session progress.

## Screens

### 1. Phone Fixer Screen (`phone_fixer_screen.dart`)
The main workspace.
*   **State**: Manages `_contacts`, `_pendingStats`, and view modes (`Swipe` vs `List`).
*   **Logic**: Handles API calls, local state updates (optimistic UI), and rate limit tracking.
*   **Fixes**: Includes robust error handling for `setState` during build phases.

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

### Platform-Aware API Configuration
- **Automatic Platform Detection**: The `api_service.dart` automatically detects the platform and uses the correct base URL:
  - **Web (Chrome)**: `http://localhost:8000`
  - **Android Emulator**: `http://10.0.2.2:8000`
- **CORS Support**: The backend is configured to accept cross-origin requests from the web app running on `localhost:3000`.

### Web-Specific Configuration

**Authentication Method**: Legacy popup (FedCM disabled)
- FedCM is currently **disabled** (commented out in `index.html`)
- Reason: Compatibility issues with OAuth apps in Testing mode
- Uses traditional Google Sign-In popup window instead
- Location: `frontend/web/index.html`:
  ```html
  <!-- FedCM disabled temporarily -->
  <!-- <meta name="google-identity-fedcm-enabled" content="true"> -->
  ```

**When to Re-enable FedCM**:
- After publishing your OAuth app (not in Testing mode)
- Provides improved privacy and native browser authentication dialogs
- Required for Chrome 108+ in production

**Platform-Aware Settings**:
- Locale detection uses `kIsWeb` to handle web vs mobile differences
- Settings provider automatically adapts to platform capabilities
- Region suggestions work on both web and mobile platforms

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

**For Web Development**:
```bash
flutter run -d chrome --web-port=3000
```

> **Note**: The web app requires the backend to be running with CORS enabled. The backend automatically allows requests from `http://localhost:3000`.

---

**Last Updated**: 2026-01-13  
**Version**: 1.2.4
