import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:intl/intl.dart';

import '../models/contact_model.dart';
import 'contacts_repository.dart';

/// Concrete implementation of the [ContactsRepository] contract wrapping the native [FlutterContacts] API.
class ContactsRepositoryImpl implements ContactsRepository {
  ContactsRepositoryImpl();

  @override
  Future<bool> checkAndRequestPermission({bool readonly = false}) async {
    try {
      final granted = await FlutterContacts.requestPermission(readonly: readonly);
      debugPrint('Contacts permission request returned: $granted');
      return granted;
    } catch (e) {
      debugPrint('Contacts permission query crashed: $e');
      return false;
    }
  }

  @override
  Future<List<ContactModel>> getContacts() async {
    // 1. Verify permissions (Throw exception if missing to satisfy clean error architecture)
    final bool hasPermission = await FlutterContacts.requestPermission(readonly: true);
    if (!hasPermission) {
      throw const PermissionDeniedException();
    }

    try {
      // 2. Fetch fresh native records (Rule 11)
      final List<Contact> nativeContacts = await FlutterContacts.getContacts(
        withProperties: true,
      );

      final List<ContactModel> mappedContacts = [];

      for (var contact in nativeContacts) {
        // Enforce Rule 18: Silently exclude contacts without phone numbers
        if (contact.phones.isEmpty) continue;

        final String displayName = contact.displayName.trim();
        final String rawPhone = contact.phones.first.number;

        // Clean and normalize (keep digits and leading plus only)
        final String normalizedPhone = rawPhone.replaceAll(RegExp(r'[^\d+]+'), '');

        mappedContacts.add(
          ContactModel(
            id: contact.id,
            name: displayName.isNotEmpty ? displayName : 'పరిచయం',
            phone: normalizedPhone,
            avatarColor: ContactModel.generateWarmColor(displayName),
          ),
        );
      }

      // 3. Alphabetically sort contacts natively. Since Telugu Unicode characters are ordered
      // alphabetically by default, standard string comparison naturally sorts Telugu text.
      mappedContacts.sort((a, b) => a.name.compareTo(b.name));

      return mappedContacts;
    } catch (e) {
      debugPrint('Native contacts read exception: $e');
      throw const ContactSaveFailureException('పరిచయాలు చదవడం కుదరలేదు');
    }
  }

  @override
  Future<bool> saveContact(String name, String phone) async {
    // 1. Validate permissions
    final bool hasPermission = await FlutterContacts.requestPermission();
    if (!hasPermission) {
      throw const PermissionDeniedException('పరిచయం సేవ్ చేయడానికి అనుమతి లేదు');
    }

    // 2. Validate phone number criteria
    final String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]+'), '');
    if (cleanPhone.isEmpty || cleanPhone.length < 10) {
      throw const InvalidPhoneNumberException();
    }

    // 3. Validate duplicates (Duplicate check on Name or Number)
    try {
      final List<Contact> existingContacts = await FlutterContacts.getContacts(
        withProperties: true,
      );

      for (var existing in existingContacts) {
        // Exact name match check
        if (existing.displayName.trim().toLowerCase() == name.trim().toLowerCase()) {
          throw const DuplicateContactException();
        }

        // Exact number match check
        for (var existingPhone in existing.phones) {
          final String normExisting = existingPhone.number.replaceAll(RegExp(r'[^\d+]+'), '');
          if (normExisting == cleanPhone) {
            throw const DuplicateContactException();
          }
        }
      }

      // 4. Perform direct programmatic insertion using our custom Kotlin MethodChannel to safely catch and handle Android 16 cloud restrictions without crashing
      bool saved = false;
      try {
        const platform = MethodChannel('com.ammananna.app/direct_call');
        saved = await platform.invokeMethod<bool>('saveContactNatively', {
          'name': name.trim(),
          'phone': cleanPhone,
        }) ?? false;
      } catch (e) {
        debugPrint('Programmatic native save contact threw error: $e');
      }

      // 5. If programmatic save fails (or returns false), gracefully fallback to the native system editor dialog as a bulletproof option
      if (!saved) {
        debugPrint('Programmatic native save failed. Falling back to native system editor form.');
        final newContact = Contact()
          ..name.first = name.trim()
          ..phones = [Phone(cleanPhone)];
        await FlutterContacts.openExternalInsert(newContact);
        return true;
      }

      debugPrint('Successfully committed new contact to device: $name ($cleanPhone)');
      return true;
    } on DuplicateContactException {
      rethrow;
    } catch (e) {
      debugPrint('Contacts insertion failed: $e');
      throw const ContactSaveFailureException();
    }
  }

  @override
  Future<bool> deleteContact(String id) async {
    final bool hasPermission = await FlutterContacts.requestPermission();
    if (!hasPermission) {
      throw const PermissionDeniedException('డిలీట్ చేయడానికి అనుమతి లేదు');
    }
    try {
      final contact = await FlutterContacts.getContact(id);
      if (contact != null) {
        await contact.delete();
        debugPrint('Successfully deleted contact: $id');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Delete contact native failure: $e');
      return false;
    }
  }

  @override
  Future<bool> updateContact(String id, String newName, String newPhone) async {
    final bool hasPermission = await FlutterContacts.requestPermission();
    if (!hasPermission) {
      throw const PermissionDeniedException('సరిచేయడానికి అనుమతి లేదు');
    }

    final String cleanPhone = newPhone.replaceAll(RegExp(r'[^\d+]+'), '');
    if (cleanPhone.isEmpty || cleanPhone.length < 10) {
      throw const InvalidPhoneNumberException();
    }

    try {
      final contact = await FlutterContacts.getContact(id);
      if (contact != null) {
        contact.name.first = newName.trim();
        if (contact.phones.isNotEmpty) {
          contact.phones.first.number = cleanPhone;
        } else {
          contact.phones = [Phone(cleanPhone)];
        }
        await contact.update();
        debugPrint('Successfully updated contact: $id to $newName ($cleanPhone)');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Update contact native failure: $e');
      return false;
    }
  }
}
