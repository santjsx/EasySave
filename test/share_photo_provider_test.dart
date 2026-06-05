import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:amma_nanna_app/models/contact_model.dart';
import 'package:amma_nanna_app/providers/media_provider.dart';
import 'package:amma_nanna_app/services/contacts_service.dart';
import 'package:amma_nanna_app/services/media_service.dart';
import 'package:amma_nanna_app/services/whatsapp_service.dart';

/// Fake mock implementation of ContactsService.
class FakeContactsService implements ContactsService {
  List<ContactModel> mockContacts = [];
  @override
  Future<List<ContactModel>> getContacts() async => mockContacts;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake mock implementation of MediaService.
class FakeMediaService implements MediaService {
  String? mockPickedPath;
  String? mockCapturedPath;
  bool shouldThrowPermission = false;
  bool shouldThrowUnsupported = false;
  bool shouldThrowCorrupted = false;

  @override
  Future<String?> pickPhoto() async {
    if (shouldThrowPermission) throw const PhotoPermissionDeniedException();
    if (shouldThrowUnsupported) throw const UnsupportedFileException();
    if (shouldThrowCorrupted) throw const CorruptedImageException();
    return mockPickedPath;
  }

  @override
  Future<String?> capturePhoto() async {
    if (shouldThrowPermission) throw const PhotoPermissionDeniedException('కెమెరా ఉపయోగించడానికి అనుమతి లేదు');
    if (shouldThrowUnsupported) throw const UnsupportedFileException();
    if (shouldThrowCorrupted) throw const CorruptedImageException();
    return mockCapturedPath;
  }

  @override
  Future<bool> checkAndRequestPhotosPermission() async => !shouldThrowPermission;

  @override
  Future<bool> checkAndRequestCameraPermission() async => !shouldThrowPermission;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake mock implementation of WhatsAppService.
class FakeWhatsAppService implements WhatsAppService {
  bool shareCalled = false;
  File? sharedPhoto;
  String? sharedPhone;

  FakeWhatsAppService();

  @override
  Future<void> sharePhoto(File photo, String phoneNumber) async {
    shareCalled = true;
    sharedPhoto = photo;
    sharedPhone = phoneNumber;
  }
}

void main() {
  group('WhatsApp Photo Share Wizard - Unit Tests', () {
    late FakeMediaService fakeMedia;
    late FakeContactsService fakeContacts;
    late FakeWhatsAppService fakeWhatsApp;
    late SharePhotoNotifier notifier;

    setUp(() {
      fakeMedia = FakeMediaService();
      fakeContacts = FakeContactsService();
      fakeWhatsApp = FakeWhatsAppService();
      notifier = SharePhotoNotifier(
        mediaService: fakeMedia,
        contactsService: fakeContacts,
        whatsappService: fakeWhatsApp,
      );
    });

    test('1. Image path and reset states configurations', () {
      expect(notifier.state.selectedImagePath, isEmpty);

      notifier.setSelectedImagePath('test_gallery_path.jpg');
      expect(notifier.state.selectedImagePath, equals('test_gallery_path.jpg'));

      notifier.resetState();
      expect(notifier.state.selectedImagePath, isEmpty);
      expect(notifier.state.selectedContact, isNull);
    });

    test('2. Photo selection updates state path', () async {
      fakeMedia.mockPickedPath = 'picked_gallery_image.png';

      final success = await notifier.selectPhotoFromGallery();

      expect(success, isTrue);
      expect(notifier.state.selectedImagePath, equals('picked_gallery_image.png'));
    });

    test('3. Fetch contacts gets fresh lists records', () async {
      fakeContacts.mockContacts = [
        const ContactModel(
          id: '1',
          name: 'రవి కుమార్',
          phone: '9876543210',
          avatarColor: Colors.amber,
        ),
      ];

      await notifier.fetchWhatsAppEligibleContacts();

      expect(notifier.state.eligibleContacts.length, equals(1));
      expect(notifier.state.eligibleContacts.first.name, equals('రవి కుమార్'));
    });

    test('4. Share dispatch checks missing arguments', () async {
      notifier.setSelectedImagePath('');
      
      final success = await notifier.dispatchWhatsAppShare();

      expect(success, isFalse);
      expect(notifier.state.errorMessage, equals('సరైన వివరాలు ఇవ్వండి'));
      expect(fakeWhatsApp.shareCalled, isFalse);
    });

    test('5. Successful Share Dispatch invokes WhatsAppService', () async {
      notifier.setSelectedImagePath('share_image.jpg');
      notifier.selectRecipient(
        const ContactModel(
          id: '1',
          name: 'రవి రావు',
          phone: '9876543210',
          avatarColor: Colors.amber,
        ),
      );

      final success = await notifier.dispatchWhatsAppShare();

      expect(success, isTrue);
      expect(fakeWhatsApp.shareCalled, isTrue);
      expect(fakeWhatsApp.sharedPhone, equals('9876543210'));
    });
  });
}
