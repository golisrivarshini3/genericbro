import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF015c68);
  static const Color primaryLightColor = Color(0xFF0a7c8a);
  static const Color accentColor = Color(0xFF1a6b75);
  static const Color buttonColor = Color(0xFFE1F5F8); // Light aqua color for buttons
  static const Color buttonIconColor = Color(0xFF015c68); // Primary color for icons
  
  static const double defaultPadding = 16.0;
  static const double defaultRadius = 12.0;
  
  static ThemeData get lightTheme {
    return ThemeData(
      primaryColor: primaryColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.light,
      ),
      textTheme: GoogleFonts.poppinsTextTheme(),
      useMaterial3: true,
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          padding: const EdgeInsets.symmetric(
            horizontal: defaultPadding * 1.5,
            vertical: defaultPadding,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(defaultRadius),
          ),
          backgroundColor: buttonColor.withOpacity(0.95),
          foregroundColor: primaryColor,
        ),
      ),
    );
  }

  static BoxDecoration get gradientBackground {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          primaryColor,
          primaryLightColor,
          accentColor,
        ],
        stops: [0.0, 0.6, 1.0],
      ),
    );
  }

  static BoxDecoration get buttonDecoration {
    return BoxDecoration(
      color: buttonColor.withOpacity(0.95),
      borderRadius: BorderRadius.circular(defaultRadius),
      border: Border.all(
        color: Colors.white.withOpacity(0.5),
        width: 1,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.white.withOpacity(0.1),
          blurRadius: 10,
          spreadRadius: -5,
          offset: const Offset(0, -4),
        ),
      ],
    );
  }
} 