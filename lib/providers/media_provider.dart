import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/contact_model.dart';
import '../services/contacts_service.dart';
import '../services/media_service.dart';
import '../services/whatsapp_service.dart';
import '../utils/contact_search_matcher.dart';
import 'system_provider.dart';

/// Flow state model for the WhatsApp Photo Sharer.
class SharePhotoState {
  final List<ContactModel> allContacts;
  final List<ContactModel> eligibleContacts;
  final List<ContactModel> similarContacts;
  final String searchQuery;
  final String selectedImagePath;
  final ContactModel? selectedContact;
  final bool isLoading;
  final String errorMessage;

  const SharePhotoState({
    this.allContacts = const [],
    this.eligibleContacts = const [],
    this.similarContacts = const [],
    this.searchQuery = '',
    this.selectedImagePath = '',
    this.selectedContact,
    this.isLoading = false,
    this.errorMessage = '',
  });

  SharePhotoState copyWith({
    List<ContactModel>? allContacts,
    List<ContactModel>? eligibleContacts,
    List<ContactModel>? similarContacts,
    String? searchQuery,
    String? selectedImagePath,
    ContactModel? selectedContact,
    bool? isLoading,
    String? errorMessage,
  }) {
    return SharePhotoState(
      allContacts: allContacts ?? this.allContacts,
      eligibleContacts: eligibleContacts ?? this.eligibleContacts,
      similarContacts: similarContacts ?? this.similarContacts,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedImagePath: selectedImagePath ?? this.selectedImagePath,
      selectedContact: selectedContact ?? this.selectedContact,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

/// State notifier to manage gallery scans, path cache bindings, and direct intent sharing launches.
class SharePhotoNotifier extends StateNotifier<SharePhotoState> {
  final MediaService _mediaService;
  final ContactsService _contactsService;
  final WhatsAppService _whatsappService;

  SharePhotoNotifier({
    required MediaService mediaService,
    required ContactsService contactsService,
    required WhatsAppService whatsappService,
  })  : _mediaService = mediaService,
        _contactsService = contactsService,
        _whatsappService = whatsappService,
        super(const SharePhotoState());

  // -------------------------------------------------------------
  // Photo Selection (Gallery / Camera actions)
  // -------------------------------------------------------------

  /// Launches the device photo picker dialog.
  Future<bool> selectPhotoFromGallery() async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      final String? pickedPath = await _mediaService.pickPhoto();
      
      if (pickedPath != null) {
        state = state.copyWith(
          selectedImagePath: pickedPath,
          isLoading: false,
        );
        return true;
      }
      
      state = state.copyWith(isLoading: false);
      return false;
    } on PhotoPermissionDeniedException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } on UnsupportedFileException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } on CorruptedImageException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      debugPrint('Select gallery photo failed: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'ఫోటో ఎంచుకోవడం కుదరలేదు', // Failed to pick photo
      );
      return false;
    }
  }

  /// Launches the system camera to snap a direct picture.
  Future<bool> selectPhotoFromCamera() async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      final String? capturedPath = await _mediaService.capturePhoto();
      
      if (capturedPath != null) {
        state = state.copyWith(
          selectedImagePath: capturedPath,
          isLoading: false,
        );
        return true;
      }
      
      state = state.copyWith(isLoading: false);
      return false;
    } on PhotoPermissionDeniedException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } on UnsupportedFileException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } on CorruptedImageException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message,
      );
      return false;
    } catch (e) {
      debugPrint('Capture camera photo failed: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'ఫోటో తీయడం కుదరలేదు', // Failed to capture photo
      );
      return false;
    }
  }

  /// Sets selected path manually (if flat grid assets are tapped).
  void setSelectedImagePath(String path) {
    state = state.copyWith(selectedImagePath: path, errorMessage: '');
  }

  // -------------------------------------------------------------
  // Recipient Contact Picker
  // -------------------------------------------------------------

  /// Loads eligible contacts fresh on screen load (Rule 11).
  Future<void> fetchWhatsAppEligibleContacts() async {
    state = state.copyWith(isLoading: true, errorMessage: '');
    try {
      final List<ContactModel> freshContacts = await _contactsService.getContacts();
      final result = ContactSearchMatcher.evaluate(freshContacts, state.searchQuery);
      state = state.copyWith(
        allContacts: freshContacts,
        eligibleContacts: result.exactMatches,
        similarContacts: result.similarMatches,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Fetch share contacts failed: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'పరిచయాలు చదవడం కుదరలేదు', // Failed to read contacts
      );
    }
  }

  /// Filters recipient contacts by search query with ranked and similar matching.
  void search(String query) {
    final result = ContactSearchMatcher.evaluate(state.allContacts, query);
    state = state.copyWith(
      searchQuery: query,
      eligibleContacts: result.exactMatches,
      similarContacts: result.similarMatches,
    );
  }

  /// Sets active recipient contact.
  void selectRecipient(ContactModel contact) {
    state = state.copyWith(selectedContact: contact, errorMessage: '');
  }

  // -------------------------------------------------------------
  // WhatsApp Direct Intent Dispatching
  // -------------------------------------------------------------

  /// Performs photo size bounds processing and launches standard sharing intents.
  Future<bool> dispatchWhatsAppShare() async {
    if (state.selectedImagePath.isEmpty || state.selectedContact == null) {
      state = state.copyWith(errorMessage: 'సరైన వివరాలు ఇవ్వండి');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: '');

    try {
      final File targetFile = File(state.selectedImagePath);
      final String phone = state.selectedContact!.phone;

      await _whatsappService.sharePhoto(targetFile, phone);
      
      state = state.copyWith(isLoading: false);
      return true;
    } on WhatsAppNotInstalledException catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.message, // Shows: WhatsApp ఇన్స్టాల్ అయిలేదు
      );
      return false;
    } catch (e) {
      debugPrint('WhatsApp sharing execution crashed: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'WhatsApp లో పంపించడం కుదరలేదు',
      );
      return false;
    }
  }

  /// Flow variables reset.
  void resetState() {
    state = const SharePhotoState();
  }
}

/// Declares the auto-disposing share photo notifier provider.
final sharePhotoProvider = StateNotifierProvider.autoDispose<SharePhotoNotifier, SharePhotoState>((ref) {
  final media = ref.read(mediaServiceProvider);
  final contacts = ref.read(contactsServiceProvider);
  final whatsapp = ref.read(whatsappServiceProvider);

  return SharePhotoNotifier(
    mediaService: media,
    contactsService: contacts,
    whatsappService: whatsapp,
  );
});
