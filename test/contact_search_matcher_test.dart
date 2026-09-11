import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amma_nanna_app/models/contact_model.dart';
import 'package:amma_nanna_app/utils/contact_search_matcher.dart';

void main() {
  group('ContactSearchMatcher - Algorithm Tests', () {
    final List<ContactModel> testContacts = [
      const ContactModel(
        id: '1',
        name: 'రమేష్ రావు',
        phone: '+91 98765-43210',
        avatarColor: Colors.blue,
      ),
      const ContactModel(
        id: '2',
        name: 'సురేష్ కుమార్',
        phone: '9123456780',
        avatarColor: Colors.green,
      ),
      const ContactModel(
        id: '3',
        name: 'అమ్మ',
        phone: '9988776655',
        avatarColor: Colors.red,
      ),
      const ContactModel(
        id: '4',
        name: 'రాము',
        phone: '9848012345',
        avatarColor: Colors.orange,
      ),
    ];

    test('1. Empty query returns all contacts with no similar matches', () {
      final result = ContactSearchMatcher.evaluate(testContacts, '');
      expect(result.exactMatches.length, equals(4));
      expect(result.similarMatches, isEmpty);
    });

    test('2. Exact and prefix name match ranks in exactMatches', () {
      final result = ContactSearchMatcher.evaluate(testContacts, 'రమేష్');
      expect(result.exactMatches.length, equals(1));
      expect(result.exactMatches.first.name, equals('రమేష్ రావు'));
    });

    test('3. Token/Word prefix match finds contact by middle/last word', () {
      final result = ContactSearchMatcher.evaluate(testContacts, 'రావు');
      expect(result.exactMatches.length, equals(1));
      expect(result.exactMatches.first.name, equals('రమేష్ రావు'));
    });

    test('4. Phone number normalization matches formatted numbers', () {
      // "+91 98765-43210" searched with "98765"
      final result = ContactSearchMatcher.evaluate(testContacts, '98765');
      expect(result.exactMatches.length, equals(1));
      expect(result.exactMatches.first.name, equals('రమేష్ రావు'));
    });

    test('5. Fuzzy Levenshtein match identifies spelling variant in similarMatches', () {
      // Search "సురేస్" (with స instead of ష)
      final result = ContactSearchMatcher.evaluate(testContacts, 'సురేస్');
      expect(result.similarMatches.any((c) => c.name == 'సురేష్ కుమార్'), isTrue);
    });

    test('6. Transliteration match maps Latin script to Telugu contact', () {
      // User speaks or types "Amma"
      final result = ContactSearchMatcher.evaluate(testContacts, 'Amma');
      expect(result.exactMatches.any((c) => c.name == 'అమ్మ'), isTrue);
    });

    test('7. Token extension matches similar contacts', () {
      // Search "రాముడు" matches contact "రాము"
      final result = ContactSearchMatcher.evaluate(testContacts, 'రాముడు');
      expect(result.similarMatches.any((c) => c.name == 'రాము'), isTrue);
    });
  });
}
