import 'package:flutter/material.dart';

class AppColors {
  static const dark = Color(0xFF121212);
  static const light = Color(0xFFFFFFFF);
}

class AppThemes {
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: AppColors.light,
    appBarTheme: const AppBarTheme(
      surfaceTintColor: AppColors.light,
    ),
  );

  static final darkTheme = ThemeData(
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.dark,
      appBarTheme: const AppBarTheme(
        surfaceTintColor: AppColors.dark,
      ));
}

class StylesForText {
  TextStyle appBarStyle(bool isDarkMode) {
    return TextStyle(
      fontSize: 20,
      fontWeight: FontWeight.bold,
      color: isDarkMode ? Colors.white : Colors.grey.shade900,
    );
  }
   TextStyle bodyTextStyle(bool isDarkMode) => TextStyle(
        fontSize: 16,
        color: isDarkMode ? Colors.white : Colors.black,
      );
}
