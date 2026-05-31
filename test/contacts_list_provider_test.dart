import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:amma_nanna_app/models/contact_model.dart';
import 'package:amma_nanna_app/providers/contacts_list_provider.dart';
import 'package:amma_nanna_app/repository/contacts_repository.dart';
import 'package:amma_nanna_app/services/contacts_service.dart';
import 'package:amma_nanna_app/providers/system_provider.dart';

class MockContactsRepositoryForList implements ContactsRepository {
  bool hasPermission = true;
  List<ContactModel> items = [];

  @override
  Future<bool> checkAndRequestPermission({bool readonly = false}) async => hasPermission;

  @override
  Future<List<ContactModel>> getContacts() async {
    if (!hasPermission) throw const PermissionDeniedException();
    final list = List<ContactModel>.from(items);
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  @override
  Future<bool> saveContact(String name, String phone) async {
    items.add(ContactModel(
      id: name,
      name: name,
      phone: phone,
      avatarColor: ContactModel.generateWarmColor(name),
    ));
    return true;
  }

  @override
  Future<bool> deleteContact(String id) async {
    items.removeWhere((item) => item.id == id);
    return true;
  }

  @override
  Future<bool> updateContact(String id, String newName, String newPhone) async {
    final idx = items.indexWhere((item) => item.id == id);
    if (idx != -1) {
      items[idx] = items[idx].copyWith(name: newName, phone: newPhone);
      return true;
    }
    return false;
  }
}

void main() {
  group('EasySave ContactsListProvider - Unit Tests', () {
    late MockContactsRepositoryForList mockRepo;
    late ProviderContainer container;

    setUp(() {
      mockRepo = MockContactsRepositoryForList();
      mockRepo.items = [
        ContactModel(id: '1', name: 'రమేష్', phone: '9876543210', avatarColor: ContactModel.generateWarmColor('రమేష్')),
        ContactModel(id: '2', name: 'సంతోష్', phone: '9988776655', avatarColor: ContactModel.generateWarmColor('సంతోష్')),
        ContactModel(id: '3', name: 'అనిల్', phone: '9123456789', avatarColor: ContactModel.generateWarmColor('అనిల్')),
      ];

      container = ProviderContainer(
        overrides: [
          contactsRepositoryProvider.overrideWithValue(mockRepo),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('1. Initial Load fetches sorted contacts', () async {
      final state = container.read(contactsListProvider);
      
      // Wait for auto trigger loading
      await container.read(contactsListProvider.notifier).fetchContacts();
      
      final updatedState = container.read(contactsListProvider);
      expect(updatedState.contacts.length, 3);
      
      // Sort verify: 'అనిల్' (Anil) starts with 'అ' and should be first, then 'రమేష్', then 'సంతోష్'
      expect(updatedState.contacts[0].name, 'అనిల్');
      expect(updatedState.contacts[1].name, 'రమేష్');
      expect(updatedState.contacts[2].name, 'సంతోష్');
    });

    test('2. Telugu dynamic search filtering', () async {
      final notifier = container.read(contactsListProvider.notifier);
      await notifier.fetchContacts();

      // Search 'రమ' (matches రమేష్)
      notifier.search('రమ');
      var state = container.read(contactsListProvider);
      expect(state.filteredContacts.length, 1);
      expect(state.filteredContacts.first.name, 'రమేష్');

      // Search phone number digit
      notifier.search('91234');
      state = container.read(contactsListProvider);
      expect(state.filteredContacts.length, 1);
      expect(state.filteredContacts.first.name, 'అనిల్');
    });

    test('3. Edit contact updates state cleanly', () async {
      final notifier = container.read(contactsListProvider.notifier);
      await notifier.fetchContacts();

      final success = await notifier.updateContact('1', 'రాము', '9876543211');
      expect(success, true);

      final state = container.read(contactsListProvider);
      expect(state.contacts.any((element) => element.name == 'రాము'), true);
      expect(state.contacts.any((element) => element.name == 'రమేష్'), false);
    });

    test('4. Delete contact removes from state', () async {
      final notifier = container.read(contactsListProvider.notifier);
      await notifier.fetchContacts();

      final success = await notifier.deleteContact('3');
      expect(success, true);

      final state = container.read(contactsListProvider);
      expect(state.contacts.length, 2);
      expect(state.contacts.any((element) => element.name == 'అనిల్'), false);
    });
  });
}
