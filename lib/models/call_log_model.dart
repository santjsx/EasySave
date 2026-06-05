import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../theme/colors.dart';

/// Supported types of calls mapped directly from native Android triggers.
enum CallEntryType {
  incoming,
  outgoing,
  missed,
  rejected,
}

/// Domain model representing a caller log entry for the Recent Calls feature.
class CallLogEntry {
  final String id;
  final String phoneNumber;
  final String contactName;
  final CallEntryType callType;
  final DateTime timestamp;
  final int duration; // in seconds
  final bool isSavedContact;
  final int callCount; // used to group consecutive duplicate calls

  const CallLogEntry({
    required this.id,
    required this.phoneNumber,
    this.contactName = '',
    required this.callType,
    required this.timestamp,
    required this.duration,
    required this.isSavedContact,
    this.callCount = 1,
  });

  CallLogEntry copyWith({
    String? id,
    String? phoneNumber,
    String? contactName,
    CallEntryType? callType,
    DateTime? timestamp,
    int? duration,
    bool? isSavedContact,
    int? callCount,
  }) {
    return CallLogEntry(
      id: id ?? this.id,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      contactName: contactName ?? this.contactName,
      callType: callType ?? this.callType,
      timestamp: timestamp ?? this.timestamp,
      duration: duration ?? this.duration,
      isSavedContact: isSavedContact ?? this.isSavedContact,
      callCount: callCount ?? this.callCount,
    );
  }

  /// Friendly Telugu description of the Call Type (non-machine translation).
  String get telugifiedCallType {
    switch (callType) {
      case CallEntryType.incoming:
        return 'వచ్చిన కాల్'; // Incoming: "Incoming call"
      case CallEntryType.outgoing:
        return 'చేసిన కాల్';   // Outgoing: "Made call"
      case CallEntryType.missed:
        return 'మిస్ అయిన కాల్'; // Missed: "Missed call"
      case CallEntryType.rejected:
        return 'కట్ చేసిన కాల్'; // Rejected: "Cut call" / "Rejected call"
    }
  }

  /// High contrast semantic color representation for caller types.
  Color get typeColor {
    switch (callType) {
      case CallEntryType.missed:
        return AppDesignColors.error; // Red for Missed calls (high attention)
      case CallEntryType.incoming:
        return AppDesignColors.success; // Green for Incoming
      case CallEntryType.outgoing:
        return Colors.blue[700]!; // High-contrast Blue for Outgoing
      case CallEntryType.rejected:
        return AppDesignColors.textSecondary; // Dull Grey for Rejected
    }
  }

  /// High contrast accessible icon representation for caller types.
  IconData get typeIcon {
    switch (callType) {
      case CallEntryType.incoming:
        return Icons.call_received_rounded;
      case CallEntryType.outgoing:
        return Icons.call_made_rounded;
      case CallEntryType.missed:
        return Icons.call_missed_rounded;
      case CallEntryType.rejected:
        return Icons.call_missed_outgoing_rounded;
    }
  }

  /// Formatted elderly-friendly timestamp representation (e.g. "10:30 AM" or "02:15 PM").
  String get telugifiedTime {
    return DateFormat('hh:mm a').format(timestamp);
  }

  /// Generates a warm primary color for contact avatars.
  Color get avatarColor {
    return isSavedContact
        ? _generateWarmColor(contactName)
        : AppDesignColors.textSecondary.withValues(alpha: 0.12);
  }

  /// Helper to generate a deterministic warm primary color based on contact name.
  static Color _generateWarmColor(String name) {
    if (name.isEmpty) return AppDesignColors.primary;
    final int hash = name.codeUnits.fold(0, (prev, element) => prev + element);
    final List<Color> warmPalette = [
      AppDesignColors.primary,
      const Color(0xFFD48B47), // Terracotta Amber
      const Color(0xFFC86B4F), // Burnt Clay
      const Color(0xFF7A9E7E), // Sage Green
      const Color(0xFF8C75B3), // Dusty Lavender
      const Color(0xFFC06C84), // Desert Rose
    ];
    return warmPalette[hash % warmPalette.length];
  }
}
