import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
part 'app_icons.dart';
part 'color/light_color.dart';
part 'text_styles.dart';
part 'extention.dart';

/// Design tokens for the Timeline Command Center redesign.
/// Primary colour: #1DA1F2  |  Border radius: 12 px  |  Font: Mulish
const Color kPrimaryColor = Color(0xFF1DA1F2);
const double kBorderRadius = 12.0;

class AppTheme {
  static final ThemeData appTheme = ThemeData.light().copyWith(
    scaffoldBackgroundColor: TwitterColor.white,
    brightness: Brightness.light,
    primaryColor: kPrimaryColor,
    cardColor: Colors.white,
    unselectedWidgetColor: Colors.grey,
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: AppColor.white,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: TwitterColor.white,
      iconTheme: const IconThemeData(
        color: kPrimaryColor,
      ),
      elevation: 0,
    ),
    bottomAppBarTheme: ThemeData.light().bottomAppBarTheme.copyWith(
          color: Colors.white,
          elevation: 0,
        ),
    tabBarTheme: TabBarTheme(
      labelStyle:
          TextStyles.titleStyle.copyWith(color: kPrimaryColor),
      unselectedLabelColor: AppColor.darkGrey,
      unselectedLabelStyle:
          TextStyles.titleStyle.copyWith(color: AppColor.darkGrey),
      labelColor: kPrimaryColor,
      labelPadding: const EdgeInsets.symmetric(vertical: 12),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kPrimaryColor,
      foregroundColor: Colors.white,
      shape: CircleBorder(),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
    ),
    cardTheme: CardTheme(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(kBorderRadius),
      ),
      elevation: 0,
    ),
    colorScheme: const ColorScheme(
      background: Colors.white,
      onPrimary: Colors.white,
      onBackground: Colors.black,
      onError: Colors.white,
      onSecondary: Colors.white,
      onSurface: Colors.black,
      error: Colors.red,
      primary: kPrimaryColor,
      primaryContainer: kPrimaryColor,
      secondary: AppColor.secondary,
      secondaryContainer: AppColor.darkGrey,
      surface: Colors.white,
      brightness: Brightness.light,
    ),
    textTheme: GoogleFonts.mulishTextTheme(),
  );

  static List<BoxShadow> shadow = <BoxShadow>[
    BoxShadow(
        blurRadius: 10,
        offset: const Offset(5, 5),
        color: AppTheme.appTheme.colorScheme.secondary,
        spreadRadius: 1)
  ];
  static BoxDecoration softDecoration =
      const BoxDecoration(boxShadow: <BoxShadow>[
    BoxShadow(
        blurRadius: 8,
        offset: Offset(5, 5),
        color: Color(0xffe2e5ed),
        spreadRadius: 5),
    BoxShadow(
        blurRadius: 8,
        offset: Offset(-5, -5),
        color: Color(0xffffffff),
        spreadRadius: 5)
  ], color: Color(0xfff1f3f6));
}

String get description {
  return '';
}
