/// Shared design tokens for the Timeline Dashboard redesign.
///
/// Import this file wherever you need the primary colour, card radius, or
/// a Mulish-based TextStyle helper.  The tokens are intentionally kept as
/// plain `const` values so they can be used in `const` widget constructors.
library app_theme;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Colour palette
// ---------------------------------------------------------------------------

/// Twitter / Timeline primary blue.
const Color kPrimaryColor = Color(0xFF1DA1F2);

/// Near-black used for body text and headings.
const Color kSecondaryColor = Color(0xFF14171A);

/// Mid-grey used for secondary text, timestamps, and icons.
const Color kLightGreyColor = Color(0xFFAAB8C2);

/// Light divider / border colour.
const Color kExtraLightColor = Color(0xFFE1E8ED);

/// Page background.
const Color kBackgroundColor = Color(0xFFF5F8FA);

/// Like / heart accent.
const Color kLikeColor = Color(0xFFE0245E);

/// Retweet / green accent.
const Color kRetweetColor = Color(0xFF17BF63);

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
  Color color = kSecondaryColor,
  double? height,
}) {
  return GoogleFonts.mulish(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}
