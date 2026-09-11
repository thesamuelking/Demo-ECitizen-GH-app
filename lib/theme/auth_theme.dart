import 'package:flutter/material.dart';

/// Color tokens for the auth screens.
/// Drawn from the deep indigo/purple palette in the reference image.
class AuthColors {
  /// Page background — deep indigo matching the reference
  static const background = Color(0xFF2D2B6E);

  /// Card / input surface — slightly lighter indigo
  static const card = Color(0xFF3D3B82);

  /// Card border — subtle purple outline
  static const cardBorder = Color(0xFF4E4BA0);

  /// Primary accent — cyan/teal highlight (matches reference's action buttons)
  static const accent = Color(0xFF4FC3F7);

  /// Soft accent background for icon containers
  static const accentSoft = Color(0xFF3D3B82);

  /// Muted text for labels, placeholders, secondary copy
  static const textMuted = Color(0xFFADA8D6);

  /// Gradient start (deep indigo)
  static const gradientStart = Color(0xFF1E1C5A);

  /// Gradient end (medium indigo)
  static const gradientEnd = Color(0xFF3D3B82);
}

const authFontFallbacks = [
  'Noto Sans',
  'Noto Sans Symbols 2',
  'Noto Color Emoji',
  'Segoe UI Emoji',
  'Arial',
];
