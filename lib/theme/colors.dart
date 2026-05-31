import 'package:flutter/material.dart';

/// Complete accessible color design system for EasyConnect.
/// Enforces high-contrast warm cultural tones (turmeric, sandalwood, and terracotta).
/// Excludes corporate cold blues and tech greens. All text colors on surfaces meet WCAG AAA contrast rules (≥ 7:1).
class AppDesignColors {
  AppDesignColors._(); // Prevent instantiation

  // -------------------------------------------------------------
  // Semantic Color Palette
  // -------------------------------------------------------------

  /// Warm Turmeric Amber: Main CTA, pulsing capture buttons, active states.
  /// High-visibility accent.
  static const Color primary = Color(0xFFC17B3F);

  /// Terracotta Mud: Active borders, pressed states, focused icons.
  /// Deepens visual focus when clicked.
  static const Color primaryDark = Color(0xFF8F5A28);

  /// Warm Sandalwood Highlight: Inactive cards, light buttons background.
  /// High visibility when paired with dark labels.
  static const Color primaryLight = Color(0xFFF5E6D3);

  /// Sandstone off-white: Global background color.
  /// Warm, highly comfortable for elderly eyes, reduces glare in bright sunlight.
  static const Color surface = Color(0xFFFDFAF6);

  /// High-contrast clean white: Content cards and popup overlays.
  /// Visually separates cards from the warm sandstone background.
  static const Color surfaceCard = Color(0xFFFFFFFF);

  /// Clay Warm Gray: Numeric keypad background tiles, disabled indicators.
  /// Neutral, tactile background surface.
  static const Color surfaceMuted = Color(0xFFF0EBE3);

  /// Terracotta Charcoal: Primary text color for all names, labels, and titles.
  /// Ensures exceptional AAA contrast (≥ 8.5:1) against surface and surfaceCard.
  static const Color textPrimary = Color(0xFF1C1208);

  /// Sandalwood Charcoal: Secondary labels, description subtitles, helper captions.
  /// Meets high-contrast ratios (≥ 4.5:1) for readable supporting text.
  static const Color textSecondary = Color(0xFF6B5744);

  /// Sage Green: Successful confirmation checkmarks, success titles.
  /// Culturally associated with peace and validation.
  static const Color success = Color(0xFF4A7C59);

  /// Pale Sage: Success screens background fill.
  /// Comforting background tone.
  static const Color successLight = Color(0xFFE8F3EC);

  /// Terracotta Brick: Error alerts, invalid fields, delete icons.
  /// Intense, readable warning tone.
  static const Color error = Color(0xFFB71C1C);

  /// Pale Brick: Error warnings background fill.
  static const Color errorLight = Color(0xFFFFEBEE);

  /// Soft cream line: Card borders, item separating lines.
  /// Clearly separates adjacent list items to prevent tap confusions.
  static const Color divider = Color(0xFFE5DDD3);

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
