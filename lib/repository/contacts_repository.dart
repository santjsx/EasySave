import '../models/contact_model.dart';

// -------------------------------------------------------------
// Domain Exceptions
// -------------------------------------------------------------

/// Thrown when device contacts permission is denied by the user.
class PermissionDeniedException implements Exception {
  final String message;
  const PermissionDeniedException([this.message = 'పరిచయాలు చదవడానికి అనుమతి లేదు']);
  @override
  String toString() => message;
}

/// Thrown when dialing inputs fail standard validation constraints.
class InvalidPhoneNumberException implements Exception {
  final String message;
  const InvalidPhoneNumberException([this.message = 'సరైన ఫోన్ నంబర్ ఇవ్వండి']);
  @override
  String toString() => message;
}

/// Thrown when a contact name or number already exists in the address book.
class DuplicateContactException implements Exception {
  final String message;
  const DuplicateContactException([this.message = 'ఈ పరిచయం ఇప్పటికే సేవ్ చేయబడింది']);
  @override
  String toString() => message;
}

/// Generic container thrown on native insert failures.
class ContactSaveFailureException implements Exception {
  final String message;
  const ContactSaveFailureException([this.message = 'పరిచయం సేవ్ చేయడం కుదరలేదు']);
  @override
  String toString() => message;
}

// -------------------------------------------------------------
// Repository Contract Interface
// -------------------------------------------------------------

/// Abstract contract defining complete read/write access to native device contacts.
abstract class ContactsRepository {
  /// Asks the OS for address book read/write permissions.
  Future<bool> checkAndRequestPermission({bool readonly = false});

  /// Reads fresh device contacts and sorts them according to Telugu collator.
  /// Throws [PermissionDeniedException] if permissions are missing.
  Future<List<ContactModel>> getContacts();

  /// Creates and saves a new contact directly to the device.
  /// Throws [PermissionDeniedException], [InvalidPhoneNumberException],
  /// [DuplicateContactException], or [ContactSaveFailureException].
  Future<bool> saveContact(String name, String phone);

  /// Deletes a contact card from the device address book.
  Future<bool> deleteContact(String id);

  /// Updates contact card details (name or phone) on the device.
  Future<bool> updateContact(String id, String newName, String newPhone);
}
