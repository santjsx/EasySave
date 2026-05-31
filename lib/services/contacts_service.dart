import '../models/contact_model.dart';
import '../repository/contacts_repository.dart';

/// Application Service layer that coordinates contact address book capabilities.
/// Strictly delegates structural operations to the [ContactsRepository] contract, keeping clean layer isolation.
class ContactsService {
  final ContactsRepository _repository;

  ContactsService(this._repository);

  /// Requests address book access permissions from the OS.
  Future<bool> checkAndRequestPermission({bool readonly = false}) {
    return _repository.checkAndRequestPermission(readonly: readonly);
  }

  /// Lists device contacts alphabetically sorted using the Telugu collation system.
  Future<List<ContactModel>> getContacts() {
    return _repository.getContacts();
  }

  /// Creates and saves a new contact card.
  /// Throws semantic domain exceptions ([PermissionDeniedException], [InvalidPhoneNumberException], etc.) on errors.
  Future<bool> saveContact(String name, String phone) {
    return _repository.saveContact(name, phone);
  }

  /// Deletes an existing contact.
  Future<bool> deleteContact(String id) {
    return _repository.deleteContact(id);
  }

  /// Updates details of an existing contact.
  Future<bool> updateContact(String id, String newName, String newPhone) {
    return _repository.updateContact(id, newName, newPhone);
  }
}
