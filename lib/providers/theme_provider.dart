import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Available theme modes
enum AppThemeMode {
  light,
  dark,
  system,
}

/// Available accent colors
enum AccentColor {
  skyBlue,
  emerald,
  violet,
  coral,
  amber,
  rose,
}

/// Theme Provider - Manages app theme state
class ThemeProvider extends ChangeNotifier {
  static const String _themeModeKey = 'theme_mode';
  static const String _accentColorKey = 'accent_color';

  AppThemeMode _themeMode = AppThemeMode.light;
  AccentColor _accentColor = AccentColor.skyBlue;
  bool _isInitialized = false;

  AppThemeMode get themeMode => _themeMode;
  AccentColor get accentColor => _accentColor;
  bool get isInitialized => _isInitialized;

  /// Initialize theme from saved preferences
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load theme mode
      final themeModeIndex = prefs.getInt(_themeModeKey) ?? 0;
      _themeMode = AppThemeMode.values[themeModeIndex.clamp(0, AppThemeMode.values.length - 1)];
      
      // Load accent color
      final accentColorIndex = prefs.getInt(_accentColorKey) ?? 0;
      _accentColor = AccentColor.values[accentColorIndex.clamp(0, AccentColor.values.length - 1)];
      
      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      print('Error loading theme preferences: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(AppThemeMode mode) async {
    if (_themeMode == mode) return;
    
    _themeMode = mode;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_themeModeKey, mode.index);
    } catch (e) {
      print('Error saving theme mode: $e');
    }
  }

  /// Set accent color
  Future<void> setAccentColor(AccentColor color) async {
    if (_accentColor == color) return;
    
    _accentColor = color;
    notifyListeners();
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_accentColorKey, color.index);
    } catch (e) {
      print('Error saving accent color: $e');
    }
  }

  /// Get the actual ThemeMode for MaterialApp
  ThemeMode get materialThemeMode {
    switch (_themeMode) {
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
      case AppThemeMode.system:
        return ThemeMode.system;
    }
  }

  /// Check if dark mode is active
  bool isDarkMode(BuildContext context) {
    if (_themeMode == AppThemeMode.system) {
      return MediaQuery.of(context).platformBrightness == Brightness.dark;
    }
    return _themeMode == AppThemeMode.dark;
  }

  /// Get primary color based on accent
  Color get primaryColor {
    switch (_accentColor) {
      case AccentColor.skyBlue:
        return const Color(0xFF4A90D9);
      case AccentColor.emerald:
        return const Color(0xFF10B981);
      case AccentColor.violet:
        return const Color(0xFF8B5CF6);
      case AccentColor.coral:
        return const Color(0xFFE8505B);
      case AccentColor.amber:
        return const Color(0xFFF59E0B);
      case AccentColor.rose:
        return const Color(0xFFEC4899);
    }
  }

  /// Get secondary/deep color based on accent
  Color get secondaryColor {
    switch (_accentColor) {
      case AccentColor.skyBlue:
        return const Color(0xFF2E78C2);
      case AccentColor.emerald:
        return const Color(0xFF059669);
      case AccentColor.violet:
        return const Color(0xFF7C3AED);
      case AccentColor.coral:
        return const Color(0xFFDC2626);
      case AccentColor.amber:
        return const Color(0xFFD97706);
      case AccentColor.rose:
        return const Color(0xFFDB2777);
    }
  }

  /// Get accent color name for display
  String get accentColorName {
    switch (_accentColor) {
      case AccentColor.skyBlue:
        return 'Sky Blue';
      case AccentColor.emerald:
        return 'Emerald';
      case AccentColor.violet:
        return 'Violet';
      case AccentColor.coral:
        return 'Coral';
      case AccentColor.amber:
        return 'Amber';
      case AccentColor.rose:
        return 'Rose';
    }
  }

  /// Get theme mode name for display
  String get themeModeName {
    switch (_themeMode) {
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
      case AppThemeMode.system:
        return 'System';
    }
  }
}


