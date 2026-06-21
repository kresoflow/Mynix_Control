import 'package:flutter/material.dart';
import 'dark_theme.dart';
import 'light_theme.dart';

abstract class AppTheme {
  static ThemeData get dark => getDarkTheme();
  static ThemeData get light => getLightTheme();
}
