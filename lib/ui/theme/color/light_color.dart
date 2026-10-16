part of '../theme.dart';

class TwitterColor {
  static Color bondiBlue = const Color.fromRGBO(0, 132, 180, 1.0);
  static Color cerulean = const Color.fromRGBO(0, 172, 237, 1.0);
  static Color spindle = const Color.fromRGBO(192, 222, 237, 1.0);
  static Color white = const Color.fromRGBO(255, 255, 255, 1.0);
  static Color black = const Color.fromRGBO(0, 0, 0, 1.0);
  static Color woodsmoke = const Color.fromRGBO(20, 23, 2, 1.0);
  static Color woodsmoke_50 = const Color.fromRGBO(20, 23, 2, 0.5);
  static Color mystic = const Color.fromRGBO(230, 236, 240, 1.0);
  static Color dodgeBlue = const Color.fromRGBO(29, 162, 240, 1.0);
  static Color dodgeBlue_50 = const Color.fromRGBO(29, 162, 240, 0.5);
  static Color paleSky = const Color.fromRGBO(101, 119, 133, 1.0);
  static Color ceriseRed = const Color.fromRGBO(224, 36, 94, 1.0);
  static Color paleSky50 = const Color.fromRGBO(101, 118, 133, 0.5);
}

/// Cinder Rust palette – used across all redesigned screens.
class AppColor {
  /// Burnt-rust primary: active indicators, FAB, accent icons.
  static const Color primary = Color(0xFFC0522B);

  /// Deep charcoal-brown: AppBar / BottomNav backgrounds.
  static const Color secondary = Color(0xFF1C1410);

  /// Darkest cinder: page / IndexedStack background, compose body.
  static const Color darkGrey = Color(0xFF2A1F1A);

  /// Taupe: secondary text, timestamps, dividers, borders.
  static const Color lightGrey = Color(0xFF8C7B72);

  /// Dark card surface: tweet cards, activity cards.
  static const Color extraLightGrey = Color(0xFF3A2E28);

  /// Warm off-white: primary text, icon fills on dark surfaces.
  static const Color extraExtraLightGrey = Color(0xFFF2EDE8);

  /// Alias kept for backward-compat with widgets that reference AppColor.white.
  static const Color white = Color(0xFFF2EDE8);
}
