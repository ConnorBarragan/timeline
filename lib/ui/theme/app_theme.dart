/// Shared design tokens for the Timeline – Cinder Rust redesign.
///
/// Import this file wherever you need palette colours, card radius, or
/// a Mulish-based TextStyle helper.  The tokens are intentionally kept as
/// plain `const` values so they can be used in `const` widget constructors.
library app_theme;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Cinder Rust colour palette
// ---------------------------------------------------------------------------

/// Burnt-rust primary – active indicators, FAB, accent icons.
const Color kPrimaryColor = Color(0xFFC0522B);

/// Deep charcoal-brown – AppBar / BottomNav backgrounds.
const Color kSecondaryColor = Color(0xFF1C1410);

/// Taupe – secondary text, timestamps, dividers, borders.
const Color kLightGreyColor = Color(0xFF8C7B72);

/// Dark card surface – tweet cards, activity cards.
const Color kExtraLightColor = Color(0xFF3A2E28);

/// Darkest cinder – page / IndexedStack background, compose body.
const Color kBackgroundColor = Color(0xFF2A1F1A);

/// Like / heart accent (kept distinct from primary for semantic clarity).
const Color kLikeColor = Color(0xFFC0522B);

/// Retweet accent (taupe-green neutral in dark theme).
const Color kRetweetColor = Color(0xFF8C7B72);

/// Warm off-white – primary text, icon fills on dark surfaces.
const Color kOffWhiteColor = Color(0xFFF2EDE8);

// ---------------------------------------------------------------------------
// Geometry
// ---------------------------------------------------------------------------

/// Card and container border-radius (12 px).
const double kCardRadius = 12.0;

// ---------------------------------------------------------------------------
// Typography helpers
// ---------------------------------------------------------------------------

/// Returns a Mulish [TextStyle] with the given parameters.
///
/// Example:
/// ```dart
/// Text('Hello', style: mulish(fontSize: 16, fontWeight: FontWeight.w800))
/// ```
TextStyle mulish({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w500,
  Color color = kOffWhiteColor,
  double? height,
}) {
  return GoogleFonts.mulish(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}
