/// Centralized registry of type-safe path strings for GoRouter navigation.
/// Configured for the updated Save Contact flow: Voice first ➔ Dialer second.
class AppRoutes {
  AppRoutes._(); // Prevent instantiation

  static const String home = '/';

  // -------------------------------------------------------------
  // Feature Flow 1: Contact Saver (Voice-First Flow)
  // -------------------------------------------------------------
  
  /// Base domain route: Voice Recording screen (/save-contact)
  static const String saveContact = '/save-contact';

  /// Keypad entry sub-route: /save-contact/number
  static const String numberEntry = '/save-contact/number';

  /// Final details verification page path: /save-contact/confirm
  static const String confirmContact = '/save-contact/confirm';

  /// Auto-dismissing success banner path: /save-contact/success
  static const String saveSuccess = '/save-contact/success';

  /// Contacts List view path: /contacts
  static const String contactsList = '/contacts';

  // -------------------------------------------------------------
  // Feature Flow 2: WhatsApp Photo Sharer
  // -------------------------------------------------------------
  static const String sharePhoto = '/share-photo';
  static const String photoConfirm = '/share-photo/confirm';
  static const String contactPicker = '/share-photo/contacts';

  // -------------------------------------------------------------
  // Feature Flow 3: Recent Calls & Quick Voice-Save
  // -------------------------------------------------------------
  static const String recentCalls = '/recent-calls';
  static const String quickSave = '/recent-calls/quick-save';
}
