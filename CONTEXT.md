# Amma Nanna App — Project Context
# Read this file completely before touching any code in this project.
# Last updated: May 2026

---

## Why this app exists

An elderly Telugu-speaking father cannot read English. He uses WhatsApp daily but
struggles with two tasks that require navigating English menus:
  1. Saving a new phone number as a contact
  2. Sharing a photo with someone on WhatsApp

This app removes every barrier between him and those two tasks.
It speaks his language — literally. The entire UI is in Telugu script.
It replaces multi-step flows with single large buttons.
It replaces English keyboard typing with voice recognition in Telugu.

This is not a side project. This is built with love, for a real person.
Every decision must ask: "Would this confuse a 65-year-old who cannot read English?"
If yes, simplify it.

---

## The two features. Only two. Nothing else.

### Feature 1 — పరిచయం సేవ్ చేయి (Save a Contact)
User opens app → taps Save Contact card → enters phone number on custom keypad →
taps mic button → speaks name in Telugu → confirms → taps Save → done.
Fallback: if voice fails, user can open system Telugu keyboard to type the name.

### Feature 2 — ఫోటో పంపించు (Share a Photo on WhatsApp)
User opens app → taps Share Photo card → sees gallery (most recent first, 2 columns) →
taps a photo → confirms → picks a contact from list → WhatsApp opens with photo
pre-attached to that contact's chat → user taps WhatsApp's send button.

That is the entire app. There is no Feature 3.
If you are considering adding anything else, stop and re-read this section.

---

## Target user — read this before every UI decision

Name: నాన్న (Nanna, meaning "Father")
Age: 60–75
Location: Andhra Pradesh or Telangana, India
Device: Budget Android (Redmi, Realme, Samsung A-series) — 2–3GB RAM
Language: Telugu only. Cannot read English. Cannot type English.
WhatsApp comfort: High — uses it daily for voice calls and receiving photos
Tech comfort: Low for anything requiring menus or text
Vision: May have mild presbyopia — assume reduced close-up vision
Motor: May have mild tremor — assume reduced fine motor precision

Design implications:
- Minimum font size 18sp, primary labels 28sp
- Minimum touch target 56dp × 56dp
- Maximum 1 action per screen
- Zero English text visible at any time
- Confirmation before any irreversible action
- Success states must be visually obvious (large ✓, Telugu text, color change)

---

## Project structure — where everything lives

```
amma_nanna_app/
├── .cursorrules                          ← AI coding rules (read before every session)
├── CONTEXT.md                            ← This file
├── pubspec.yaml
├── android/
│   └── app/src/main/
│       ├── AndroidManifest.xml           ← Permissions + FileProvider declaration
│       └── res/xml/file_paths.xml        ← FileProvider paths config
├── assets/
│   └── fonts/
│       ├── NotoSansTelugu-Regular.ttf    ← MUST be bundled — system fonts unreliable
│       └── NotoSansTelugu-SemiBold.ttf
└── lib/
    ├── main.dart                         ← Entry point, initializes app
    ├── app.dart                          ← MaterialApp, theme, routes map
    ├── routes.dart                       ← All route name constants
    ├── theme/
    │   ├── app_colors.dart               ← Single source of truth for all colors
    │   ├── app_text_styles.dart          ← Single source of truth for all text styles
    │   └── app_theme.dart               ← ThemeData built from colors + text styles
    ├── l10n/
    │   └── te.arb                        ← ALL user-visible Telugu strings
    ├── models/
    │   ├── contact_model.dart            ← {name, phone, avatarColor}
    │   └── photo_model.dart             ← {assetEntity, thumbnailData, dateCreated}
    ├── services/
    │   ├── speech_service.dart           ← Google on-device STT, te_IN locale
    │   ├── contacts_service.dart         ← Read/write device contacts
    │   ├── media_service.dart            ← Gallery access via photo_manager
    │   └── whatsapp_service.dart         ← FileProvider + Intent construction
    ├── screens/
    │   ├── home/
    │   │   └── home_screen.dart
    │   ├── save_contact/
    │   │   ├── number_entry_screen.dart
    │   │   ├── voice_name_screen.dart
    │   │   ├── confirm_contact_screen.dart
    │   │   └── success_screen.dart
    │   └── share_photo/
    │       ├── gallery_screen.dart
    │       ├── photo_confirm_screen.dart
    │       └── contact_picker_screen.dart
    └── widgets/
        ├── large_button.dart             ← Primary CTA button, full-width, 72dp height
        ├── numeric_keypad.dart           ← Custom 72dp circular digit buttons
        ├── avatar_circle.dart            ← 48dp contact initial circle
        ├── contact_list_tile.dart        ← 72dp list item for contact picker
        ├── photo_grid.dart               ← 2-column async gallery grid
        ├── mic_button.dart               ← 96dp pulsing circle mic
        ├── waveform_animation.dart       ← Animated listening state indicator
        └── permission_explanation_widget.dart  ← Telugu explanation before any permission
```

---

## Route map — all named routes

```dart
// lib/routes.dart
class AppRoutes {
  static const home             = '/';
  static const numberEntry      = '/save/number';
  static const voiceName        = '/save/voice';
  static const confirmContact   = '/save/confirm';
  static const saveSuccess      = '/save/success';
  static const gallery          = '/share/gallery';
  static const photoConfirm     = '/share/confirm';
  static const contactPicker    = '/share/contacts';
}
```

Navigation flow:
```
home → numberEntry → voiceName → confirmContact → saveSuccess → home (auto 2500ms)
home → gallery → photoConfirm → contactPicker → [WhatsApp opens] → home
```

Arguments passed between screens:
- `numberEntry` → `voiceName`: `String phoneNumber`
- `voiceName` → `confirmContact`: `String phoneNumber, String name`
- `confirmContact` → `saveSuccess`: `String phoneNumber, String name`
- `gallery` → `photoConfirm`: `AssetEntity photo`
- `photoConfirm` → `contactPicker`: `File cachedPhotoFile`
- `contactPicker` → WhatsApp: launches intent, no return value

---

## Color system — AppColors

All colors are warm amber-brown. No blues. No standard "app" colors.
Cultural palette: turmeric, sandalwood, terracotta.

```dart
// lib/theme/app_colors.dart
class AppColors {
  static const primary       = Color(0xFFC17B3F); // Warm amber — main CTA, icons
  static const primaryDark   = Color(0xFF8F5A28); // Pressed states, active borders
  static const primaryLight  = Color(0xFFF5E6D3); // Ghost button bg, card tint
  static const surface       = Color(0xFFFDFAF6); // Screen background — warm off-white
  static const surfaceCard   = Color(0xFFFFFFFF); // Card backgrounds
  static const surfaceMuted  = Color(0xFFF0EBE3); // Input bg, inactive items, keypad buttons
  static const textPrimary   = Color(0xFF1C1208); // All body text, names, labels
  static const textSecondary = Color(0xFF6B5744); // Hints, placeholders, subtitles
  static const success       = Color(0xFF4A7C59); // Confirmation states
  static const successLight  = Color(0xFFE8F3EC); // Success screen background tint
  static const divider       = Color(0xFFE5DDD3); // Separator lines, borders
}
```

---

## Typography system — AppTextStyles

Font: Noto Sans Telugu (bundled). This is non-negotiable.
The system Telugu font on budget devices is often incomplete — users see squares.

```dart
// lib/theme/app_text_styles.dart
class AppTextStyles {
  static const _base = TextStyle(fontFamily: 'NotoSansTelugu', color: AppColors.textPrimary);

  static final primaryLabel  = _base.copyWith(fontSize: 28, fontWeight: FontWeight.w600);
  static final buttonText    = _base.copyWith(fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white);
  static final sectionHeader = _base.copyWith(fontSize: 22, fontWeight: FontWeight.w500);
  static final bodyText      = _base.copyWith(fontSize: 20, fontWeight: FontWeight.w400, height: 1.5);
  static final secondaryText = _base.copyWith(fontSize: 18, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static final hintText      = _base.copyWith(fontSize: 18, fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static final keypadDigit   = _base.copyWith(fontSize: 32, fontWeight: FontWeight.w600);
  static final numberDisplay = _base.copyWith(fontSize: 40, fontWeight: FontWeight.w700, letterSpacing: 4);
  static final confirmedName = _base.copyWith(fontSize: 32, fontWeight: FontWeight.w700);
  static final successHeading= _base.copyWith(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.success);
  static final appName       = _base.copyWith(fontSize: 26, fontWeight: FontWeight.w700);
}
```

Nothing below 18sp. Ever. This is a hard constraint, not a guideline.

---

## Service layer — what each service does and doesn't do

### SpeechService (lib/services/speech_service.dart)
Does:
- Initializes Google on-device STT with `localeId: 'te_IN'`
- Exposes `SpeechState` enum: idle | listening | result | error
- Exposes `currentResult` String (partial and final results)
- Detects if Telugu language pack is available; exposes `bool isTeluguAvailable`
- Configures `pauseFor: Duration(seconds: 2)` for natural speech pauses
- Configures `listenFor: Duration(seconds: 10)` maximum listen window

Does NOT:
- Make any network calls
- Store results to disk
- Handle UI state

### ContactsService (lib/services/contacts_service.dart)
Does:
- `Future<List<ContactModel>> getContacts()` — reads all device contacts with phone numbers
- `Future<bool> saveContact(String name, String phone)` — writes to device contacts
- Sorts result using `intl` package Collator with `te` locale
- Filters out contacts with no phone number

Does NOT:
- Cache contacts in memory or disk
- Filter by WhatsApp status (that check is not reliable via Flutter)
- Store any state between calls

### MediaService (lib/services/media_service.dart)
Does:
- `Future<List<AssetEntity>> getRecentPhotos({int page, int size})` — returns photos sorted by creation time descending
- `Future<File> copyToCache(AssetEntity asset)` — copies photo to app cache dir for FileProvider use
- Handles `READ_MEDIA_IMAGES` on API 33+ and `READ_EXTERNAL_STORAGE` on older APIs

Does NOT:
- Compress images (that's WhatsAppService's job before sharing)
- Manage albums or folders
- Return videos

### WhatsAppService (lib/services/whatsapp_service.dart)
Does:
- `Future<void> sharePhoto(File photo, String phoneNumber)` — the main method
- Compresses photo to ≤5MB using `flutter_image_compress` before sharing
- Creates FileProvider URI: authority = `com.ammananna.app.fileprovider`
- Constructs `ACTION_SEND` Intent targeting `com.whatsapp` package
- Falls back to `com.whatsapp.w4b` (WhatsApp Business) if main WhatsApp not installed
- If neither installed, throws `WhatsAppNotInstalledException`

Does NOT:
- Use WhatsApp API (not needed — native Android Intent is sufficient and free)
- Send messages (photos only)
- Track delivery status

---

## Models

### ContactModel
```dart
class ContactModel {
  final String id;        // device contact ID
  final String name;      // as stored on device (may be Telugu or any script)
  final String phone;     // normalized: digits only, with country code if available
  final Color avatarColor; // deterministic from name hash, warm palette only
}
```

### PhotoModel
```dart
class PhotoModel {
  final AssetEntity asset;
  final Uint8List thumbnailData;  // 200×200 pre-loaded thumbnail
  final DateTime dateCreated;
}
```

---

## Key technical decisions and why they were made

### Why FileProvider instead of direct path sharing?
Android 7+ (API 24+) blocks sharing raw `file://` URIs across app boundaries.
FileProvider creates a temporary permission-granted `content://` URI.
Without it, WhatsApp receives the Intent but cannot read the file — silent failure.

### Why on-device STT instead of a cloud API?
1. No API key needed — completely free
2. Works without internet (once `te_IN` language pack is downloaded)
3. Faster — no round-trip latency
4. Privacy — no audio leaves the device
The `speech_to_text` Flutter plugin wraps Android's `SpeechRecognizer` API directly.

### Why custom numeric keypad instead of system keyboard?
The system numeric keyboard on Android includes letters and symbols that confuse
elderly users. Our keypad shows exactly 10 digits + backspace. Nothing else.
Touch targets are 72dp circles — twice the minimum — because dialing confidence matters.

### Why Noto Sans Telugu bundled instead of system font?
Redmi and Realme devices (most common budget Android in India) ship with MIUI/realmeUI
which sometimes has incomplete Telugu Unicode ranges. Characters in certain conjunct
ranges render as boxes. Bundling the complete Google Noto Sans Telugu guarantees
correct rendering on every device we care about.

### Why contacts are read fresh every time?
Contact data can change between app sessions (user may have saved new contacts
outside this app, contacts may have been deleted). Stale cached data would show
wrong or missing contacts. The penalty of a fresh read (~200ms for 500 contacts)
is invisible to the user and the correctness guarantee is worth it.

### Why no search bar in contact picker (Phase 1)?
Searching requires typing, which requires a keyboard, which requires English literacy
for the input mechanism. The contact list is sorted in Telugu alphabetical order.
For a person with ~20-50 contacts (typical elderly user), scrolling is faster and
more reliable than searching. Search is Phase 2 with voice search.

---

## Permissions — what each one is for

| Permission | Why needed | When requested |
|---|---|---|
| READ_CONTACTS | Display contact list in photo sharing picker | First time Share Photo is opened |
| WRITE_CONTACTS | Save new contact to device | First time Save Contact is used |
| READ_MEDIA_IMAGES | Display gallery of photos | First time Share Photo is opened |
| READ_EXTERNAL_STORAGE (API ≤ 32) | Same as above, older Android API | Same as above |
| RECORD_AUDIO | Microphone for voice name input | First time Voice Name screen is opened |

Every permission is preceded by `PermissionExplanationWidget` showing a Telugu
sentence explaining why the permission is needed. This is not optional UX polish —
elderly users who see an unexpected system dialog without context will tap "Deny"
and the feature will stop working.

---

## Localization — te.arb key inventory

All keys used in the app. If you add a new screen, add keys here first.

```json
{
  "appName": "EasySave",
  "appTagline": "మీ సహాయకుడు",
  "saveContactLabel": "పరిచయం సేవ్ చేయి",
  "saveContactSub": "కొత్త నంబర్ సేవ్ చేయడానికి",
  "sharePhotoLabel": "ఫోటో పంపించు",
  "sharePhotoSub": "WhatsApp లో ఫోటో పంపించడానికి",
  "enterNumber": "నంబర్ ఎంటర్ చేయండి",
  "nextButton": "తర్వాత",
  "speakName": "పేరు చెప్పండి",
  "pressMicPrompt": "పై బటన్ నొక్కి పేరు చెప్పండి",
  "listeningLabel": "వింటున్నాను...",
  "isCorrectQuestion": "ఇది సరైనదేనా?",
  "yesButton": "అవును",
  "tryAgainButton": "మళ్ళీ చెప్పండి",
  "typeWithKeyboard": "కీబోర్డ్ తో టైప్ చేయండి",
  "confirmLabel": "నిర్ధారించు",
  "saveButton": "సేవ్ చేయి",
  "savedSuccess": "సేవ్ అయింది!",
  "backButton": "వెనక్కి",
  "goHome": "హోమ్ కి వెళ్ళు",
  "choosePhoto": "ఫోటో ఎంచుకోండి",
  "recentPhotos": "ఇటీవలి ఫోటోలు",
  "sendThisPhoto": "ఈ ఫోటో పంపించు",
  "whoToSend": "ఎవరికి పంపించాలి?",
  "whatsappWillSend": "WhatsApp లో పంపించబడుతుంది",
  "whatsappNotInstalled": "WhatsApp ఇన్స్టాల్ అయిలేదు",
  "installWhatsapp": "WhatsApp ఇన్స్టాల్ చేయండి",
  "saveContactFirst": "ముందు పరిచయం సేవ్ చేయండి",
  "noPhotosFound": "ఫోటోలు కనుగొనబడలేదు",
  "generalErrorMessage": "తప్పు జరిగింది, మళ్ళీ ప్రయత్నించండి",
  "speechNotRecognized": "అర్థం కాలేదు, మళ్ళీ చెప్పండి",
  "permissionContactsExplanation": "మీ పరిచయాలు చదవడానికి అనుమతి అడుగుతున్నాం",
  "permissionWriteExplanation": "పరిచయం సేవ్ చేయడానికి అనుమతి అడుగుతున్నాం",
  "permissionPhotosExplanation": "ఫోటోలు చూడటానికి అనుమతి అడుగుతున్నాం",
  "permissionMicExplanation": "మీ పేరు వినడానికి మైక్ అనుమతి అడుగుతున్నాం",
  "permissionDeniedMessage": "అనుమతి లేకుండా ఈ పని చేయడం సాధ్యం కాదు",
  "openSettings": "సెట్టింగ్స్ తెరవండి",
  "teluguSpeechMissing": "తెలుగు వాయిస్ ప్యాక్ డౌన్లోడ్ చేయండి"
}
```

---

## Third-party packages — approved list only

Do not add packages not on this list without explicit instruction.

```yaml
dependencies:
  flutter:
    sdk: flutter
  flutter_localizations:
    sdk: flutter

  # Core features
  speech_to_text: ^6.6.0          # On-device Telugu STT
  flutter_contacts: ^1.1.7        # Read/write device contacts
  photo_manager: ^3.3.0           # Gallery access
  flutter_image_compress: ^2.2.0  # Compress before WhatsApp share

  # Sharing / intents
  url_launcher: ^6.2.5            # Open WhatsApp deep links
  share_plus: ^9.0.0              # Fallback sharing mechanism

  # Permissions
  permission_handler: ^11.3.0

  # Fonts / icons
  google_fonts: ^6.2.1            # Noto Sans Telugu
  material_symbols_icons: ^4.2719.1

  # Utilities
  shared_preferences: ^2.2.3      # App state only (not contacts/photos)
  intl: ^0.19.0                   # Telugu collation for contact sort
```

---

## Android configuration — critical values

Package name: `com.ammananna.app`
Application ID: `com.ammananna.app`
FileProvider authority: `com.ammananna.app.fileprovider`  ← must match EXACTLY in both AndroidManifest.xml and WhatsAppService.dart
minSdkVersion: 26  ← never lower this
targetSdkVersion: 34
compileSdkVersion: 34

If the package name ever changes, the FileProvider authority string must be
updated in both places simultaneously or WhatsApp sharing will silently break.

---

## What Phase 1 does NOT include (and why)

| Excluded feature | Reason |
|---|---|
| iOS support | Target users are on Android. Not needed. |
| Contact editing/deletion | Adds complexity and risk of data loss. Phase 2. |
| Voice search in contact picker | Typing isn't used, but voice search adds STT dependency to this screen. Phase 2. |
| Cloud backup | Requires Google Sign-In flow which is confusing. Phase 2. |
| Multiple languages | Telugu first, prove it works. Other languages Phase 3. |
| Share video | WhatsApp video sharing is more complex (size limits, formats). Phase 2. |
| Contact photos | Not critical for functionality. Phase 2. |
| Dark mode | Target devices are used in daylight. Warm light palette optimized for this. Phase 2. |
| Tablet layout | Target users have phones. Phase 2. |
| Notification of any kind | No notifications needed for this app's purpose. Never. |

---

## Known edge cases and how to handle them

| Situation | How the app handles it |
|---|---|
| Voice not recognized | Show "అర్థం కాలేదు, మళ్ళీ చెప్పండి". Allow 3 retries before offering keyboard fallback. |
| Telugu speech pack not installed | Detect on app launch. Show `teluguSpeechMissing` with link to Android language settings. |
| WhatsApp not installed | Show `whatsappNotInstalled` error + `installWhatsapp` button opening Play Store. |
| WhatsApp Business installed instead | `WhatsAppService` checks for `com.whatsapp.w4b` as fallback after `com.whatsapp`. |
| Both WhatsApp variants installed | Show a simple Telugu picker: "WhatsApp" or "WhatsApp Business". |
| Photo file too large (>5MB) | `flutter_image_compress` reduces quality before sharing. Target ≤5MB. |
| No photos on device | `GalleryScreen` shows empty state with `noPhotosFound` message. |
| No contacts saved | `ContactPickerScreen` shows empty state with link to Save Contact flow. |
| Contact has no phone number | Silently excluded from contact picker list. |
| Permission permanently denied | Show `permissionDeniedMessage` + `openSettings` button. |
| Phone call received mid-flow | Flutter lifecycle handles this. `voiceName` screen pauses STT in `onPause`. |
| App killed mid-flow | No persistent state mid-flow by design — user restarts from home. |

---

## Success definition

The app succeeds when:
  1. Father can save a new contact unassisted in under 10 seconds
  2. Father can share a photo to a specific WhatsApp contact in 3 taps or fewer
  3. Father smiles when he uses it

Number 3 is not a joke. It is the actual success criterion.
Every technical decision in this file exists in service of that smile.
