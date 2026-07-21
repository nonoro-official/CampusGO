import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // CIIT Primary brand color: Prussian Blue
  static const Color primaryColor = Color(0xFF00364D);

  // CIIT Accent color: Persian Rose (used for selections and highlights)
  static const Color accentColor = Color(0xFFFF28B1);

  static const Color lightSurfaceColor = Colors.white;

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
      scaffoldBackgroundColor: lightSurfaceColor,

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

  // A lighter shade from the existing Prussian Blue swatch remains visible on
  // neutral dark surfaces while keeping the CampusGO brand family intact.
  static const Color darkPrimaryColor = Color(0xFF8099AB);
  static const Color darkSurfaceColor = Color(0xFF121212);

  static ColorScheme get darkColorScheme => ColorScheme.fromSeed(
        seedColor: primaryColor,
        brightness: Brightness.dark,
      ).copyWith(
        primary: darkPrimaryColor,
        onPrimary: const Color(0xFF081217),
        primaryContainer: primaryColor,
        onPrimaryContainer: const Color(0xFFE0E7EB),
        secondary: accentColor,
        onSecondary: Colors.black,
        secondaryContainer: const Color(0xFF5A1240),
        onSecondaryContainer: const Color(0xFFFFD8EF),
        surface: darkSurfaceColor,
        onSurface: const Color(0xFFF2F2F2),
        surfaceContainerLowest: const Color(0xFF0D0D0D),
        surfaceContainerLow: const Color(0xFF181818),
        surfaceContainer: const Color(0xFF1E1E1E),
        surfaceContainerHigh: const Color(0xFF252525),
        surfaceContainerHighest: const Color(0xFF2C2C2C),
        onSurfaceVariant: const Color(0xFFBDBDBD),
        outline: const Color(0xFF757575),
        outlineVariant: const Color(0xFF3A3A3A),
        inverseSurface: const Color(0xFFF2F2F2),
        onInverseSurface: const Color(0xFF202020),
        inversePrimary: primaryColor,
        surfaceTint: Colors.transparent,
        shadow: Colors.black,
        scrim: Colors.black,
      );

  static ThemeData get darkTheme {
    final colors = darkColorScheme;
    final textTheme = _darkTextTheme(colors);

    return ThemeData(
      useMaterial3: false,
      brightness: Brightness.dark,
      colorScheme: colors,
      primarySwatch: primarySwatch,
      primaryColor: colors.primary,
      scaffoldBackgroundColor: colors.surface,
      canvasColor: colors.surface,
      cardColor: colors.surfaceContainerLow,
      dividerColor: colors.outlineVariant,
      disabledColor: const Color(0xFF606060),
      shadowColor: colors.shadow,
      textTheme: textTheme,
      iconTheme: IconThemeData(color: colors.onSurfaceVariant),
      appBarTheme: AppBarTheme(
        backgroundColor: colors.surface,
        foregroundColor: colors.onSurface,
        elevation: 0,
        systemOverlayStyle: systemOverlayStyle(Brightness.dark),
      ),
      cardTheme: CardThemeData(
        color: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colors.primary,
        textColor: colors.onSurface,
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colors.surface,
        modalBackgroundColor: colors.surface,
        surfaceTintColor: Colors.transparent,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: colors.surfaceContainerLow,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: textTheme.titleLarge,
        contentTextStyle: textTheme.bodyMedium,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: colors.surfaceContainerHigh,
        textStyle: textTheme.bodyMedium,
        surfaceTintColor: Colors.transparent,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colors.inverseSurface,
        contentTextStyle: textTheme.bodyMedium?.copyWith(
          color: colors.onInverseSurface,
        ),
        actionTextColor: colors.inversePrimary,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          foregroundColor: colors.onPrimary,
          backgroundColor: colors.primary,
          disabledForegroundColor: colors.onSurfaceVariant,
          disabledBackgroundColor: colors.surfaceContainerHighest,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: colors.primary,
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.primary,
          side: BorderSide(color: colors.primary),
          textStyle: GoogleFonts.poppins(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: GoogleFonts.poppins(color: colors.primary),
        hintStyle: GoogleFonts.poppins(color: colors.onSurfaceVariant),
        filled: false,
        fillColor: colors.surfaceContainerHigh,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.primary),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.error),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: BorderSide(color: colors.error),
        ),
      ),
      dividerTheme: DividerThemeData(color: colors.outlineVariant),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: colors.primary,
      ),
      textSelectionTheme: TextSelectionThemeData(
        cursorColor: accentColor,
        selectionColor: accentColor.withValues(alpha: 0.35),
        selectionHandleColor: accentColor,
      ),
    );
  }

  static SystemUiOverlayStyle systemOverlayStyle(Brightness brightness) {
    if (brightness == Brightness.dark) {
      return SystemUiOverlayStyle.light.copyWith(
        statusBarColor: Colors.transparent,
        systemNavigationBarColor: darkSurfaceColor,
        systemNavigationBarDividerColor: const Color(0xFF3A3A3A),
        systemNavigationBarIconBrightness: Brightness.light,
      );
    }

    return SystemUiOverlayStyle.dark.copyWith(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarDividerColor: Colors.grey.shade300,
      systemNavigationBarIconBrightness: Brightness.dark,
    );
  }

  static TextTheme _darkTextTheme(ColorScheme colors) {
    final primaryTextColor = colors.onSurface;
    final secondaryTextColor = colors.onSurfaceVariant;
    final baseTextTheme = GoogleFonts.montserratTextTheme(
      ThemeData(brightness: Brightness.dark).textTheme,
    );

    return baseTextTheme.copyWith(
      displayLarge: GoogleFonts.poppins(
        fontSize: 57,
        fontWeight: FontWeight.normal,
        color: primaryTextColor,
      ),
      displayMedium: GoogleFonts.poppins(
        fontSize: 45,
        fontWeight: FontWeight.w500,
        color: primaryTextColor,
      ),
      displaySmall: GoogleFonts.poppins(
        fontSize: 36,
        fontWeight: FontWeight.w500,
        color: primaryTextColor,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 32,
        fontWeight: FontWeight.w500,
        color: primaryTextColor,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 28,
        fontWeight: FontWeight.w500,
        color: primaryTextColor,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w500,
        color: primaryTextColor,
      ),
      titleLarge: GoogleFonts.poppins(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: primaryTextColor,
      ),
      titleMedium: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primaryTextColor,
      ),
      titleSmall: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w300,
        color: primaryTextColor,
      ),
      bodyLarge: GoogleFonts.montserrat(
        fontSize: 16,
        fontWeight: FontWeight.normal,
        color: primaryTextColor,
      ),
      bodyMedium: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.normal,
        color: primaryTextColor,
      ),
      bodySmall: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.normal,
        color: secondaryTextColor,
      ),
      labelLarge: GoogleFonts.montserrat(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryTextColor,
      ),
      labelMedium: GoogleFonts.montserrat(
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: primaryTextColor,
      ),
      labelSmall: GoogleFonts.montserrat(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: secondaryTextColor,
      ),
    );
  }
}
