import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AppTheme {
  static const Color accentColor = Color(0xFF007AFF); // iOS Blue

  static final ThemeData iosLightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: accentColor,
      brightness: Brightness.light,
    ),
    scaffoldBackgroundColor: const Color(0xFFF2F2F7), // iOS System Background
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(
        color: Colors.black,
        fontSize: 17,
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static const CupertinoThemeData cupertinoTheme = CupertinoThemeData(
    primaryColor: accentColor,
    brightness: Brightness.light,
    scaffoldBackgroundColor: Color(0xFFF2F2F7),
  );
}
