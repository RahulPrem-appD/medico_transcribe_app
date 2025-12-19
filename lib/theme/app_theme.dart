import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color palette - Professional Sky Blue aesthetic
  static const Color primarySkyBlue = Color(0xFF4A90D9);
  static const Color deepSkyBlue = Color(0xFF2E78C2);
  static const Color lightSkyBlue = Color(0xFF87CEEB);
  static const Color accentBlue = Color(0xFF1E5AA8);
  static const Color softSkyBg = Color(0xFFF0F8FF);
  static const Color paleBlue = Color(0xFFE6F3FF);
  static const Color darkSlate = Color(0xFF1A2B3C);
  static const Color mediumGray = Color(0xFF6B7280);
  static const Color lightGray = Color(0xFFF3F4F6);
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color accentCoral = Color(0xFFE8505B);

  // Legacy color mappings for backward compatibility
  static const Color primaryTeal = primarySkyBlue;
  static const Color deepTeal = deepSkyBlue;
  static const Color warmCream = softSkyBg;
  static const Color softMint = paleBlue;

  static ThemeData get theme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: softSkyBg,
      colorScheme: ColorScheme.light(
        primary: primarySkyBlue,
        secondary: deepSkyBlue,
        tertiary: accentBlue,
        surface: Colors.white,
        surfaceContainerHighest: softSkyBg,
        error: accentCoral,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkSlate,
      ),
      textTheme: GoogleFonts.poppinsTextTheme().copyWith(
        displayLarge: GoogleFonts.raleway(
          fontSize: 48,
          fontWeight: FontWeight.w700,
          color: darkSlate,
          letterSpacing: -1,
        ),
        displayMedium: GoogleFonts.raleway(
          fontSize: 36,
          fontWeight: FontWeight.w600,
          color: darkSlate,
        ),
        displaySmall: GoogleFonts.raleway(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: darkSlate,
        ),
        headlineLarge: GoogleFonts.poppins(
          fontSize: 24,
          fontWeight: FontWeight.w700,
          color: darkSlate,
        ),
        headlineMedium: GoogleFonts.poppins(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkSlate,
        ),
        headlineSmall: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkSlate,
        ),
        bodyLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          color: darkSlate,
          height: 1.6,
        ),
        bodyMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: mediumGray,
          height: 1.5,
        ),
        labelLarge: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        labelMedium: GoogleFonts.poppins(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: mediumGray,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primarySkyBlue,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primarySkyBlue,
          side: const BorderSide(color: primarySkyBlue, width: 2),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.poppins(
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
        titleTextStyle: GoogleFonts.poppins(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: darkSlate,
        ),
        iconTheme: const IconThemeData(color: darkSlate),
      ),
    );
  }
}
