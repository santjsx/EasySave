import 'package:flutter/material.dart';
import 'colors.dart';

/// Complete accessible typography design system for EasyConnect.
/// Enforces Google's Noto Sans Telugu as the core font family to prevent budget devices from displaying boxes.
/// Strict rule: No text size falls below 18sp. Every style specifies `height: 1.5` to give Telugu script breathing room.
class AppTypography {
  AppTypography._(); // Prevent instantiation

  static const String fontFamily = 'NotoSansTelugu';

  /// Standard default text style parameters.
  static const TextStyle _base = TextStyle(
    fontFamily: fontFamily,
    color: AppDesignColors.textPrimary,
    height: 1.5, // Non-negotiable vertical space to avoid script clipping
    leadingDistribution: TextLeadingDistribution.even,
  );

  /// Top navigation bar or dashboard title: 26sp, bold.
  /// Max-visibility app banner.
  static final TextStyle appName = _base.copyWith(
    fontSize: 26,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  /// Primary focus text on voice and keypad pages: 28sp, semi-bold.
  /// The single, main focus label of a screen.
  static final TextStyle primaryLabel = _base.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w600,
  );

  /// Confirm name screen display: 32sp, extra-bold.
  /// Focuses attention on verifying if STT parsed correctly.
  static final TextStyle confirmedName = _base.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w700,
  );

  /// Main green header on success screen: 32sp, extra-bold.
  /// Clearly reports positive flow completion.
  static final TextStyle successHeading = _base.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    color: AppDesignColors.success,
  );

  /// Core action buttons text: 24sp, extra-bold.
  /// Legible on solid Amber or sandalwood outline buttons from a distance.
  static final TextStyle buttonText = _base.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
  );

  /// Card section headers, list title headers: 22sp, medium.
  /// Subdivides widgets dynamically.
  static final TextStyle sectionHeader = _base.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w500,
  );

  /// Core descriptive paragraphs, permissions overlays, dialogue contents: 20sp, regular.
  /// Highly readable base body size.
  static final TextStyle bodyText = _base.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w400,
  );

  /// Sandstone secondary captions, sub-card descriptors: 18sp, regular.
  /// Absolute smallest size allowed in the application.
  static final TextStyle secondaryText = _base.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppDesignColors.textSecondary,
  );

  /// Input fields default placeholders: 18sp, regular.
  static final TextStyle hintText = _base.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w400,
    color: AppDesignColors.textSecondary,
  );

  /// Numeric circular keypad numbers: 32sp, semi-bold.
  /// Ensures tactile digits are fully legible.
  static final TextStyle keypadDigit = _base.copyWith(
    fontSize: 32,
    fontWeight: FontWeight.w600,
  );

  /// Dialer number display bar: 40sp, extra-bold.
  /// Large, high-visibility number readout with extended tracking spacing.
  static final TextStyle numberDisplay = _base.copyWith(
    fontSize: 40,
    fontWeight: FontWeight.w700,
    letterSpacing: 4.0,
  );
}
