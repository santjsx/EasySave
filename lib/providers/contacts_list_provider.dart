import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/contact_model.dart';
import '../services/contacts_service.dart';
import '../utils/contact_search_matcher.dart';
import 'system_provider.dart';

/// State class for the Contacts List Manager view.
class ContactsListState {
  final List<ContactModel> contacts;
  final List<ContactModel> filteredContacts;
  final List<ContactModel> similarContacts;
  final bool isLoading;
  final String errorMessage;
  final String searchQuery;

  const ContactsListState({
    this.contacts = const [],
    this.filteredContacts = const [],
    this.similarContacts = const [],
    this.isLoading = false,
    this.errorMessage = '',
    this.searchQuery = '',
  });

  ContactsListState copyWith({
    List<ContactModel>? contacts,
    List<ContactModel>? filteredContacts,
    List<ContactModel>? similarContacts,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
  }) {
    return ContactsListState(
      contacts: contacts ?? this.contacts,
      filteredContacts: filteredContacts ?? this.filteredContacts,
      similarContacts: similarContacts ?? this.similarContacts,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

/// State notifier class managing contacts list, filtering, and native edits/deletions.
class ContactsListNotifier extends StateNotifier<ContactsListState> {
  final ContactsService _contactsService;

  ContactsListNotifier({
    required ContactsService contactsService,
  })  : _contactsService = contactsService,
        super(const ContactsListState()) {
    fetchContacts(); // Automatically trigger initial load
  }

  /// Fetches device contacts and updates states.
  Future<void> fetchContacts() async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      final List<ContactModel> list = await _contactsService.getContacts();
      final result = ContactSearchMatcher.evaluate(list, state.searchQuery);
      state = state.copyWith(
        contacts: list,
        filteredContacts: result.exactMatches,
        similarContacts: result.similarMatches,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Fetch contacts failed: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'పరిచయాలు చదవడం కుదరలేదు',
      );
    }
  }

  /// Filters contacts list by a search query (checks name and phone number with ranked and similar matches).
  void search(String query) {
    final result = ContactSearchMatcher.evaluate(state.contacts, query);
    state = state.copyWith(
      searchQuery: query,
      filteredContacts: result.exactMatches,
      similarContacts: result.similarMatches,
    );
  }

  /// Deletes a contact and refreshes the address book.
  Future<bool> deleteContact(String id) async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      final success = await _contactsService.deleteContact(id);
      if (success) {
        await fetchContacts();
        return true;
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'డిలీట్ చేయడం కుదరలేదు');
        return false;
      }
    } catch (e) {
      debugPrint('Delete contact failed: $e');
      state = state.copyWith(isLoading: false, errorMessage: 'డిలీట్ చేయడం కుదరలేదు');
      return false;
    }
  }

  /// Updates contact details and refreshes the address book.
  Future<bool> updateContact(String id, String newName, String newPhone) async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      final success = await _contactsService.updateContact(id, newName, newPhone);
      if (success) {
        // Optimistically update the list in-memory to prevent slow Android Contacts Provider re-indexing lag/flickering
        final updatedContacts = state.contacts.map((contact) {
          if (contact.id == id) {
            return contact.copyWith(
              name: newName,
              phone: newPhone.replaceAll(RegExp(r'[^\d+]+'), ''),
              avatarColor: ContactModel.generateWarmColor(newName),
            );
          }
          return contact;
        }).toList();

        // Sort the contacts list alphabetically to match our design system Collation (Rule 3)
        updatedContacts.sort((a, b) => a.name.compareTo(b.name));

        final result = ContactSearchMatcher.evaluate(updatedContacts, state.searchQuery);
        state = state.copyWith(
          contacts: updatedContacts,
          filteredContacts: result.exactMatches,
          similarContacts: result.similarMatches,
          isLoading: false,
        );

        // Fetch fresh records in the background after a slight delay to let Android finalize indexing
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            fetchContacts();
          }
        });

        return true;
      } else {
        state = state.copyWith(isLoading: false, errorMessage: 'సేవ్ చేయడం కుదరలేదు');
        return false;
      }
    } catch (e) {
      debugPrint('Update contact failed: $e');
      state = state.copyWith(isLoading: false, errorMessage: 'సేవ్ చేయడం కుదరలేదు');
      return false;
    }
  }
}

/// Autodisposing state notifier provider for managing contacts list.
final contactsListProvider = StateNotifierProvider.autoDispose<ContactsListNotifier, ContactsListState>((ref) {
  final service = ref.read(contactsServiceProvider);
  return ContactsListNotifier(contactsService: service);
});
