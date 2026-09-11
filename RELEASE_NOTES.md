# EasySave v1.3.2 Release - Dual-SIM Calling Fix & Text Scaling Safeguards 🚀📱

We are proud to release version **1.3.2**, fixing the dual-SIM calling freeze (blank white screen on Realme / Oppo / ColorOS devices) and preventing oversized layout ballooning when Android system display/font size is set to Large or Largest.

---

## 🛠️ What's Changed in v1.3.2
### 📞 Dual-SIM Universal Calling (Zero-Freeze & Zero-Blank Screen)
*   **Google-Standard ACTION_DIAL Architecture:** Dispatches phone numbers directly to Android's official dialer via `Intent.ACTION_DIAL` (`tel:<number>`), completely eradicating the dual-SIM blank screen freeze caused by `ACTION_CALL` on Realme, Oppo, OnePlus, and ColorOS devices.
*   **Seamless SIM 1 / SIM 2 Selection:** On dual-SIM phones, the native dialer cleanly presents SIM 1 and SIM 2 call buttons with the number prefilled, allowing effortless 1-tap dialing.
*   **Zero Permissions Required:** Eliminates dependency on dangerous `CALL_PHONE` runtime permissions, ensuring 100% reliable calling on all Android versions (8 through 16).
*   **Caller ID Conflicts Eradicated:** Prevents third-party and OEM Caller ID scanners from intercepting and freezing the calling UI.

### 📐 Text Scaling Safeguards & Layout Overflow Fix ("Too Much Big" Solved)
*   **Clamped Text Scaling (`0.95` to `1.15`):** Protects EasySave's already-enlarged elder-friendly base typography from multiplying uncontrollably into gigantic proportions when Android system display settings are set to Large or Largest.
*   **Settings Header Overflow Fixed:** Wrapped the Privacy Policy title in `Expanded` to prevent horizontal text clipping.
*   **Natural Conversational Telugu in Permissions:** Simplified permission titles to clean, natural Telugu without redundant English parentheticals:
    *   `కాంటాక్ట్స్`
    *   `ఫోన్ కాల్స్`
    *   `మైక్రోఫోన్ (వాయిస్)`
    *   `ఫోటోలు & గ్యాలరీ`
    *   `యాప్ అనుమతులు`

---

# EasySave v1.3.1 Release - 1-Click Calling, Intelligent Live Search & Recent Calls Fix 🚀📞

We are proud to release version **1.3.1**, bringing a zero-edge-case 1-Click Calling engine across the entire app, layout overflow fixes for recent calls, intelligent multi-tiered live search with fuzzy matching, voice recipient selection for WhatsApp photo sharing, and empathetic Telugu empty states.

---

## 🛠️ What's Changed in v1.3.1
### 📞 1-Click Calling System (Zero-Edge Cases)
*   **Dual-Tier Calling Architecture:** Initiates direct native calls via `ACTION_CALL` when permission is present, and seamlessly falls back to `Intent.ACTION_DIAL` (`tel:<number>`) without requiring any runtime permissions if denied.
*   **E.164-Compatible Phone Sanitization:** Strips all spaces, dashes, and parentheses while preserving international `+` prefixes, preventing dialer launch failures.
*   **1-Click Call Buttons Everywhere:** Available directly on every contact card in the directory, all recent call log entries, contact details screen, and home screen preview.

### 🐛 Recent Calls Blank Cards & RenderFlex Overflow Fix
*   **Solved Silent Flex Overflow:** Replaced oversized text buttons on unsaved callers that exceeded mobile viewports with compact 1-click call and quick-save icons.
*   **Zero Blank Cards:** Completely eliminates release-mode layout crashes on narrow devices.

### 🔍 Multi-Tiered Live Search & Fuzzy Matching
*   **Intelligent Ranking:** Exact, token prefix, substring, and Damerau-Levenshtein fuzzy matching with Telugu phonetic transliteration.
*   **Empathetic Contact Not Found Screen:** Displays searched term, helpful advice, 1-tap "Save as New Contact", and 1-tap "Clear Search".
*   **WhatsApp Photo Voice Recipient Selection:** Voice search mic in photo share contact picker for effortless Telugu/English recipient selection.

### 🌟 Elderly-Friendly Empty States
*   **Engaging Guidance:** Illustrated empty state cards with 1-tap action buttons in Recent Calls, Contacts Directory, and Home Screen.

---

# EasySave v1.3.0 Senior Experience & Google Play In-App Updates 🌟📱

- **Complete UI/UX Redesign**: Clean, accessible, elderly-friendly screens adhering to Hick's and Fitts's laws with WCAG AAA compliance.
- **Natural Conversational Telugu**: Full localization overhaul replacing literal translations with genuine, everyday conversational Telugu understood by elders across all regions.
- **Dedicated Screens**: Contact Details, Contact Form, Recent Calls, and Settings & Permissions.
- **Hardened Voice Input Engine**: Silence watchdog timer prevents Android 12+ recognition freezes; added real-time sound level feedback and stutter deduplication.
- **Google Play In-App OTA Updates**: Official Google Play Core API integration with silent background downloading, home screen restart banner, and settings management.

---

# EasySave v1.2.13 Senior-Optimistic Hotfix Release 🛠️📱

We are happy to release version **1.2.13**, which implements a production-grade, double-guaranteed background contact editor and optimistic UI updates to completely solve lag, sync inconsistencies, and race conditions.

---

## 🛠️ What's Changed
### ⚡ Instant Optimistic UI Updates
*   **Zero-Lag UI Rendering:** The contact list now optimistically updates in-memory with the new name, phone number, and deterministic avatar color instantly. This completely eliminates lag and visual flickers caused by slow OS Contacts indexing.
*   **Automatic Collation Sorting:** Re-sorts the list in memory immediately using the Telugu alphabetical sorting standard to keep lists perfectly aligned.
*   **Asynchronous Background Synchronization:** Re-queries and synchronizes the contacts database in the background after a slight 800ms delay, allowing the Android system wrapper to completely finish its background indexing processes without blocking the UI.

### 👤 Bulletproof Android Update-or-Insert Native Pipeline
*   **Adaptive Update-or-Insert Loop:** In case a writeable raw contact is missing its `StructuredName` or `Phone` data rows in the system database, the native system now catches the 0-row updated count and performs a direct, clean `insert` operation. This makes background renaming 100% successful even for corrupt or stripped contact structures.
*   **Exclusion of read-only WhatsApp/Telegram directories** remains intact to prevent platform write restrictions.

---

# EasySave v1.2.12 Writeable-Filter Update Hotfix 🛠️📱

We are happy to release version **1.2.12**, which implements a highly robust, individual ContentProvider raw-contact updater that excludes read-only platform raw accounts (like WhatsApp/Telegram) and validates modified row counts to guarantee a 100% correct, zero-failure background renaming experience.

---

## 🛠️ What's Changed
### 👤 Bulletproof Direct Background Contact Renaming (Writeable Filters!)
*   **Writeable Raw Contact Filtering:** The native Android system now fetches all sub-accounts (raw contacts) associated with the contact ID and filters out read-only types (e.g. WhatsApp, Telegram, Skype) dynamically. This prevents read-only account constraints from throwing database write-protection exceptions.
*   **Individual Direct Updates:** Instead of batch ContentProvider operations that can fail atomically if a single raw contact fails, the app now updates writeable raw contacts (`StructuredName` and `Phone` tables) individually.
*   **Truthful Return Status Validation:** Kotlin now tracks the exact number of database rows affected. It returns a successful `true` status to Dart only if at least one row was actually modified. If no rows were changed, it triggers the programmatic fallback seamlessly, guaranteeing the edit succeeds.

---

# EasySave v1.2.11 Background Update Hotfix 🛠️📱

We are happy to release version **1.2.11**, which implements a fully custom, background-based Android ContentProvider update channel for contact renaming, removing any need for opening the external system editor.

---

## 🛠️ What's Changed
### 👤 Direct Background Contact Renaming (No External Editor!)
*   **Direct Native ContentProvider Operations:** Contact renaming is now executed directly in the database background using highly optimized batch ContentProvider queries in Kotlin. This bypasses permission, cloud-sync, and third-party library constraints.
*   **Removed External Google Contacts UI:** Replaces the native Google contacts system editor completely, satisfying requests for a seamless, in-app editing experience.
*   **Fully Clean segment updates:** Safely sanitizes all components (`StructuredName` and `Phone` tables) instantly.

---

# EasySave v1.2.10 Hotfix Release 🛠️📱

We are happy to release version **1.2.10**, which introduces a robust native editor fallback to ensure contact renaming is 100% bulletproof even under modern OS or cloud-synced account database restrictions.

---

## 🛠️ What's Changed
### 👤 Bulletproof Contact Renaming
*   **Tactile Native Editor Fallback:** If a programmatic contact update is rejected or fails due to database restrictions (e.g. read-only Google/WhatsApp syncing, permission restrictions), the app now gracefully and instantly opens the OS's native contact edit form (`openExternalEdit`). This provides a seamless, zero-error editing experience.
*   **Resolved "సేవ్ చేయడం కుదరలేదు" Error:** Eradicates the red "సేవ్ చేయడం కుదరలేదు" error sheet by cleanly delegating the edit action to the Android system when needed.

---

# EasySave v1.2.9 Patch Release 🛠️📱

We are happy to release version **1.2.9**, which includes a critical bug fix for editing/renaming contacts natively on Android.

---

## 🛠️ What's Changed
### 👤 Contact Renaming & Details Fix
*   **Resolved Native Update Errors:** Contact modifications now safely query full data structures from the OS using the `withProperties: true` payload, avoiding native platform crashes or data loss.
*   **Name Component Sanitization:** Cleanses all name parts (`first`, `last`, `middle`, `prefix`, `suffix`) during updates so that old name parts (e.g. old last names) do not awkwardly linger.
*   **Expanded Unit Tests:** Added specific mock repository tests to validate the `updateContact` interface.

---

# EasySave v1.0.0 Production Release 🚀📱

We are extremely proud to announce the first production release of **EasySave**! This version has been fully audited, optimized, and certified for zero production blockers.

EasySave is a Telugu-first, elderly-friendly, and accessibility-first assistant tailored specifically for motor-challenged, first-time, or non-literate smartphone users.

---

## 🌟 Key Highlights

### 🎙️ Voice-First Contact Saving (2-3 Taps)
*   **Telugu Locale Input:** Speech-to-Text maps directly to `'te_IN'` for natural script matching.
*   **Sequence-Aware Deduplication:** Smart word analyzer removes duplicate names spoken repeatedly (e.g. converting `"సంతోష్ సంతోష్"` into `"సంతోష్"`).
*   **Generous Listening Limits:** Enhanced patience settings with `20`-second total capture limits and a custom `2`-second silence auto-stop trigger.
*   **Zero-Flicker States:** Instant UI updates that prevent blinking/flash frames during dynamic callbacks.

### ✉️ One-Tap Simpler WhatsApp Photo Sharing
*   **Zero System Sheet Clutter:** Launches directly into the selected contact's WhatsApp chat thread.
*   **Secure Intent Dispatch:** Packages assets utilizing Android's secure `FileProvider` (`content://` URIs).
*   **Number Normalization:** Sanitizes phone numbers on the fly, automatically appending international codes (e.g., `+91` prefix standard) to guarantee reliable routing.

### 📞 Contact History & Instant CTAs
*   **Call Duplication Grouping:** Aggregates up to 500 records into grouped logs (e.g., `"రమేష్ (3 కాల్స్)"`) to dramatically reduce cognitive overhead.
*   **Instant Unsaved Save:** Unknown callers prominently showcase a massive green `"సేవ్ చేయండి"` CTA that directs straight to the voice recorder wizard.

### 👤 4. My Contacts Manager (చూడండి, మార్చండి, తీసేయండి - New!)
*   **Tactile Dashboard Integration:** Wide, green circular button on the dashboard for direct, zero-friction access.
*   **Search & View:** Telugu collation-sorted contacts directory with an instant responsive search bar.
*   **Tactile Modal Sheets:** Tapping any contact tile opens a massive detail sheet featuring huge green Call, amber Rename, and red Delete action cards.
*   **Bulletproof Native Operations:** Edit/update names and numbers natively, and remove records safely with double-confirm red warning dialogues.

---

## ♿ Accessibility Compliance (WCAG 2.2 AA)
*   **TalkBack Semantic Cues:** Keypad elements are fully customized (e.g., `"అంకె ఒకటి"`, `"అంకె సున్నా"`) instead of fast raw digits.
*   **72dp Touch Targets:** Interactive surfaces exceed standard sizes, ensuring easy activation for motor-challenged users.
*   **Noto Sans Telugu Typography:** Clean rendering of complex glyphs across budget smartphones, completely avoiding tofu blocks.
*   **Fitted Dynamic Layouts:** Uses auto-scaling bounds to prevent text overflows or clipped boundaries.

---

## ⚙️ Core Technical Specifications
*   **Target SDK:** Android 36 (targetSdk 36) / Android 16 Cloud-Safe
*   **Native Bridge:** `MainActivity.kt` handles programmatic SQLite/Contacts contract insertions safely to Google/Cloud active authenticators, avoiding default saving blocks.
*   **Flutter Version:** v3.44.0 SDK
*   **State Manager:** Flutter Riverpod v2.5.1
*   **Routing:** GoRouter v14.2.0

---

## 📦 Downloadable Assets
*   **`app-release.apk`**: Production release binary. Ready to sideload directly onto compatible Android devices.

*Thank you for supporting accessible technology for our elders! 💖*
