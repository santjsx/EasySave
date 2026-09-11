/// Centralized registry of type-safe path strings for GoRouter navigation.
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

  // -------------------------------------------------------------
  // Feature Flow 2: Contacts Directory & Management
  // -------------------------------------------------------------
  /// Contacts List view path: /contacts
  static const String contactsList = '/contacts';

  /// Dedicated Contact Details Screen: /contacts/details
  static const String contactDetails = '/contacts/details';

  /// Dedicated Add / Edit Contact Screen: /contacts/form
  static const String contactForm = '/contacts/form';

  // -------------------------------------------------------------
  // Feature Flow 3: WhatsApp Photo Sharer
  // -------------------------------------------------------------
  static const String sharePhoto = '/share-photo';
  static const String photoConfirm = '/share-photo/confirm';
  static const String contactPicker = '/share-photo/contacts';

  // -------------------------------------------------------------
  // Feature Flow 4: Recent Calls & Quick Voice-Save
  // -------------------------------------------------------------
  static const String recentCalls = '/recent-calls';
  static const String quickSave = '/recent-calls/quick-save';

  // -------------------------------------------------------------
  // Feature Flow 5: Settings & Information
  // -------------------------------------------------------------
  static const String settings = '/settings';
}
