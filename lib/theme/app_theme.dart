import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/theme_provider.dart';

class AppTheme {
  // ==================== COLOR PALETTE ====================
  
  // Primary Baby Blue - Vibrant and Fresh
  static const Color primarySkyBlue = Color(0xFF5DB5FF);  // Bright baby blue
  static const Color deepSkyBlue = Color(0xFF3DA0FF);     // Deep baby blue
  static const Color lightSkyBlue = Color(0xFF9FD6FF);    // Light baby blue
  static const Color accentBlue = Color(0xFF2280E8);      // Accent blue
  static const Color softSkyBg = Color(0xFFF5FBFF);       // Very light blue background
  static const Color paleBlue = Color(0xFFE8F5FF);        // Pale baby blue
  
  // Neutral Colors
  static const Color darkSlate = Color(0xFF1A2B3C);
  static const Color mediumGray = Color(0xFF6B7280);
  static const Color lightGray = Color(0xFFF3F4F6);
  
  // Semantic Colors
  static const Color successGreen = Color(0xFF10B981);
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color accentCoral = Color(0xFFE8505B);

  // Dark Theme Colors
  static const Color darkBackground = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF334155);
  static const Color darkText = Color(0xFFF1F5F9);
  static const Color darkTextSecondary = Color(0xFF94A3B8);

  // Legacy color mappings for backward compatibility
  static const Color primaryTeal = primarySkyBlue;
  static const Color deepTeal = deepSkyBlue;
  static const Color warmCream = softSkyBg;
  static const Color softMint = paleBlue;

  // ==================== THEME DATA ====================

  /// Get light theme with baby blue colors
  static ThemeData lightTheme({Color? primaryColor, Color? secondaryColor}) {
    // Always use baby blue - ignore parameters
    final primary = primarySkyBlue;
    final secondary = deepSkyBlue;
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: softSkyBg,
      colorScheme: ColorScheme.light(
        primary: primary,
        secondary: secondary,
        tertiary: accentBlue,
        surface: Colors.white,
        surfaceContainerHighest: softSkyBg,
        error: accentCoral,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkSlate,
      ),
      textTheme: _buildTextTheme(darkSlate, mediumGray),
      elevatedButtonTheme: _buildElevatedButtonTheme(primary),
      outlinedButtonTheme: _buildOutlinedButtonTheme(primary),
      cardTheme: _buildCardTheme(Colors.white),
      appBarTheme: _buildAppBarTheme(darkSlate),
      inputDecorationTheme: _buildInputDecorationTheme(primary, false),
      dialogTheme: _buildDialogTheme(Colors.white),
      bottomSheetTheme: _buildBottomSheetTheme(Colors.white),
      snackBarTheme: _buildSnackBarTheme(),
      dividerTheme: const DividerThemeData(color: lightGray),
      switchTheme: _buildSwitchTheme(primary),
      checkboxTheme: _buildCheckboxTheme(primary),
      radioTheme: _buildRadioTheme(primary),
      floatingActionButtonTheme: _buildFabTheme(primary),
    );
  }

  /// Get dark theme with specified accent color
  static ThemeData darkTheme({Color? primaryColor, Color? secondaryColor}) {
    final primary = primaryColor ?? primarySkyBlue;
    final secondary = secondaryColor ?? deepSkyBlue;
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: darkBackground,
      colorScheme: ColorScheme.dark(
        primary: primary,
        secondary: secondary,
        tertiary: primary.withOpacity(0.7),
        surface: darkSurface,
        surfaceContainerHighest: darkCard,
        error: accentCoral,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: darkText,
      ),
      textTheme: _buildTextTheme(darkText, darkTextSecondary),
      elevatedButtonTheme: _buildElevatedButtonTheme(primary),
      outlinedButtonTheme: _buildOutlinedButtonTheme(primary),
      cardTheme: _buildCardTheme(darkSurface),
      appBarTheme: _buildAppBarTheme(darkText, isDark: true),
      inputDecorationTheme: _buildInputDecorationTheme(primary, true),
      dialogTheme: _buildDialogTheme(darkSurface),
      bottomSheetTheme: _buildBottomSheetTheme(darkSurface),
      snackBarTheme: _buildSnackBarTheme(isDark: true),
      dividerTheme: DividerThemeData(color: darkCard),
      switchTheme: _buildSwitchTheme(primary),
      checkboxTheme: _buildCheckboxTheme(primary),
      radioTheme: _buildRadioTheme(primary),
      floatingActionButtonTheme: _buildFabTheme(primary),
    );
  }

  /// Get theme based on ThemeProvider settings
  static ThemeData getTheme(ThemeProvider provider, {required bool isDark}) {
    if (isDark) {
      return darkTheme(
        primaryColor: provider.primaryColor,
        secondaryColor: provider.secondaryColor,
      );
    } else {
      return lightTheme(
        primaryColor: provider.primaryColor,
        secondaryColor: provider.secondaryColor,
      );
    }
  }

  /// Legacy theme getter for backward compatibility
  static ThemeData get theme => lightTheme();

  // ==================== THEME COMPONENTS ====================

  static TextTheme _buildTextTheme(Color primaryText, Color secondaryText) {
    return GoogleFonts.poppinsTextTheme().copyWith(
      displayLarge: GoogleFonts.raleway(
        fontSize: 48,
        fontWeight: FontWeight.w700,
        color: primaryText,
        letterSpacing: -1,
      ),
      displayMedium: GoogleFonts.raleway(
        fontSize: 36,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      displaySmall: GoogleFonts.raleway(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      headlineLarge: GoogleFonts.poppins(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: primaryText,
      ),
      headlineMedium: GoogleFonts.poppins(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      headlineSmall: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      bodyLarge: GoogleFonts.poppins(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primaryText,
        height: 1.6,
      ),
      bodyMedium: GoogleFonts.poppins(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondaryText,
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
        color: secondaryText,
      ),
    );
  }

  static ElevatedButtonThemeData _buildElevatedButtonTheme(Color primary) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primary,
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
    );
  }

  static OutlinedButtonThemeData _buildOutlinedButtonTheme(Color primary) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primary,
        side: BorderSide(color: primary, width: 2),
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        textStyle: GoogleFonts.poppins(
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  static CardThemeData _buildCardTheme(Color color) {
    return CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      color: color,
    );
  }

  static AppBarTheme _buildAppBarTheme(Color textColor, {bool isDark = false}) {
    return AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.poppins(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      iconTheme: IconThemeData(color: textColor),
    );
  }

  static InputDecorationTheme _buildInputDecorationTheme(Color primary, bool isDark) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? darkCard : lightGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: primary, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  static DialogThemeData _buildDialogTheme(Color backgroundColor) {
    return DialogThemeData(
      backgroundColor: backgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
    );
  }

  static BottomSheetThemeData _buildBottomSheetTheme(Color backgroundColor) {
    return BottomSheetThemeData(
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    );
  }

  static SnackBarThemeData _buildSnackBarTheme({bool isDark = false}) {
    return SnackBarThemeData(
      backgroundColor: isDark ? darkCard : darkSlate,
      contentTextStyle: GoogleFonts.poppins(
        color: Colors.white,
        fontSize: 14,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  static SwitchThemeData _buildSwitchTheme(Color primary) {
    return SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary;
        }
        return mediumGray;
      }),
      trackColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary.withOpacity(0.3);
        }
        return lightGray;
      }),
    );
  }

  static CheckboxThemeData _buildCheckboxTheme(Color primary) {
    return CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary;
        }
        return Colors.transparent;
      }),
      checkColor: WidgetStateProperty.all(Colors.white),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  static RadioThemeData _buildRadioTheme(Color primary) {
    return RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return primary;
        }
        return mediumGray;
      }),
    );
  }

  static FloatingActionButtonThemeData _buildFabTheme(Color primary) {
    return FloatingActionButtonThemeData(
      backgroundColor: primary,
      foregroundColor: Colors.white,
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  // ==================== HELPER METHODS ====================

  /// Get background color based on theme
  static Color getBackgroundColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkBackground : softSkyBg;
  }

  /// Get surface color based on theme
  static Color getSurfaceColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkSurface : Colors.white;
  }

  /// Get card color based on theme
  static Color getCardColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkSurface : Colors.white;
  }

  /// Get text color based on theme
  static Color getTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkText : darkSlate;
  }

  /// Get secondary text color based on theme
  static Color getSecondaryTextColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? darkTextSecondary : mediumGray;
  }

  /// Get gradient for backgrounds
  static LinearGradient getBackgroundGradient(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (isDark) {
      return LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          darkBackground,
          darkSurface,
          darkBackground,
        ],
      );
    }
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        const Color(0xFFF8FBFF),
        const Color(0xFFEDF5FF),
        const Color(0xFFF0F4F8),
      ],
    );
  }
}
