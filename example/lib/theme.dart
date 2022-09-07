import 'package:flutter/material.dart';

@immutable
class AppTheme {
  const AppTheme._();

  static final ThemeData light = ThemeData.light().copyWith(
    brightness: Brightness.light,
  );

  static final ThemeData dark = ThemeData.dark().copyWith(
    brightness: Brightness.dark,
  );

  static ThemeData fromBrightness(Brightness brightness) {
    return brightness == Brightness.light ? light : dark;
  }
}
