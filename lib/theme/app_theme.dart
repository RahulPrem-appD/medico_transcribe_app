import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color palette - Medical/Professional aesthetic with warmth
  static const Color primaryTeal = Color(0xFF0D7377);
  static const Color deepTeal = Color(0xFF14919B);
  static const Color accentCoral = Color(0xFFE8505B);
  static const Color warmCream = Color(0xFFFFF8F0);
  static const Color softMint = Color(0xFFE4F9F5);
  static const Color darkSlate = Color(0xFF212121);
  static const Color mediumGray = Color(0xFF6B7280);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: warmCream,
      colorScheme: ColorScheme.light(
        primary: primaryTeal,
        secondary: deepTeal,
        tertiary: accentCoral,
        surface: Colors.white,
        surfaceContainerHighest: warmCream,
        error: accentCoral,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkSlate,
      ),
      textTheme: GoogleFonts.dmSansTextTheme().copyWith(
        displayLarge: GoogleFonts.playfairDisplay(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: darkSlate,
          letterSpacing: -1,
        ),
        displayMedium: GoogleFonts.playfairDisplay(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          color: darkSlate,
        ),
        displaySmall: GoogleFonts.playfairDisplay(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: darkSlate,
        ),
        headlineLarge: GoogleFonts.dmSans(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: darkSlate,
        ),
        headlineMedium: GoogleFonts.dmSans(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkSlate,
        ),
        headlineSmall: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkSlate,
        ),
        bodyLarge: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: darkSlate,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: mediumGray,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.dmSans(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        labelMedium: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: mediumGray,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryTeal,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryTeal,
          side: const BorderSide(color: primaryTeal, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        color: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.dmSans(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkSlate,
        ),
        iconTheme: const IconThemeData(color: darkSlate),
      ),
    );
  }
}

