import 'package:flutter/material.dart';

/// Spacing design system tokens for EasyConnect.
/// Enforces high predictability, large padding, and massive touch targets to mitigate fine-motor tremors.
class AppSpacing {
  AppSpacing._(); // Prevent instantiation

  // -------------------------------------------------------------
  // Base Spacing Tokens (Scale)
  // -------------------------------------------------------------
  
  /// Extra Extra Small padding: 4.0 dp (subtle alignments)
  static const double xxs = 4.0;

  /// Extra Small padding: 8.0 dp (micro elements gap)
  static const double xs = 8.0;

  /// Small padding: 12.0 dp (inner card content spacing)
  static const double sm = 12.0;

  /// Medium padding: 16.0 dp (standard list tile gaps)
  static const double md = 16.0;

  /// Large padding: 20.0 dp (margins for inner widgets)
  static const double lg = 20.0;

  /// Extra Large padding: 24.0 dp (outer edge grid gutters)
  static const double xl = 24.0;

  /// Extra Extra Large padding: 32.0 dp (gaps between major layout elements)
  static const double xxl = 32.0;

  /// Triple Extra Large padding: 48.0 dp (gaps between functional cards)
  static const double xxxl = 48.0;

  /// Huge padding: 64.0 dp (separates interactive forms from bottom buttons)
  static const double huge = 64.0;

  // -------------------------------------------------------------
  // Layout Target Constraints
  // -------------------------------------------------------------

  /// Minimum interactive touch target bounds (Rule 4: minimum 56dp)
  static const double minTouchTarget = 56.0;

  /// Microphone primary touch target: 96.0 dp diameter (Rule 4 constraint)
  static const double micTouchTarget = 96.0;

  /// Circular custom dialer keypad keys: 72.0 dp height/width (Rule 16 constraint)
  static const double keypadButtonSize = 72.0;

  /// Standard big CTA buttons: 72.0 dp height
  static const double primaryButtonHeight = 72.0;

  /// List item tiles comfortable height: 72.0 dp
  static const double listTileHeight = 72.0;

  // -------------------------------------------------------------
  // Border Radius Tokens
  // -------------------------------------------------------------

  /// Sandstone cards border radius: 24.0 dp
  static const double cardRadius = 24.0;

  /// Big action buttons border radius: 20.0 dp
  static const double buttonRadius = 20.0;

  /// Input fields background border radius: 16.0 dp
  static const double inputRadius = 16.0;

  /// Circular avatars border radius: 50.0 dp
  static const double circularRadius = 50.0;

  // -------------------------------------------------------------
  // Edge Padding Helpers (Insets)
  // -------------------------------------------------------------

  /// Standard vertical spacing for views
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(
    horizontal: xl,
    vertical: xl,
  );

  /// Inner padding inside functional list tiles
  static const EdgeInsets listTilePadding = EdgeInsets.symmetric(
    horizontal: lg,
    vertical: md,
  );

  /// Inner padding inside core container cards
  static const EdgeInsets cardPadding = EdgeInsets.all(lg);
}
