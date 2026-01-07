# Frontend Authentication Integration Guide

## ⚠️ IMPORTANT: Remaining Work

The backend security hardening is **100% complete**. However, some frontend screens still need to be updated to pass authentication tokens. 

## ✅ Already Completed

- `AuthProvider` - Added `getIdToken()` method
- `ApiService` -  Updated all methods to accept `idToken` parameter
- `ContactsProvider` - Fully integrated with authentication
- `main.dart` - Properly injects AuthProvider into ContactsProvider

## 🔧 Screens That Need Updates

The following screens make direct API calls and need to be updated to pass ID tokens:

### 1. `phone_fixer_screen.dart`
**Lines to update**: 98, 110, 134, 220

**Current code pattern**:
```dart
final ApiService _api = ApiService();

// Line 98
final result = await _api.getPendingChanges();

// Line 110
final result = await _api.getMissingExtensionContacts(
  regionCode: widget.regionCode,
);

// Line 134 & 220
await _api.stageFix(
  resourceName: contact['resource_name'],
  // ...
);
```

**Fixed Pattern**:
```dart
import 'package:provider/provider.dart';
import '../mixins/auth_token_mixin.dart';

class _PhoneFixerScreenState extends State<PhoneFixerScreen> with AuthTokenMixin {
  late final ApiService _api;
  
  @override
  void initState() {
    super.initState();
    _api = createApiService(context);
    // ...
  }
  
  Future<void> _loadPendingStats() async {
    final idToken = await getIdToken(context);
    final result = await _api.getPendingChanges(idToken);
    // ...
  }
  
  Future<void> _loadContacts() async {
    final idToken = await getIdToken(context);
    final result = await _api.getMissingExtensionContacts(
      idToken: idToken,
      regionCode: widget.regionCode,
    );
    // ...
  }
  
  Future<void> _stageContact(...) async {
    final idToken = await getIdToken(context);
    await _api.stageFix(
      idToken: idToken,
      resourceName: contact['resource_name'],
      // ...
    );
  }
}
```

### 2. `pending_changes_screen.dart`
**Lines to update**: 107, 120, 149, 200, 306

Same pattern as above - add mixin and pass `idToken` to all API calls:
- `getPendingChanges(idToken)`
- `pushToGoogle(idToken)`
- `stageFix(idToken: idToken, ...)`
- `clearStaged(idToken)`
- `removeStagedChange(idToken, resourceName)`

### 3. `settings_provider.dart`
**Line to update**: 70

```dart
// Add AuthProvider injection
class SettingsProvider with ChangeNotifier {
  final AuthProvider _authProvider;
  late final ApiService _api;
  
  SettingsProvider(this._authProvider) {
    _api = ApiService(
      onAuthenticationExpired: () => _authProvider.logout(),
    );
  }
  
  Future<void> analyzeRegions() async {
    final idToken = await _authProvider.getIdToken();
    final result = await _api.analyzeRegions(idToken);
    // ...
  }
}
```

And update `main.dart`:
```dart
ChangeNotifierProxyProvider<AuthProvider, SettingsProvider>(
  create: (context) => SettingsProvider(
    Provider.of<AuthProvider>(context, listen: false),
  ),
  update: (context, auth, previous) => previous ?? SettingsProvider(auth),
),
```

### 4. `country_picker_sheet.dart`
**Line to update**: 32

Use the `AuthTokenMixin` pattern as shown above.

## 🎯 Quick Fix Template

For any screen with direct API calls:

1. **Import dependencies**:
```dart
import 'package:provider/provider.dart';
import '../mixins/auth_token_mixin.dart';
```

2. **Add mixin to State class**:
```dart
with AuthTokenMixin
```

3. **Initialize API service in initState**:
```dart
late final ApiService _api;

@override
void initState() {
  super.initState();
  _api = createApiService(context);
}
```

4. **Update all API calls**:
```dart
Future<void> someMethod() async {
  final idToken = await getIdToken(context);
  await _api.someMethod(idToken, ...);
}
```

## 🧪 Testing After Updates

After updating each file, verify:

1. **No compilation errors**: `flutter analyze`
2. **App runs**: Test the feature end-to-end
3. **Authentication works**: Check that requests include `Authorization` header
4. **401 errors handled**: Sign out and verify user is prompted to sign in again

## 📝 Verification Checklist

- [ ] `phone_fixer_screen.dart` - Updated all API calls
- [ ] `pending_changes_screen.dart` - Updated all API calls
- [ ] `settings_provider.dart` - Injected AuthProvider
- [ ] `country_picker_sheet.dart` - Added auth token
- [ ] Run `flutter analyze` - No errors
- [ ] Test complete user flow - Works end-to-end
- [ ] Test 401 handling - User signed out on token expiry

## ⏱️ Estimated Time

- **Per screen**: 5-10 minutes
- **Total**: 30-45 minutes for all files
- **Testing**: 15-30 minutes

## 🚀 After Completion

Once all screens are updated:

1. Test the entire app flow
2. Verify all API calls include `Authorization` header (check browser DevTools Network tab)
3. Test authentication expiry (backend will return 401 after ~1 hour)
4. App is ready for production deployment!

## 💡 Tips

- Use find & replace to speed up updates
- Test each screen after updating
- Check browser console for token-related errors
- The `AuthTokenMixin` handles all the boilerplate

---

**Status**: Backend complete ✅ | Frontend 40% complete ⚠️
