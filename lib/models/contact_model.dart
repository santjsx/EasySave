import 'package:flutter/material.dart';

/// Immutable model representing a saved phone contact on the device.
class ContactModel {
  final String id;
  final String name;
  final String phone;
  final Color avatarColor;

  const ContactModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.avatarColor,
  });

  /// Deterministically derives a warm avatar color from the contact name's hash.
  /// Enforces sandstones, turmeric, and terracotta warm colors, completely avoiding corporate cold blues.
  static Color generateWarmColor(String name) {
    final int hash = name.codeUnits.fold(0, (prev, element) => prev + element);
    
    const List<Color> warmPalette = [
      Color(0xFFC17B3F), // Turmeric Primary Amber
      Color(0xFF8F5A28), // Terracotta Brown
      Color(0xFFD69C6B), // Warm Sandstone
      Color(0xFFE4A054), // Sand Mustard
      Color(0xFFB06434), // Rich Earth
      Color(0xFF7A4A28), // Deep Mahogany
      Color(0xFFD88C55), // Burnt Orange
      Color(0xFF5B391E), // Sandal Charcoal
    ];

    return warmPalette[hash % warmPalette.length];
  }

  ContactModel copyWith({
    String? id,
    String? name,
    String? phone,
    Color? avatarColor,
  }) {
    return ContactModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      avatarColor: avatarColor ?? this.avatarColor,
    );
  }
}
