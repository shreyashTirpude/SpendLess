import 'package:flutter/widgets.dart';

/// One spacing scale for the whole app (4 / 8 / 16 / 24 / 32). Using these
/// instead of ad-hoc numbers is the difference between "designed" and
/// "assembled". Reach for the nearest token, don't invent new gaps.
class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

/// One corner-radius scale. Cards use [lg]; pills/chips use [pill].
class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 20;
  static const double pill = 999;
}

/// Money should always use tabular (monospaced) figures so amounts line up in
/// columns and don't jitter as they animate. Apply this to every ₹ amount.
class AppType {
  static const List<FontFeature> tabular = [FontFeature.tabularFigures()];

  /// Convenience: copy a style to use tabular figures.
  static TextStyle money(TextStyle base) =>
      base.copyWith(fontFeatures: tabular);
}
