import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amma_nanna_app/services/call_service.dart';

void main() {
  group('CallService - Unit Tests', () {
    test('1. sanitizePhoneNumber preserves leading + and removes all formatting', () {
      expect(
        CallService.sanitizePhoneNumber('+91 98765 43210'),
        equals('+919876543210'),
      );
      expect(
        CallService.sanitizePhoneNumber('+91-98765-43210'),
        equals('+919876543210'),
      );
      expect(
        CallService.sanitizePhoneNumber(' +91 (98765) 43210 '),
        equals('+919876543210'),
      );
    });

    test('2. sanitizePhoneNumber handles national 10-digit and landline numbers', () {
      expect(
        CallService.sanitizePhoneNumber('98765 43210'),
        equals('9876543210'),
      );
      expect(
        CallService.sanitizePhoneNumber('040 1234 5678'),
        equals('04012345678'),
      );
    });

    test('3. sanitizePhoneNumber returns empty string on whitespace or invalid input', () {
      expect(CallService.sanitizePhoneNumber(''), equals(''));
      expect(CallService.sanitizePhoneNumber('   '), equals(''));
      expect(CallService.sanitizePhoneNumber('abc-def'), equals(''));
      expect(CallService.sanitizePhoneNumber('++'), equals(''));
    });

    test('4. callServiceProvider provides CallService instance correctly', () {
      final container = ProviderContainer();
      final service = container.read(callServiceProvider);
      expect(service, isA<CallService>());
      container.dispose();
    });
  });
}
