import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
part 'app_icons.dart';
part 'color/light_color.dart';
part 'text_styles.dart';
part 'extention.dart';

// ---------------------------------------------------------------------------
// Cinder Rust design tokens (also exported via app_theme.dart)
// ---------------------------------------------------------------------------

/// Burnt-rust primary – active indicators, FAB, accent icons.
const Color kPrimaryColor = Color(0xFFC0522B);

/// Card border-radius.
const double kBorderRadius = 12.0;

class AppTheme {
  static final ThemeData appTheme = ThemeData.dark().copyWith(
    scaffoldBackgroundColor: const Color(0xFF2A1F1A),
    brightness: Brightness.dark,
    primaryColor: kPrimaryColor,
    cardColor: const Color(0xFF3A2E28),
    unselectedWidgetColor: const Color(0xFF8C7B72),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF2A1F1A),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: const Color(0xFF1C1410),
      iconTheme: const IconThemeData(color: Color(0xFFF2EDE8)),
      elevation: 0,
      titleTextStyle: GoogleFonts.mulish(
        color: const Color(0xFFF2EDE8),
        fontSize: 18,
        fontWeight: FontWeight.w800,
      ),
    ),
    bottomAppBarTheme: ThemeData.dark().bottomAppBarTheme.copyWith(
          color: const Color(0xFF1C1410),
          elevation: 0,
        ),
    tabBarTheme: TabBarTheme(
      labelStyle: GoogleFonts.mulish(
        color: kPrimaryColor,
        fontWeight: FontWeight.w700,
      ),
      unselectedLabelColor: const Color(0xFF8C7B72),
      unselectedLabelStyle: GoogleFonts.mulish(
        color: const Color(0xFF8C7B72),
        fontWeight: FontWeight.w600,
      ),
      labelColor: kPrimaryColor,
      labelPadding: const EdgeInsets.symmetric(vertical: 12),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kPrimaryColor,
      foregroundColor: Color(0xFFF2EDE8),
      shape: CircleBorder(),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      backgroundColor: kPrimaryColor,
      labelStyle: GoogleFonts.mulish(
        color: const Color(0xFFF2EDE8),
        fontWeight: FontWeight.w700,
      ),
    ),
    cardTheme: CardTheme(
      color: const Color(0xFF3A2E28),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      elevation: 0,
    ),
    dividerColor: const Color(0xFF8C7B72),
    colorScheme: const ColorScheme(
      background: Color(0xFF2A1F1A),
      onPrimary: Color(0xFFF2EDE8),
      onBackground: Color(0xFFF2EDE8),
      onError: Color(0xFFF2EDE8),
      onSecondary: Color(0xFFF2EDE8),
      onSurface: Color(0xFFF2EDE8),
      error: Colors.red,
      primary: kPrimaryColor,
      primaryContainer: kPrimaryColor,
      secondary: Color(0xFF1C1410),
      secondaryContainer: Color(0xFF3A2E28),
      surface: Color(0xFF3A2E28),
      brightness: Brightness.dark,
    ),
    textTheme: GoogleFonts.mulishTextTheme(ThemeData.dark().textTheme),
  );

  static List<BoxShadow> shadow = <BoxShadow>[
    const BoxShadow(
      blurRadius: 10,
      offset: Offset(5, 5),
      color: Color(0xFF1C1410),
      spreadRadius: 1,
    )
  ];

  static BoxDecoration softDecoration = const BoxDecoration(
    boxShadow: <BoxShadow>[
      BoxShadow(
        blurRadius: 8,
        offset: Offset(5, 5),
        color: Color(0xFF1C1410),
        spreadRadius: 5,
      ),
      BoxShadow(
        blurRadius: 8,
        offset: Offset(-5, -5),
        color: Color(0xFF3A2E28),
        spreadRadius: 5,
      ),
    ],
    color: Color(0xFF2A1F1A),
  );
}

String get description {
  return '';
}
