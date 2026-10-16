/// Shared design tokens for the Analytics screens.
///
/// Graphite/grey palette with #F5C518 yellow accent.
/// Import this file in all analytics pages.
library analytics_theme;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ---------------------------------------------------------------------------
// Analytics colour palette
// ---------------------------------------------------------------------------

/// Page scaffold background – darkest graphite.
const Color kAnalyticsBackground = Color(0xFF1E1E1E);

/// Card / surface background.
const Color kAnalyticsSurface = Color(0xFF2C2C2C);

/// Border / divider colour.
const Color kAnalyticsBorder = Color(0xFF3A3A3A);

/// Primary / body text – mid grey.
const Color kAnalyticsPrimary = Color(0xFF6B6B6B);

/// Yellow accent – charts, highlights, selected indicators.
const Color kAnalyticsAccent = Color(0xFFF5C518);

/// Light text on dark surfaces (headings, values).
const Color kAnalyticsOnSurface = Color(0xFFE0E0E0);

// ---------------------------------------------------------------------------
// Geometry
// ---------------------------------------------------------------------------

/// Card border-radius (12 px).
const double kAnalyticsRadius = 12.0;

// ---------------------------------------------------------------------------
// Typography helpers
// ---------------------------------------------------------------------------

/// Returns a Mulish [TextStyle] for analytics screens.
TextStyle analyticsMulish({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w500,
  Color color = kAnalyticsOnSurface,
  double? height,
}) {
  return GoogleFonts.mulish(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );
}

// ---------------------------------------------------------------------------
// Reusable card decoration
// ---------------------------------------------------------------------------

BoxDecoration analyticsCardDecoration({
  double radius = kAnalyticsRadius,
}) {
  return BoxDecoration(
    color: kAnalyticsSurface,
    borderRadius: BorderRadius.circular(radius),
    border: Border.all(color: kAnalyticsBorder),
  );
}
