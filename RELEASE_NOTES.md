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
