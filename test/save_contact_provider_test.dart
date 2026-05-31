import 'package:flutter_test/flutter_test.dart';

import 'package:amma_nanna_app/providers/save_contact_provider.dart';
import 'package:amma_nanna_app/repository/contacts_repository.dart';
import 'package:amma_nanna_app/services/contacts_service.dart';
import 'package:amma_nanna_app/services/speech_service.dart';

/// Concrete Fake Contacts Service to mock address book saving.
class FakeContactsService implements ContactsService {
  bool isGranted = true;
  bool saveSuccess = true;
  List<Map<String, String>> savedList = [];

  FakeContactsService();

  @override
  Future<bool> checkAndRequestPermission({bool readonly = false}) async {
    return isGranted;
  }

  @override
  Future<bool> saveContact(String name, String phone) async {
    if (!isGranted) {
      throw const PermissionDeniedException();
    }
    if (saveSuccess) {
      savedList.add({'name': name, 'phone': phone});
    }
    return saveSuccess;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// Fake Speech Service to mock voice names.
class FakeSpeechService implements SpeechService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('Save Contact Wizard Notifier - Unit Tests', () {
    late FakeContactsService fakeContacts;
    late FakeSpeechService fakeSpeech;
    late SaveContactNotifier notifier;

    setUp(() {
      fakeContacts = FakeContactsService();
      fakeSpeech = FakeSpeechService();
      notifier = SaveContactNotifier(
        contactsService: fakeContacts,
        speechService: fakeSpeech,
      );
    });

    test('1. Digit entry and circular bounds constraints', () {
      expect(notifier.state.phoneNumber, isEmpty);

      // Add a single digit
      notifier.addDigit('9');
      expect(notifier.state.phoneNumber, equals('9'));

      // Add multiple digits
      notifier.addDigit('8');
      notifier.addDigit('7');
      expect(notifier.state.phoneNumber, equals('987'));

      // Enforce 10-digit bounds checking
      for (int i = 0; i < 15; i++) {
        notifier.addDigit('0');
      }
      expect(notifier.state.phoneNumber.length, equals(10));
      expect(notifier.state.phoneNumber, equals('9870000000'));
    });

    test('2. Tactile Keypad Backspace deletion', () {
      notifier.addDigit('9');
      notifier.addDigit('8');
      
      notifier.removeLastDigit();
      expect(notifier.state.phoneNumber, equals('9'));

      notifier.removeLastDigit();
      expect(notifier.state.phoneNumber, isEmpty);

      // Backspace on empty buffer does not crash
      expect(() => notifier.removeLastDigit(), returnsNormally);
    });

    test('3. Reset and wizard cleanup parameters mapping', () {
      notifier.addDigit('9');
      notifier.setManualName('రవి');

      expect(notifier.state.phoneNumber, equals('9'));
      expect(notifier.state.recognizedName, equals('రవి'));

      notifier.resetWizard();

      expect(notifier.state.phoneNumber, isEmpty);
      expect(notifier.state.recognizedName, isEmpty);
    });

    test('4. Commit Contact performs successful native write', () async {
      notifier.addDigit('9');
      notifier.addDigit('8');
      notifier.addDigit('7');
      notifier.addDigit('6');
      notifier.addDigit('5');
      notifier.addDigit('4');
      notifier.addDigit('3');
      notifier.addDigit('2');
      notifier.addDigit('1');
      notifier.addDigit('0');
      notifier.setManualName('రవి రావు');

      final success = await notifier.commitContact();

      expect(success, isTrue);
      expect(fakeContacts.savedList.length, equals(1));
      expect(fakeContacts.savedList.first['name'], equals('రవి రావు'));
      expect(fakeContacts.savedList.first['phone'], equals('9876543210'));
    });

    test('5. Missing inputs return error strings', () async {
      notifier.clearPhoneNumber();
      notifier.resetVoiceName();

      final success = await notifier.commitContact();

      expect(success, isFalse);
      expect(notifier.state.errorMessage, equals('సరైన వివరాలు ఇవ్వండి'));
    });
  });
}
