import 'package:flutter/material.dart';
import '../core/app_colors.dart';

class AppTheme {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF7F8F5),
    useMaterial3: true,

    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF0F4F3A),
      brightness: Brightness.light,
    ).copyWith(
      primary: const Color(0xFF0F4F3A),
      secondary: AppColors.gold,
      surface: Colors.white,
    ),

    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF7F8F5),
      foregroundColor: Color(0xFF17211D),
      centerTitle: false,
      elevation: 0,
    ),

    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(
          color: Color(0xFFE1E5DF),
        ),
      ),
    ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,

      labelStyle: const TextStyle(
        color: Color(0xFF6D756F),
      ),

      hintStyle: const TextStyle(
        color: Color(0xFF8A928C),
      ),

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFFE1E5DF),
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFFE1E5DF),
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(
          color: Color(0xFF0F4F3A),
          width: 1.4,
        ),
      ),
    ),

    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: Colors.white,
      indicatorColor: const Color(0xFFEAF4EF),

      labelTextStyle: WidgetStateProperty.all(
        const TextStyle(
          color: Color(0xFF17211D),
          fontWeight: FontWeight.w600,
        ),
      ),

      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(
            color: Color(0xFF0F4F3A),
          );
        }

        return const IconThemeData(
          color: Color(0xFF6D756F),
        );
      }),
    ),
  );
}