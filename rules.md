# Amma Nanna App — Cursor / AI Coding Rules
# Place this file at the root of the project as `.cursorrules`

## Project identity
This is a Flutter (Dart) Android app for Telugu-speaking elderly users.
Two features only: Save Contact (voice + manual) and Share Photo via WhatsApp.
The entire UI is in Telugu script. Every decision prioritises simplicity and reliability.

---

## Non-negotiable rules

### Rule 1 — Never break existing working screens
Before touching any screen file, read the entire file first.
When editing a widget, verify that the parent widget still compiles.
Never remove a named route that is referenced elsewhere in the router.
If you are unsure where a widget is used, run `grep -r "WidgetName" lib/` first.

### Rule 2 — One screen = one file, one responsibility
Each screen lives in `lib/screens/<feature>/<screen_name>_screen.dart`.
Screens contain ONLY widget build logic.
Business logic lives in `lib/services/`.
Data models live in `lib/models/`.
Reusable widgets live in `lib/widgets/`.
Never mix service calls directly into a build() method.

### Rule 3 — No hardcoded strings in widget files
Every user-visible string must come from `lib/l10n/te.arb`.
Access strings via `AppLocalizations.of(context)!.keyName`.
Never write Telugu text directly in a Dart file. Not even in a comment that becomes a label.

### Rule 4 — Minimum touch target is 56dp
Every `GestureDetector`, `InkWell`, `ElevatedButton`, `TextButton` must have a
minimum size of `Size(56, 56)` enforced via `minimumSize` in `ButtonStyle` or
by wrapping in a `SizedBox` with `constraints: BoxConstraints(minHeight: 56, minWidth: 56)`.
The microphone button must be exactly 96dp diameter. Never smaller.

### Rule 5 — Minimum font size is 18sp
No `TextStyle` anywhere in the app may have `fontSize` below 18.
Primary labels: 28sp. Button text: 24sp. Section headers: 22sp.
Secondary / hint text: 18sp. Absolutely nothing smaller.
Telugu script needs breathing room — use lineHeight 1.5 minimum.

### Rule 6 — Font must always be Noto Sans Telugu
Every `TextStyle` must explicitly set `fontFamily: 'NotoSansTelugu'`.
Do NOT rely on the system fallback — budget Android devices often have
incomplete Telugu support. The font is bundled in `assets/fonts/`.
`pubspec.yaml` must declare it. Never remove the font declaration.

### Rule 7 — Never make network calls in build()
All async operations (contacts, gallery, speech) go through the service layer.
Use `FutureBuilder` or state management (setState / ValueNotifier) to reflect results.
A `build()` method must be synchronous and free of await/then chains.

### Rule 8 — Every permission must be explained in Telugu before requesting
Never call `Permission.request()` without first showing the explanation widget:
`PermissionExplanationWidget(messageKey: 'permissionXExplanation')`.
This is in `lib/widgets/permission_explanation_widget.dart`.
Never delete this widget. Never skip it.

### Rule 9 — WhatsApp sharing uses FileProvider, not raw file paths
Always copy the selected photo to the app cache directory before sharing.
Always use `FileProvider.getUriForFile()` to get the shareable URI.
Never pass a raw `/storage/emulated/...` path to the intent — it will fail on Android 10+.
The FileProvider authority is `com.ammananna.app.fileprovider` — never change this string.
It must match `AndroidManifest.xml` exactly.

### Rule 10 — Speech service handles all three states
The `SpeechService` in `lib/services/speech_service.dart` must always expose:
- `SpeechState.idle` — not listening, no result
- `SpeechState.listening` — actively capturing audio
- `SpeechState.result` — recognized text available
Never add a fourth state without updating all switch statements that consume it.
Always use `localeId: 'te_IN'` when calling `speechToText.listen()`. Never change this.

### Rule 11 — Contacts are always read from device, never cached in-app
Do not maintain an internal contacts list in shared_preferences or SQLite.
Always read from `FlutterContacts.getContacts()` fresh on each screen load.
The only local persistence in this app is app state (which screen was last open).

### Rule 12 — Color tokens must come from AppColors, never hardcoded
All colors are defined in `lib/theme/app_colors.dart` as static constants.
Never write `Color(0xFFC17B3F)` inside a widget file.
Always write `AppColors.primary`.
The color palette: primary #C17B3F, primaryDark #8F5A28, primaryLight #F5E6D3,
surface #FDFAF6, surfaceCard #FFFFFF, surfaceMuted #F0EBE3,
textPrimary #1C1208, textSecondary #6B5744, success #4A7C59,
successLight #E8F3EC, divider #E5DDD3.
These colors are final. Do not add new colors without updating this file and this rule.

### Rule 13 — Navigation uses named routes only
All navigation calls must use `Navigator.pushNamed(context, AppRoutes.routeName)`.
Never use `Navigator.push(context, MaterialPageRoute(...))` directly.
All routes are declared in `lib/app.dart` in the `routes` map.
Route constants are in `lib/routes.dart` as static const strings.
Adding a new screen requires: (1) add route constant, (2) add to routes map, (3) add screen file.

### Rule 14 — Error states must show Telugu text, never crash
Every try/catch block must update UI state to show a Telugu error message.
Never allow an unhandled exception to show a Flutter red error screen to the user.
Wrap all service calls in try/catch. Log the error with `debugPrint()` for developer visibility.
The fallback message key is `'generalErrorMessage'` in `te.arb`.

### Rule 15 — The success screen auto-dismisses after 2500ms
`SaveContactSuccessScreen` uses a `Timer(Duration(milliseconds: 2500), ...)` to
navigate back to home. This timer must be cancelled in `dispose()`. Never remove the
`dispose()` override. Never change the duration without updating this rule.

### Rule 16 — The numeric keypad is custom, never the system keyboard
`NumberEntryScreen` uses `lib/widgets/numeric_keypad.dart`.
Never replace it with a `TextField` with `keyboardType: TextInputType.number`.
The custom keypad shows digits 1–9, then 0, then backspace. No letters. No symbols.
Button size: 72dp × 72dp circular buttons.

### Rule 17 — Gallery shows 2 columns, most recent first, no albums
`GalleryScreen` uses `photo_manager` to load assets sorted by creation time descending.
Grid: `crossAxisCount: 2`, `mainAxisSpacing: 4`, `crossAxisSpacing: 4`.
No album selector. No folder navigation. Flat chronological list only.
Load in batches of 50 (`page: 0, size: 50`). Add a load-more trigger at bottom.

### Rule 18 — Contact list is alphabetically sorted in Telugu
`ContactPickerScreen` sorts contacts using `Collator` with `te` locale via the
`intl` package. Never sort by Unicode code point — that gives wrong Telugu order.
Contacts with phone numbers only. Skip contacts with no phone number silently.

### Rule 19 — The app targets Android only
Never add iOS-specific code paths, `Platform.isIOS` checks, or Podfile entries.
`minSdkVersion` is 26. `targetSdkVersion` is 34. `compileSdkVersion` is 34.
Never lower `minSdkVersion` below 26 — required for FileProvider URI behavior.

### Rule 20 — pubspec.yaml is the source of truth for dependencies
Never import a package that is not declared in `pubspec.yaml` dependencies.
Never remove a package from `pubspec.yaml` without first confirming it has zero imports.
Run `dart pub deps` to check before removing. Approved packages only:
```
flutter_contacts: ^1.1.7
speech_to_text: ^6.6.0
photo_manager: ^3.3.0
url_launcher: ^6.2.5
share_plus: ^9.0.0
permission_handler: ^11.3.0
google_fonts: ^6.2.1
material_symbols_icons: ^4.2719.1
flutter_image_compress: ^2.2.0
shared_preferences: ^2.2.3
intl: ^0.19.0
```
Do not upgrade major versions without explicit instruction.

---

## Code style

### Dart
- Use `const` constructors wherever possible. It matters for rebuild performance.
- Prefer `final` over `var` for all local variables that don't reassign.
- Use `async/await` over `.then()` chains. Exception: `then()` inside `initState` is acceptable.
- Always null-check with `??` or `?.` before accessing nullable fields.
- Never use `!` force-unwrap on a nullable that could reasonably be null at runtime.
- Each Dart file has a single public class. Private helpers are prefixed with `_`.
- `build()` methods should be under 80 lines. Extract sub-widgets if longer.

### Flutter widget structure
```dart
class MyScreen extends StatefulWidget {
  const MyScreen({super.key});
  @override
  State<MyScreen> createState() => _MyScreenState();
}

class _MyScreenState extends State<MyScreen> {
  // 1. Service instances
  // 2. State variables
  // 3. initState / dispose
  // 4. Private methods
  // 5. build()
}
```

### Naming
- Screens: `PascalCase` + `Screen` suffix — `VoiceNameScreen`
- Widgets: `PascalCase` + `Widget` suffix — `NumericKeypadWidget`
- Services: `PascalCase` + `Service` suffix — `SpeechService`
- Route constants: `lowerCamelCase` — `AppRoutes.voiceName`
- Color constants: `lowerCamelCase` — `AppColors.primaryLight`
- ARB keys: `lowerCamelCase` — `speakNameLabel`

---

## Files that must never be deleted

```
lib/l10n/te.arb                         — All Telugu strings
lib/theme/app_colors.dart               — Color tokens
lib/theme/app_text_styles.dart          — Text style tokens
lib/routes.dart                         — Route constants
lib/widgets/numeric_keypad.dart         — Custom number input
lib/widgets/permission_explanation_widget.dart
lib/services/speech_service.dart
lib/services/whatsapp_service.dart
android/app/src/main/res/xml/file_paths.xml   — FileProvider paths
android/app/src/main/AndroidManifest.xml
assets/fonts/NotoSansTelugu-Regular.ttf
assets/fonts/NotoSansTelugu-SemiBold.ttf
```

---

## AndroidManifest.xml rules

The following entries must always be present. Never remove them:

```xml
<uses-permission android:name="android.permission.READ_CONTACTS"/>
<uses-permission android:name="android.permission.WRITE_CONTACTS"/>
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE"
    android:maxSdkVersion="32"/>
<uses-permission android:name="android.permission.RECORD_AUDIO"/>

<provider
    android:name="androidx.core.content.FileProvider"
    android:authorities="com.ammananna.app.fileprovider"
    android:exported="false"
    android:grantUriPermissions="true">
  <meta-data
      android:name="android.support.FILE_PROVIDER_PATHS"
      android:resource="@xml/file_paths"/>
</provider>
```

The `android:authorities` value is `com.ammananna.app.fileprovider`.
It must match the string in `WhatsAppService` exactly.
If the package name ever changes, update both simultaneously.

---

## Testing requirements

Before marking any feature complete:

1. Run `flutter analyze` — zero warnings allowed, zero errors
2. Run `flutter test` — all tests pass
3. Test on a physical device (not emulator) with `te` locale set in Android settings
4. Verify Telugu text renders correctly (not boxes/squares) on the test device
5. Test voice recognition with a real Telugu name spoken aloud
6. Test WhatsApp sharing end-to-end — photo must arrive in WhatsApp chat

---

## When you are unsure

If a change might affect permission flows, WhatsApp intent construction,
FileProvider behavior, or Telugu font rendering — pause and ask before implementing.
These four areas are the highest-risk areas for silent failures that only show up on
a real device in a real Telugu-language environment.

When in doubt, do less. A working subset is always better than a broken whole.
This app is for someone's father. It must work perfectly.
