import 'package:call_log/call_log.dart' as native;
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../models/call_log_model.dart';
import '../models/contact_model.dart';
import 'contacts_service.dart';

/// Service layer responsible for accessing, parsing, and caching system call logs.
class CallLogService {
  final ContactsService _contactsService;

  CallLogService(this._contactsService);

  /// Asks the OS for call log reading permissions.
  Future<bool> checkAndRequestPermission() async {
    try {
      final status = await Permission.phone.request();
      debugPrint('CallLog permission check returned: $status');
      return status.isGranted;
    } catch (e) {
      debugPrint('CallLog permission query crashed: $e');
      return false;
    }
  }

  /// Fetches system call history, matches phone numbers against cached contacts,
  /// and merges consecutive duplicate logs to optimize rendering performance.
  Future<List<CallLogEntry>> getRecentCalls() async {
    // 1. Enforce permission verification
    final bool hasPermission = await Permission.phone.isGranted;
    if (!hasPermission) {
      debugPrint('Permissions missing for fetching system call logs');
      throw Exception('Call log permission not granted');
    }

    try {
      // 2. Fetch system call history via the call_log package
      // Fetch a maximum of 500 records to maintain extreme performance boundaries
      final Iterable<native.CallLogEntry> nativeLogs = await native.CallLog.get();

      // 3. Fetch device contacts once for cache generation (O(1) lookups)
      List<ContactModel> deviceContacts = [];
      try {
        deviceContacts = await _contactsService.getContacts();
      } catch (e) {
        debugPrint('Address book read failed inside call log fetcher: $e');
      }

      // Build the fast-lookup matching maps
      final Map<String, String> exactMatchMap = {};
      final Map<String, String> last10MatchMap = {};

      for (var contact in deviceContacts) {
        final String cleanPhone = _normalizePhoneNumber(contact.phone);
        exactMatchMap[cleanPhone] = contact.name;

        final String last10 = _extractLast10Digits(cleanPhone);
        if (last10.length == 10) {
          last10MatchMap[last10] = contact.name;
        }
      }

      final List<CallLogEntry> mappedList = [];

      // 4. Parse system logs and execute contacts matching
      for (var entry in nativeLogs) {
        final String rawNumber = entry.number ?? '';
        final String cleanNumber = _normalizePhoneNumber(rawNumber);

        // Edge Cases: Skip or handle empty, blocked, or private numbers
        if (rawNumber.isEmpty ||
            rawNumber.toLowerCase().contains('private') ||
            rawNumber.toLowerCase().contains('unknown') ||
            rawNumber.contains('-1') ||
            rawNumber.contains('-2')) {
          continue; // Filter private/blocked callers to keep clean view
        }

        // Match contact name from maps (prefer exact match, fallback to last 10 digits)
        String matchedName = '';
        bool isSaved = false;

        if (exactMatchMap.containsKey(cleanNumber)) {
          matchedName = exactMatchMap[cleanNumber]!;
          isSaved = true;
        } else {
          final String last10 = _extractLast10Digits(cleanNumber);
          if (last10.length == 10 && last10MatchMap.containsKey(last10)) {
            matchedName = last10MatchMap[last10]!;
            isSaved = true;
          }
        }

        // Map native call type to local enum representation
        final CallEntryType localType = _mapNativeCallType(entry.callType);

        final DateTime logDate = entry.timestamp != null
            ? DateTime.fromMillisecondsSinceEpoch(entry.timestamp!)
            : DateTime.now();

        mappedList.add(
          CallLogEntry(
            id: '${entry.timestamp}_${entry.number}',
            phoneNumber: rawNumber,
            contactName: matchedName,
            callType: localType,
            timestamp: logDate,
            duration: entry.duration ?? 0,
            isSavedContact: isSaved,
          ),
        );

        // Cap at 500 entries for safety and extreme performance
        if (mappedList.length >= 500) break;
      }

      // 5. Group consecutive duplicates in the list (Rule 9/11 matching optimization)
      return _groupConsecutiveDuplicateCalls(mappedList);
    } catch (e) {
      debugPrint('Native call log parser exception encountered: $e');
      throw Exception('కాల్ రికార్డులను లోడ్ చేయడం కుదరలేదు'); // Failed to load call logs in Telugu
    }
  }

  /// Groups consecutive calls from the exact same phone number and call type.
  List<CallLogEntry> _groupConsecutiveDuplicateCalls(List<CallLogEntry> sourceList) {
    if (sourceList.isEmpty) return [];

    final List<CallLogEntry> groupedList = [];
    CallLogEntry currentGroup = sourceList.first;

    for (int i = 1; i < sourceList.length; i++) {
      final CallLogEntry nextEntry = sourceList[i];

      // Merge if number and type are consecutive matches
      if (nextEntry.phoneNumber == currentGroup.phoneNumber &&
          nextEntry.callType == currentGroup.callType) {
        currentGroup = currentGroup.copyWith(
          callCount: currentGroup.callCount + 1,
          // Keep the latest timestamp
          timestamp: currentGroup.timestamp.isAfter(nextEntry.timestamp)
              ? currentGroup.timestamp
              : nextEntry.timestamp,
        );
      } else {
        groupedList.add(currentGroup);
        currentGroup = nextEntry;
      }
    }

    // Add the final remaining group
    groupedList.add(currentGroup);
    return groupedList;
  }

  /// Maps the native call type enum to our local CallEntryType enum safely.
  CallEntryType _mapNativeCallType(native.CallType? nativeType) {
    if (nativeType == null) return CallEntryType.incoming;
    switch (nativeType) {
      case native.CallType.incoming:
        return CallEntryType.incoming;
      case native.CallType.outgoing:
        return CallEntryType.outgoing;
      case native.CallType.missed:
        return CallEntryType.missed;
      case native.CallType.rejected:
        return CallEntryType.rejected;
      default:
        return CallEntryType.incoming; // Default fallback to incoming
    }
  }

  /// Cleans and normalizes raw phone strings.
  String _normalizePhoneNumber(String number) {
    return number.replaceAll(RegExp(r'[^\d+]+'), '');
  }

  /// Extracts the last 10 digits for prefix-free country comparisons.
  String _extractLast10Digits(String cleanedNumber) {
    final digitsOnly = cleanedNumber.replaceAll(RegExp(r'[^\d]+'), '');
    if (digitsOnly.length > 10) {
      return digitsOnly.substring(digitsOnly.length - 10);
    }
    return digitsOnly;
  }
}
