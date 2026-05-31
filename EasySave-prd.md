# EasySave (Amma Nanna App) — Product Requirements Document

**Version:** 1.0  
**Date:** May 2026  
**Author:** Product Team  
**Platform:** Android (Flutter)  
**Target User:** Telugu-speaking elderly adults with limited English literacy

---

## 1. Executive Summary

Amma Nanna is a Telugu-first Android app that removes every barrier standing between an elderly parent and two of the most common smartphone actions — saving a contact and sharing a photo on WhatsApp. The entire interface is in Telugu script. Voice input replaces keyboard typing. Single large buttons replace multi-step flows. The app does two things, does them perfectly, and gets out of the way.

This document specifies the full product — scope, architecture, UX, screens, data model, technical stack, and launch plan — using only free and open-source tools.

---

## 2. Problem Statement

### 2.1 User Context

An elderly Telugu-speaking father uses an Android phone primarily for WhatsApp. He is functionally literate in Telugu but cannot read or type English. Two tasks cause him repeated frustration:

**Saving a contact:**  
The native Android contact-saving flow requires navigating English menus, typing a name via English keyboard, and confirming across multiple screens. He either asks for help every time or loses numbers entirely.

**Sharing a photo on WhatsApp:**  
Selecting the correct contact in WhatsApp, navigating to the gallery, choosing a photo, and confirming the send involves 6–9 taps across three different apps — each with English text and small touch targets.

### 2.2 The Cost of the Status Quo

Every failed attempt at these tasks is a moment of embarrassment and dependency. The goal is not just functionality — it is *dignity*. A person should be able to share a photo with their grandchild without asking for help.

---

## 3. Goals & Success Criteria

| Goal | Metric |
|------|--------|
| Save a contact in under 10 seconds | Time-to-complete task ≤ 10s in usability testing |
| Share a photo in under 3 taps | Tap count from app open to send ≤ 3 |
| Zero English text visible to user | 100% of UI strings in Telugu |
| Works on low-end Android devices | Tested on Android 8.0+, 2GB RAM, no internet required for core features |
| User can complete both tasks unassisted | 5/5 task completions in supervised testing with target persona |

---

## 4. Non-Goals (Explicit Out-of-Scope)

- iOS support (Android is the primary platform for the target demographic in India)
- Calling, messaging, or any WhatsApp feature beyond photo sharing
- Contact editing or deletion (Phase 2)
- Cloud backup or sync (Phase 2)
- Multiple language support beyond Telugu (Phase 2)

---

## 5. User Persona

**నాన్న (Nanna)**  
Age: 60–75 · Location: Andhra Pradesh or Telangana, India  
Device: Budget Android smartphone (Redmi, Realme, or Samsung A-series)  
WhatsApp usage: Daily — receives photos and videos from family  
Pain points: Cannot type English, screen text is too small, too many steps  
Motivations: Wants to share memories, stay connected with grandchildren  
Tech comfort: Comfortable with WhatsApp voice calls, basic photo gallery use

---

## 6. Core Feature Set

### Feature 1 — Contact Saver (పరిచయం సేవ్ చేయి)

**Flow:**
1. User taps the microphone button
2. Speaks the contact name in Telugu (e.g., "రవి కుమార్")
3. App displays the recognized name in large Telugu text for confirmation
4. User sees the phone number pre-filled (from incoming call or manual entry)
5. Single tap on "సేవ్ చేయి" (Save) button → contact saved to device

**Key requirements:**
- Voice recognition uses Google's on-device speech-to-text (free, supports Telugu)
- Recognized name shown in 28sp Telugu font before saving
- Fallback: if voice fails, user can type via Telugu keyboard (system keyboard)
- No English text at any point in the flow
- Contact saved to device contacts (not just app-internal) via Flutter Contacts plugin
- Success confirmation shown as large ✓ with Telugu text "సేవ్ అయింది!"

**Phone number input:**
- If app was opened from recent calls screen (Phase 2 integration), number is pre-filled
- Otherwise: large-digit numeric keypad (48sp digits, no letters) for manual entry
- No validation dialogs — if number is entered, save it

---

### Feature 2 — WhatsApp Photo Sharer (ఫోటో పంపించు)

**Flow:**
1. User taps "ఫోటో పంపించు" on home screen
2. Gallery opens — large thumbnails (2 per row), most recent first
3. User taps a photo — it shows full-screen with a single "ఈ ఫోటో పంపించు" (Send this photo) button
4. Contact picker opens — shows only saved contacts with Telugu names, large text, avatar initials
5. User taps a contact — WhatsApp opens directly to that chat with photo pre-attached
6. User taps WhatsApp's send button (the only non-app step — unavoidable)

**Key requirements:**
- Gallery uses device media store (no permission beyond READ_MEDIA_IMAGES)
- Contact list sourced from device contacts, filtered to those with WhatsApp
- WhatsApp deep link: `intent://send?phone=91XXXXXXXXXX&text=` with image attachment via FileProvider
- Contacts shown with large initial-circle avatars (48dp) + name in Telugu script
- If a contact has no Telugu name, it still appears (shown in whatever script was saved)
- No contact is hidden or filtered out based on app status

---

## 7. Screen Architecture

### 7.1 Screen Map

```
హోమ్ స్క్రీన్ (Home)
├── పరిచయం సేవ్ చేయి (Save Contact)
│   ├── నంబర్ ఎంటర్ చేయి (Enter Number)
│   ├── పేరు చెప్పండి (Speak Name) — Voice Input
│   ├── పేరు నిర్ధారించు (Confirm Name)
│   └── ✓ సేవ్ అయింది (Success)
└── ఫోటో పంపించు (Share Photo)
    ├── ఫోటో ఎంచుకోండి (Pick Photo — Gallery)
    ├── ఫోటో నిర్ధారించు (Confirm Photo)
    ├── ఎవరికి పంపించాలి? (Select Contact)
    └── WhatsApp opens (handoff)
```

### 7.2 Navigation

- No bottom nav bar, no tabs, no hamburger menu
- Every screen has a single large "వెనక్కి" (Back) arrow — top-left, 48dp touch target
- Home screen always reachable with one tap
- No deep navigation stacks — max 3 levels from home

---

## 8. UI & Visual Design Specification

### 8.1 Design Philosophy

**Large. Clear. Telugu. One thing per screen.**

Every decision serves a user with aging eyesight, no English, and low confidence with technology. Clutter is the enemy. Decoration is acceptable only when it aids understanding.

### 8.2 Color Palette

The palette moves away from standard "app" blues and greens toward warm, inviting tones that feel culturally familiar and premium without being corporate.

| Token | Value | Usage |
|-------|-------|-------|
| `primary` | `#C17B3F` | Main CTA buttons, active states, icon fills |
| `primary-dark` | `#8F5A28` | Button pressed state, active borders |
| `primary-light` | `#F5E6D3` | Button backgrounds (ghost), card tints |
| `surface` | `#FDFAF6` | Screen background — warm off-white |
| `surface-card` | `#FFFFFF` | Card background |
| `surface-muted` | `#F0EBE3` | Input backgrounds, inactive items |
| `text-primary` | `#1C1208` | All body text, names, labels |
| `text-secondary` | `#6B5744` | Hints, placeholder text |
| `success` | `#4A7C59` | Confirmation states |
| `success-light` | `#E8F3EC` | Success card backgrounds |
| `divider` | `#E5DDD3` | Separator lines, borders |

The palette is warm amber-brown — reminiscent of turmeric and sandalwood, approachable and non-technical. It avoids the cold blues of corporate apps and the aggressive greens of WhatsApp-clone territory.

### 8.3 Typography

- **Font:** Noto Sans Telugu (Google Fonts, free, excellent Telugu script rendering)
- **Body text:** 20sp minimum. No text below 18sp anywhere.
- **Primary labels/names:** 28sp, weight 600
- **Button text:** 24sp, weight 700
- **Section headers:** 22sp, weight 500
- **Hints/secondary:** 18sp, weight 400, `text-secondary` color
- Line height: 1.5 minimum for all Telugu text (script requires vertical space)

### 8.4 Touch Targets

- All interactive elements: minimum 56dp height, 56dp width
- Primary CTA buttons: 72dp height, full width minus 32dp horizontal padding
- Contact list items: 72dp height
- Back button: 48dp × 48dp
- Microphone button: 96dp diameter circle

### 8.5 Spacing

- Screen edge padding: 20dp horizontal, 24dp vertical
- Between major sections: 32dp
- Between list items: 0dp (use dividers instead)
- Card internal padding: 20dp

### 8.6 Iconography

- Icons: Material Symbols (free, from Google Fonts)
- All icons paired with Telugu label text — never icon-only
- Icon size: 32dp for list items, 40dp for primary actions
- Icon color: `primary` for active, `text-secondary` for inactive

---

## 9. Screen-by-Screen Specification

### 9.1 Home Screen (హోమ్)

**Layout:** Full-screen, two equal-height cards stacked vertically with 24dp gap. App name at top.

**Header:**
- App name: "EasySave" — 26sp, centered, `text-primary`
- Subtitle: small Telugu tagline — 16sp, `text-secondary`

**Card 1 — Save Contact:**
- Background: `primary-light`
- Large icon (phone + person, 56dp) in `primary` color
- Label: "పరిచయం సేవ్ చేయి" — 26sp bold
- Sub-label: "కొత్త నంబర్ సేవ్ చేయడానికి" — 17sp secondary
- Entire card is tappable (full-bleed touch target)

**Card 2 — Share Photo:**
- Background: white with `primary` left border (4dp)
- Large icon (photo + share, 56dp) in `primary` color
- Label: "ఫోటో పంపించు" — 26sp bold
- Sub-label: "WhatsApp లో ఫోటో పంపించడానికి" — 17sp secondary
- Entire card is tappable

**No other elements on this screen.** No settings link, no version number, no credits.

---

### 9.2 Save Contact — Number Entry Screen

**Header:** "నంబర్ ఎంటర్ చేయండి" (Enter Number)

**Large number display:** Shows digits as typed, 40sp, centered, monospace  
Placeholder: "_ _ _ _ _ _ _ _ _ _"

**Custom numeric keypad:**
- 3×4 grid of large circular buttons (72dp diameter)
- Digits 1–9, then 0 and backspace (⌫)
- Font: 32sp, weight 600
- Background: `surface-muted`, pressed: `primary-light`
- No letters (unlike system numpad)

**CTA Button:** "తర్వాత →" (Next) — appears once 10 digits are entered, full-width, 72dp height, `primary` background, white 24sp text

---

### 9.3 Save Contact — Voice Name Entry Screen

**Header:** "పేరు చెప్పండి" (Say the Name)

**Microphone area:**
- Large pulsing circle (96dp), `primary` color
- State 1 (idle): Mic icon, "పై బటన్ నొక్కి పేరు చెప్పండి" (Press and say the name)
- State 2 (listening): Animated waveform rings, "వింటున్నాను..." (Listening...)
- State 3 (done): Recognized text appears in a card below

**Recognized name card:**
- White card, 16dp radius
- Recognized name in 32sp bold Telugu
- Below it: "ఇది సరైనదేనా?" (Is this correct?)
- Two buttons side by side: "అవును ✓" (Yes) — `success` | "మళ్ళీ చెప్పండి" (Try again) — outlined

**Fallback link:** "కీబోర్డ్ తో టైప్ చేయండి" (Type with keyboard) — small text link at bottom, opens system keyboard

---

### 9.4 Save Contact — Confirmation Screen

**Single card showing:**
- Person icon (large, 56dp, `primary`)
- Name: 32sp bold
- Phone: 26sp, formatted (e.g., +91 98765 43210)

**Single CTA:** "సేవ్ చేయి" (Save) — large, full-width, `primary` background

**Back link:** to go back and correct name or number

---

### 9.5 Save Contact — Success Screen

**Full-screen success state:**
- Large ✓ in a circle (80dp, `success` green)
- "సేవ్ అయింది!" (Saved!) — 32sp bold
- Name and number shown below in 24sp
- Auto-dismiss after 2.5 seconds → returns to Home
- Manual dismiss: "హోమ్ కి వెళ్ళు" button

---

### 9.6 Photo Picker Screen

**Header:** "ఫోటో ఎంచుకోండి" (Choose a Photo)

**Gallery grid:**
- 2 columns, square thumbnails, 4dp gap
- Most recent photos first
- Each thumbnail: 56dp corner radius = 0, subtle 1dp border in `divider` color
- No album navigation — flat chronological list of all photos
- Smooth scroll, no pagination

**Tap behavior:** Tap any photo → goes to Photo Confirmation screen (no multi-select)

---

### 9.7 Photo Confirmation Screen

**Full-screen photo preview** (aspect-fill)

**Bottom sheet (fixed, 140dp):**
- White background, top rounded corners (20dp)
- Photo name/date in `text-secondary` 16sp
- Single large button: "ఈ ఫోటో పంపించు →" (Send this photo) — `primary`, full-width

---

### 9.8 Contact Picker Screen

**Header:** "ఎవరికి పంపించాలి?" (Who to send to?)

**Contact list:**
- Full-width list items, 72dp height
- Avatar: 48dp circle, initial letter, color derived from name hash (warm palette)
- Name: 24sp, `text-primary`
- Phone (optional, 16sp, `text-secondary`)
- No search bar (Phase 2) — contacts sorted alphabetically in Telugu

**Empty state:** If no contacts saved, shows a warm illustration and "ముందు పరిచయం సేవ్ చేయండి" (Save a contact first) with a link to the Save Contact flow

---

## 10. Technical Architecture

### 10.1 Technology Stack (100% Free)

| Component | Technology | Cost |
|-----------|-----------|------|
| Framework | Flutter (Dart) | Free / Open Source |
| Speech recognition | `speech_to_text` Flutter plugin (wraps Google on-device STT) | Free |
| Telugu STT | Google's on-device speech engine (bundled in Android) | Free |
| Contacts access | `flutter_contacts` plugin | Free |
| Media/gallery | `photo_manager` plugin | Free |
| WhatsApp sharing | Android Intents via `url_launcher` + `share_plus` | Free |
| Font | Noto Sans Telugu via `google_fonts` package | Free |
| Icons | Material Symbols via `material_symbols_icons` package | Free |
| Local storage | `shared_preferences` (app state only) | Free |
| Device permissions | `permission_handler` plugin | Free |

### 10.2 Platform Target

- **Minimum SDK:** Android 8.0 (API 26) — covers 97%+ of active Android devices in India
- **Target SDK:** Android 14 (API 34)
- **Architecture:** ARM64 + ARM (universal APK)
- **Permissions required:**
  - `READ_CONTACTS` — read contact list for WhatsApp picker
  - `WRITE_CONTACTS` — save new contacts
  - `READ_MEDIA_IMAGES` (API 33+) / `READ_EXTERNAL_STORAGE` (older) — gallery access
  - `RECORD_AUDIO` — microphone for voice name input

### 10.3 WhatsApp Integration

WhatsApp sharing on Android works via a file-sharing Intent without requiring any API key or registration:

```
Intent.ACTION_SEND
  type = "image/jpeg"
  EXTRA_STREAM = FileProvider URI of selected photo
  package = "com.whatsapp"
  EXTRA_PHONE_NUMBER = selected contact's phone number
```

The FileProvider must be configured in `AndroidManifest.xml` with `<provider>` pointing to a `file_paths.xml` that exposes the cache directory. Photos are copied to cache before sharing (required by FileProvider security model).

**Fallback:** If WhatsApp is not installed, show Telugu error: "WhatsApp ఇన్స్టాల్ అయిలేదు" with a button to open Play Store.

### 10.4 Speech-to-Text Configuration

```dart
SpeechToText speechToText = SpeechToText();
await speechToText.initialize(
  onStatus: statusListener,
  onError: errorListener,
);
speechToText.listen(
  onResult: resultListener,
  localeId: 'te_IN', // Telugu (India)
  listenFor: Duration(seconds: 10),
  pauseFor: Duration(seconds: 2),
  partialResults: true,
);
```

The `te_IN` locale uses Google's on-device Telugu model. No internet required once the device has the language pack downloaded. The app should detect if the Telugu speech pack is available on first launch and prompt download if missing.

### 10.5 Folder Structure

```
lib/
├── main.dart
├── app.dart                    # MaterialApp, theme, routes
├── theme/
│   ├── app_colors.dart
│   ├── app_text_styles.dart
│   └── app_theme.dart
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
├── services/
│   ├── speech_service.dart
│   ├── contacts_service.dart
│   ├── media_service.dart
│   └── whatsapp_service.dart
├── widgets/
│   ├── large_button.dart
│   ├── avatar_circle.dart
│   ├── numeric_keypad.dart
│   ├── contact_list_tile.dart
│   └── photo_grid.dart
├── models/
│   ├── contact_model.dart
│   └── photo_model.dart
└── l10n/
    └── te.arb                  # All Telugu strings
```

### 10.6 Localization

All user-facing strings are stored in `te.arb` (Flutter's ARB format). Key strings:

```json
{
  "appName": "EasySave",
  "saveContact": "పరిచయం సేవ్ చేయి",
  "sharePhoto": "ఫోటో పంపించు",
  "enterNumber": "నంబర్ ఎంటర్ చేయండి",
  "speakName": "పేరు చెప్పండి",
  "listening": "వింటున్నాను...",
  "isCorrect": "ఇది సరైనదేనా?",
  "yes": "అవును",
  "tryAgain": "మళ్ళీ చెప్పండి",
  "save": "సేవ్ చేయి",
  "saved": "సేవ్ అయింది!",
  "sendThisPhoto": "ఈ ఫోటో పంపించు",
  "whoToSend": "ఎవరికి పంపించాలి?",
  "back": "వెనక్కి",
  "home": "హోమ్ కి వెళ్ళు",
  "whatsappNotInstalled": "WhatsApp ఇన్స్టాల్ అయిలేదు",
  "choosePhoto": "ఫోటో ఎంచుకోండి",
  "next": "తర్వాత",
  "typeWithKeyboard": "కీబోర్డ్ తో టైప్ చేయండి",
  "saveContactFirst": "ముందు పరిచయం సేవ్ చేయండి"
}
```

---

## 11. Permissions Flow & First Launch

### 11.1 First Launch Experience

1. **Splash screen** — App name in Telugu, warm amber background, 2 seconds
2. **Welcome screen** — One screen explaining what the app does in Telugu, illustrated with two simple icons
3. **Permissions request** — Each permission is explained in Telugu before the system dialog appears:
   - "మీ పరిచయాలు చదవడానికి అనుమతి అడుగుతున్నాం" (We need permission to read your contacts)
   - "ఫోటోలు చూడటానికి అనుమతి అడుగుతున్నాం" (We need permission to view photos)
   - "మీ పేరు వినడానికి మైక్ అనుమతి అడుగుతున్నాం" (We need microphone permission to hear your name)
4. **Telugu speech pack check** — If `te_IN` locale not downloaded, show Telugu prompt to download it

### 11.2 Graceful Permission Denial

If any permission is denied:
- Show a Telugu explanation of why it's needed
- Offer a button to re-request or open Settings
- Never crash or show blank screens

---

## 12. Edge Cases & Error Handling

| Scenario | Handling |
|----------|----------|
| Speech not recognized | Show "అర్థం కాలేదు, మళ్ళీ చెప్పండి" (Didn't understand, please try again). Allow 3 retries, then offer keyboard |
| No internet (STT needs data) | On-device STT works offline on most Android 8+ devices if language pack installed |
| WhatsApp not installed | Telugu error screen + Play Store link |
| No photos on device | Empty state with Telugu message |
| No contacts saved | Empty state in contact picker with link to Save Contact flow |
| Contact has no phone number | Skip in contact picker list |
| Photo too large for WhatsApp | Compress to ≤5MB before sharing using `flutter_image_compress` (free) |
| Device contacts permission denied | Show explanation screen, offer Settings link |
| App paused mid-flow (call received) | Save state, resume on return |

---

## 13. Accessibility

- **Text scaling:** All text uses `sp` units — respects user's font size preferences in Android settings
- **Touch target size:** All interactive elements ≥ 56dp (exceeds Google's 48dp minimum)
- **Color contrast:** Primary text on `surface` background — contrast ratio ≥ 7:1 (AAA)
- **TalkBack support:** All interactive elements have `Semantics()` labels in Telugu
- **No animations that cannot be disabled:** All transitions respect `reduce motion` setting

---

## 14. Performance Requirements

| Metric | Target |
|--------|--------|
| App cold start | < 2 seconds on mid-range device |
| Gallery load (100 photos) | < 1.5 seconds |
| Contact list load (500 contacts) | < 1 second |
| Voice recognition response | < 1.5 seconds after speech ends |
| WhatsApp handoff | < 2 seconds including photo copy to cache |

---

## 15. Testing Plan

### 15.1 Unit Tests
- Contact save/read service
- Phone number formatting
- Photo compression service
- WhatsApp intent construction

### 15.2 Widget Tests
- Numeric keypad correctness
- Voice waveform animation states
- Empty state rendering

### 15.3 Integration Tests
- Full save-contact flow (mock contacts plugin)
- Full share-photo flow (mock gallery + WhatsApp)

### 15.4 User Acceptance Testing
- Recruit 2–3 Telugu-speaking adults aged 60+
- Unassisted task: "నంబర్ సేవ్ చేయండి" and "ఫోటో పంపించు"
- Success criteria: task completion without asking for help
- Capture: time-on-task, number of errors, facial expression

---

## 16. Release Plan

### Phase 1 — MVP (Current PRD)
- Home screen with two primary actions
- Save contact (voice + manual fallback)
- Share photo via WhatsApp
- Telugu-only UI
- Android 8.0+

### Phase 2 — Enhancements
- Contact list management (view/edit/delete)
- Recent contacts quick-access on home screen
- Share to recent contact (bypass picker for most-used contact)
- Voice search in contact picker
- Backup contacts to Google Drive

### Phase 3 — Extended Family
- Multiple language support (Tamil, Kannada, Hindi)
- iOS port
- Share video via WhatsApp

---

## 17. Distribution

The app is intended for personal/family use and does not need to be published to the Play Store initially.

**Recommended distribution:**
1. Build a release APK: `flutter build apk --release`
2. Enable "Install from unknown sources" on father's phone (one-time setup)
3. Transfer APK via WhatsApp or USB
4. Install directly

**If Play Store publication is desired later:**
- Create a free Google Play Developer account (one-time ₹2,000 fee)
- App does not require any paid APIs or services

---

## 18. Open Source Dependencies Summary

| Package | Version | License |
|---------|---------|---------|
| flutter | stable | BSD-3 |
| speech_to_text | ^6.x | BSD-3 |
| flutter_contacts | ^1.x | MIT |
| photo_manager | ^3.x | Apache-2.0 |
| url_launcher | ^6.x | BSD-3 |
| share_plus | ^9.x | BSD-3 |
| permission_handler | ^11.x | MIT |
| google_fonts | ^6.x | Apache-2.0 |
| material_symbols_icons | ^4.x | Apache-2.0 |
| flutter_image_compress | ^2.x | MIT |
| shared_preferences | ^2.x | BSD-3 |

All dependencies are free, actively maintained, and have permissive licenses.

---

## 19. Developer Notes

- Use `flutter_localizations` with the `te` locale to ensure system widgets (date pickers, dialogs) also render in Telugu
- The Noto Sans Telugu font must be bundled — do not rely on system fonts for Telugu, as many budget devices have incomplete Telugu font support
- Test on a physical budget device (Redmi or Realme), not just emulator — touch responsiveness varies significantly
- WhatsApp's `ACTION_SEND` intent with `setPackage("com.whatsapp")` targets the main WhatsApp only; WhatsApp Business uses `"com.whatsapp.w4b"`. Detect both and show a picker if both are installed.
- The `speech_to_text` plugin's `te_IN` locale works best when the user pauses briefly after speaking — configure `pauseFor: Duration(seconds: 2)` to avoid cutting off multi-word names

---

*This document is a complete specification for version 1.0 of Amma Nanna App. Any feature not listed here is explicitly out of scope for Phase 1.*
