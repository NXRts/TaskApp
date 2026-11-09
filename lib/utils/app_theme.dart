import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modern Editorial Productivity × Premium Minimalism Design System
/// Inspired by Things 3, Linear, and Notion.
class AppTheme {
  // --- PALETTE TOKENS ---
  
  // Light Canvas (Warm paper / Editorial ivory)
  static const Color lightBg = Color(0xFFFBFBF9);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFEAEAEC);
  static const Color lightBorderSubtle = Color(0xFFF1F1F3);
  static const Color lightTextPrimary = Color(0xFF18181B); // Zinc 900
  static const Color lightTextSecondary = Color(0xFF71717A); // Zinc 500
  static const Color lightTextMuted = Color(0xFFA1A1AA); // Zinc 400

  // Dark Canvas (Warm Obsidian / Linear Charcoal)
  static const Color darkBg = Color(0xFF0E0F12);
  static const Color darkSurface = Color(0xFF16181D);
  static const Color darkSurfaceElevated = Color(0xFF1E2128);
  static const Color darkBorder = Color(0xFF23262F);
  static const Color darkBorderSubtle = Color(0xFF1B1D23);
  static const Color darkTextPrimary = Color(0xFFF4F4F5); // Zinc 100
  static const Color darkTextSecondary = Color(0xFF9CA3AF); // Zinc 400
  static const Color darkTextMuted = Color(0xFF6B7280); // Zinc 500

  // Primary Editorial Accent (Deep Obsidian in light, Crisp Electric Cobalt in dark)
  static const Color lightAccent = Color(0xFF0F172A); // Slate 900
  static const Color darkAccent = Color(0xFF3B82F6); // Blue 500
  static const Color brandCobalt = Color(0xFF2563EB); // Royal Blue

  // Restrained Semantic Accents
  static const Color urgentRose = Color(0xFFE11D48); // Red/Rose 600
  static const Color warningOchre = Color(0xFFD97706); // Amber 600
  static const Color successSage = Color(0xFF059669); // Emerald 600
  static const Color infoSlate = Color(0xFF64748B); // Slate 500

  // --- SYSTEM UI OVERLAY ---

  static SystemUiOverlayStyle systemOverlayStyle(bool isDark) {
    return SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
      statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
      systemNavigationBarColor: isDark ? darkSurface : lightSurface,
      systemNavigationBarDividerColor: isDark ? darkBorder : lightBorder,
      systemNavigationBarIconBrightness:
          isDark ? Brightness.light : Brightness.dark,
      systemNavigationBarContrastEnforced: false,
    );
  }

  // --- THEME DATA ---

  static ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBg,
    colorScheme: const ColorScheme.light(
      surface: lightSurface,
      primary: lightAccent,
      secondary: brandCobalt,
      onPrimary: Colors.white,
      onSurface: lightTextPrimary,
    ),
    dividerTheme: const DividerThemeData(
      color: lightBorder,
      thickness: 1,
      space: 1,
    ),
    cardTheme: CardThemeData(
      color: lightSurface,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: lightBorder, width: 1),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: lightBg,
      foregroundColor: lightTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: systemOverlayStyle(false),
      titleTextStyle: const TextStyle(
        color: lightTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
    ),
    bottomNavigationBarTheme: const BottomNavigationBarThemeData(
      backgroundColor: lightSurface,
      selectedItemColor: lightTextPrimary,
      unselectedItemColor: lightTextMuted,
      elevation: 0,
      type: BottomNavigationBarType.fixed,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: lightSurface,
      elevation: 0,
      height: 64,
      indicatorColor: lightBorderSubtle,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: lightTextPrimary,
          );
        }
        return const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: lightTextMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: lightTextPrimary, size: 22);
        }
        return const IconThemeData(color: lightTextMuted, size: 22);
      }),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: lightBorderSubtle,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: lightBorder, width: 0.8),
      ),
      labelStyle: const TextStyle(
        fontSize: 12,
        color: lightTextSecondary,
        fontWeight: FontWeight.w500,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBg,
    colorScheme: const ColorScheme.dark(
      surface: darkSurface,
      primary: darkAccent,
      secondary: brandCobalt,
      onPrimary: Colors.white,
      onSurface: darkTextPrimary,
    ),
    dividerTheme: const DividerThemeData(
      color: darkBorder,
      thickness: 1,
      space: 1,
    ),
    cardTheme: CardThemeData(
      color: darkSurface,
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: darkBorder, width: 1),
      ),
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: darkBg,
      foregroundColor: darkTextPrimary,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      systemOverlayStyle: systemOverlayStyle(true),
      titleTextStyle: const TextStyle(
        color: darkTextPrimary,
        fontSize: 18,
        fontWeight: FontWeight.w600,
        letterSpacing: -0.3,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: darkSurface,
      elevation: 0,
      height: 64,
      indicatorColor: darkSurfaceElevated,
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: darkTextPrimary,
          );
        }
        return const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w500,
          color: darkTextMuted,
        );
      }),
      iconTheme: WidgetStateProperty.resolveWith((states) {
        if (states.contains(WidgetState.selected)) {
          return const IconThemeData(color: darkTextPrimary, size: 22);
        }
        return const IconThemeData(color: darkTextMuted, size: 22);
      }),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: darkSurfaceElevated,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: darkBorder, width: 0.8),
      ),
      labelStyle: const TextStyle(
        fontSize: 12,
        color: darkTextSecondary,
        fontWeight: FontWeight.w500,
      ),
    ),
  );
}
