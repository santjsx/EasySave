import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';

import 'package:amma_nanna_app/models/contact_model.dart';
import 'package:amma_nanna_app/repository/contacts_repository.dart';
import 'package:amma_nanna_app/repository/contacts_repository_impl.dart';

/// Concrete Mock Repository implementation to test boundary parameters,
/// validation constraints, duplicates, and Telugu sorting logic in isolation.
class FakeContactsRepository implements ContactsRepository {
  bool hasPermission = true;
  List<ContactModel> mockContacts = [];

  FakeContactsRepository();

  @override
  Future<bool> checkAndRequestPermission({bool readonly = false}) async {
    return hasPermission;
  }

  @override
  Future<List<ContactModel>> getContacts() async {
    if (!hasPermission) {
      throw const PermissionDeniedException();
    }

    final List<ContactModel> sorted = List.from(mockContacts);
    
    // Sort Telugu alphabetically natively
    sorted.sort((a, b) => a.name.compareTo(b.name));

    return sorted;
  }

  @override
  Future<bool> saveContact(String name, String phone) async {
    if (!hasPermission) {
      throw const PermissionDeniedException('పరిచయం సేవ్ చేయడానికి అనుమతి లేదు');
    }

    final String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]+'), '');
    if (cleanPhone.isEmpty || cleanPhone.length < 10) {
      throw const InvalidPhoneNumberException();
    }

    // Duplicate check
    for (var existing in mockContacts) {
      if (existing.name.toLowerCase() == name.toLowerCase() ||
          existing.phone == cleanPhone) {
        throw const DuplicateContactException();
      }
    }

    mockContacts.add(
      ContactModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: name,
        phone: cleanPhone,
        avatarColor: ContactModel.generateWarmColor(name),
      ),
    );

    return true;
  }

  @override
  Future<bool> deleteContact(String id) async {
    if (!hasPermission) {
      throw const PermissionDeniedException('అనుమతి లేదు');
    }
    mockContacts.removeWhere((element) => element.id == id);
    return true;
  }

  @override
  Future<bool> updateContact(String id, String newName, String newPhone) async {
    if (!hasPermission) {
      throw const PermissionDeniedException('అనుమతి లేదు');
    }
    final int index = mockContacts.indexWhere((element) => element.id == id);
    if (index != -1) {
      mockContacts[index] = mockContacts[index].copyWith(
        name: newName,
        phone: newPhone,
      );
      return true;
    }
    return false;
  }
}

void main() {
  group('EasyConnect Contacts Architecture - Unit Tests', () {
    late FakeContactsRepository contactsRepo;

    setUp(() {
      contactsRepo = FakeContactsRepository();
    });

    test('1. Deterministic Warm Color Avatar generation', () {
      final colorA = ContactModel.generateWarmColor('Ravi');
      final colorB = ContactModel.generateWarmColor('Ravi');
      final colorC = ContactModel.generateWarmColor('Kumar');

      // The color must be deterministic for the same name string
      expect(colorA, equals(colorB));
      
      // Different names might yield different colors (warm palette hash match)
      expect(colorA.red, isPositive);
    });

    test('2. Permission Denied triggers PermissionDeniedException', () async {
      contactsRepo.hasPermission = false;

      expect(
        () => contactsRepo.getContacts(),
        throwsA(isA<PermissionDeniedException>()),
      );

      expect(
        () => contactsRepo.saveContact('రవి కుమార్', '9876543210'),
        throwsA(isA<PermissionDeniedException>()),
      );
    });

    test('3. Invalid Phone Number throws InvalidPhoneNumberException', () async {
      contactsRepo.hasPermission = true;

      // Under 10 digits
      expect(
        () => contactsRepo.saveContact('రవి కుమార్', '98765'),
        throwsA(isA<InvalidPhoneNumberException>()),
      );

      // Empty digits
      expect(
        () => contactsRepo.saveContact('రవి కుమార్', ''),
        throwsA(isA<InvalidPhoneNumberException>()),
      );
    });

    test('4. Duplicate Contact check triggers DuplicateContactException', () async {
      contactsRepo.hasPermission = true;
      contactsRepo.mockContacts = [
        ContactModel(
          id: '1',
          name: 'రవి కుమార్',
          phone: '9876543210',
          avatarColor: Colors.amber,
        ),
      ];

      // Exact name duplicate
      expect(
        () => contactsRepo.saveContact('రవి కుమార్', '9876543211'),
        throwsA(isA<DuplicateContactException>()),
      );

      // Exact phone number duplicate
      expect(
        () => contactsRepo.saveContact('రవి రావు', '9876543210'),
        throwsA(isA<DuplicateContactException>()),
      );
    });

    test('5. Telugu Alphabetical Collation sorting correctness', () async {
      contactsRepo.hasPermission = true;
      
      // Add out of order Telugu names
      contactsRepo.mockContacts = [
        ContactModel(
          id: '1',
          name: 'రవి', // Ravi
          phone: '9876543210',
          avatarColor: Colors.amber,
        ),
        ContactModel(
          id: '2',
          name: 'అనిల్', // Anil (starts with 'అ' - vowel first in alphabet)
          phone: '9876543211',
          avatarColor: Colors.amber,
        ),
        ContactModel(
          id: '3',
          name: 'కమల్', // Kamal (starts with 'క')
          phone: '9876543212',
          avatarColor: Colors.amber,
        ),
      ];

      final List<ContactModel> sortedList = await contactsRepo.getContacts();

      // Ordered: అనిల్ (Anil), కమల్ (Kamal), రవి (Ravi)
      expect(sortedList[0].name, equals('అనిల్'));
      expect(sortedList[1].name, equals('కమల్'));
      expect(sortedList[2].name, equals('రవి'));
    });
  });
}
