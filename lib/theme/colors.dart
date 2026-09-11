import 'package:flutter/material.dart';

/// Complete accessible color design system for EasySave.
/// Enforces high-contrast warm cultural tones (turmeric, sandalwood, and terracotta).
/// All text colors on surfaces meet WCAG AAA contrast rules (≥ 7:1).
class AppDesignColors {
  AppDesignColors._(); // Prevent instantiation

  // -------------------------------------------------------------
  // Semantic Color Palette
  // -------------------------------------------------------------

  /// Warm Turmeric Amber: Main CTA, pulsing capture buttons, active states.
  static const Color primary = Color(0xFFC86A2B);

  /// Terracotta Mud: Active borders, pressed states, focused icons.
  static const Color primaryDark = Color(0xFF8F481B);

  /// Warm Sandalwood Highlight: Inactive cards, light buttons background.
  static const Color primaryLight = Color(0xFFFBEEDD);

  /// Sandstone off-white: Global background color.
  /// Warm, highly comfortable for elderly eyes, reduces glare in bright sunlight.
  static const Color surface = Color(0xFFFDFBF7);

  /// High-contrast clean white: Content cards and popup overlays.
  static const Color surfaceCard = Color(0xFFFFFFFF);

  /// Clay Warm Gray: Numeric keypad background tiles, neutral tags.
  static const Color surfaceMuted = Color(0xFFF3EDE2);

  /// Deep Charcoal: Primary text color for all names, labels, and titles.
  /// Ensures exceptional AAA contrast (≥ 16:1) against surface and surfaceCard.
  static const Color textPrimary = Color(0xFF1C140D);

  /// Sandalwood Charcoal: Secondary labels, description subtitles, helper captions.
  /// Meets high-contrast ratios (≥ 5.5:1) for readable supporting text.
  static const Color textSecondary = Color(0xFF5E5043);

  /// Sage / Call Green: For direct call buttons, successful checkmarks, positive states.
  static const Color success = Color(0xFF2E7D32);

  /// Pale Sage: Success screens background fill.
  static const Color successLight = Color(0xFFE8F5E9);

  /// WhatsApp Brand Teal/Green: Distinctive tactile WhatsApp actions.
  static const Color whatsapp = Color(0xFF128C7E);

  /// Pale WhatsApp Teal: Background highlight for WhatsApp cards.
  static const Color whatsappLight = Color(0xFFE0F2F1);

  /// Terracotta Brick / Crimson: Error alerts, missed calls, delete icons.
  static const Color error = Color(0xFFC62828);

  /// Pale Brick: Error warnings background fill.
  static const Color errorLight = Color(0xFFFFEBEE);

  /// Soft cream line: Card borders, item separating lines.
  static const Color divider = Color(0xFFE6DCD1);

  // -------------------------------------------------------------
  // Semantic Intent Gradients
  // -------------------------------------------------------------

  /// Warm amber gradient used for the pulsing microphone voice capture screen.
  static const LinearGradient warmMicGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );
}
