import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // CIIT Primary brand color: Prussian Blue
  static const Color primaryColor = Color(0xFF00364D);

  // CIIT Accent color: Persian Rose (used for selections and highlights)
  static const Color accentColor = Color(0xFFFF28B1);

  // MaterialColor swatch generated from Prussian Blue
  static const MaterialColor primarySwatch =
  MaterialColor(0xFF00364D, <int, Color>{
    50: Color(0xFFE0E7EB),
    100: Color(0xFFB3C2CD),
    200: Color(0xFF8099AB),
    300: Color(0xFF4D7088),
    400: Color(0xFF26516E),
    500: Color(0xFF00364D), // Primary
    600: Color(0xFF003046),
    700: Color(0xFF00293D),
    800: Color(0xFF002235),
    900: Color(0xFF001625),
  });

  static ThemeData get lightTheme {
    // Base text theme using Montserrat for a modern, tech-focused body font
    final TextTheme baseTextTheme = GoogleFonts.montserratTextTheme();

    return ThemeData(
      useMaterial3: false,
      primarySwatch: primarySwatch,
      primaryColor: primaryColor,
      scaffoldBackgroundColor: Colors.white,

      textTheme: baseTextTheme.copyWith(
        // Poppins for headers and titles
        displayLarge: GoogleFonts.poppins(
          fontSize: 57,
          fontWeight: FontWeight.normal,
          color: Colors.black87,
        ),
        displayMedium: GoogleFonts.poppins(
          fontSize: 45,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        displaySmall: GoogleFonts.poppins(
          fontSize: 36,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 32,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 28,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        titleLarge: GoogleFonts.poppins(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        titleMedium: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: Colors.black87,
        ),
        titleSmall: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w300,
          color: Colors.black87,
        ),
        // Montserrat for sub headlines and body text (Replacing Merriweather)
        bodyLarge: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.normal,
          color: Colors.black87,
        ),
        bodyMedium: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Colors.black87,
        ),
        bodySmall: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.normal,
          color: Colors.black54,
        ),
        labelLarge: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: Colors.black87,
        ),
        labelMedium: GoogleFonts.montserrat(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: Colors.black87,
        ),
        labelSmall: GoogleFonts.montserrat(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: Colors.black54,
        ),
      ),

      // Button Themes
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: Colors.white,
          backgroundColor: primaryColor,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Input Decoration
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: GoogleFonts.poppins(color: primaryColor),
        hintStyle: GoogleFonts.poppins(color: Colors.grey),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade400),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: primaryColor),
        ),
      ),

      // Selection Colors (Using the vibrant CIIT Persian Rose for contrast)
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accentColor,
        selectionColor: accentColor.withOpacity(0.3),
        selectionHandleColor: accentColor,
      ),
    );
  }
}