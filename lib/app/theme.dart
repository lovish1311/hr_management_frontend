import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hr_management/core/constants/colors.dart';
import 'package:hr_management/core/theme/theme_manager.dart';

class AppTheme {
  static TextTheme _buildTextTheme(TextTheme base, String family) {
    switch (family) {
      case 'Inter':
        return GoogleFonts.interTextTheme(base);
      case 'Roboto':
        return GoogleFonts.robotoTextTheme(base);
      case 'Outfit':
        return GoogleFonts.outfitTextTheme(base);
      case 'Poppins':
        return GoogleFonts.poppinsTextTheme(base);
      case 'Lato':
        return GoogleFonts.latoTextTheme(base);
      case 'Chilanka':
      case 'Chillar':
      case 'Chilanka (Chillar)':
        return GoogleFonts.chilankaTextTheme(base);
      default:
        return base;
    }
  }

  static ThemeData get lightTheme {
    final activeTheme = ThemeManager.instance.activeThemeConfig;
    final fontFamily = ThemeManager.instance.fontFamily;

    // Guaranteed dark text for light theme (never white!)
    final textColor = activeTheme.isDarkTheme ? const Color(0xFF0F172A) : activeTheme.surfaceText;
    final textSecondaryColor = activeTheme.isDarkTheme ? const Color(0xFF475569) : activeTheme.surfaceTextSecondary;
    final cardColor = activeTheme.isDarkTheme ? const Color(0xFFF1F5F9) : activeTheme.card;
    final cardSoftColor = activeTheme.isDarkTheme ? const Color(0xFFE2E8F0) : activeTheme.cardSoft;
    final borderColor = activeTheme.isDarkTheme ? const Color(0xFFCBD5E1) : activeTheme.border;

    final baseTextTheme = ThemeData.light().textTheme.apply(
          bodyColor: textColor,
          displayColor: textColor,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: activeTheme.primary,
      scaffoldBackgroundColor: activeTheme.isDarkTheme ? AppColors.background : activeTheme.backgroundGradient.first,
      colorScheme: ColorScheme.light(
        primary: activeTheme.primary,
        onPrimary: Colors.white,
        secondary: activeTheme.secondary,
        onSecondary: Colors.white,
        surface: cardColor,
        onSurface: textColor,
        onSurfaceVariant: textSecondaryColor,
        error: activeTheme.danger,
        onError: Colors.white,
      ),
      iconTheme: IconThemeData(color: textColor),
      fontFamily: (fontFamily != 'Default' && fontFamily != 'Chilanka (Chillar)')
          ? fontFamily
          : (fontFamily == 'Chilanka (Chillar)' ? GoogleFonts.chilanka().fontFamily : null),
      textTheme: _buildTextTheme(baseTextTheme, fontFamily),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: activeTheme.onBackgroundText),
        actionsIconTheme: IconThemeData(color: activeTheme.onBackgroundText),
        titleTextStyle: TextStyle(
          color: activeTheme.onBackgroundText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardSoftColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: activeTheme.primary, width: 1.5),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final activeTheme = ThemeManager.instance.activeThemeConfig;
    final fontFamily = ThemeManager.instance.fontFamily;

    // Guaranteed high-contrast crisp text for dark theme
    final darkTextColor = activeTheme.isDarkTheme ? activeTheme.surfaceText : const Color(0xFFF8FAFC);
    final darkTextSecondaryColor = activeTheme.isDarkTheme ? activeTheme.surfaceTextSecondary : const Color(0xFF94A3B8);
    final cardColor = activeTheme.card;
    final cardSoftColor = activeTheme.cardSoft;
    final borderColor = activeTheme.border;

    final baseTextTheme = ThemeData.dark().textTheme.apply(
          bodyColor: darkTextColor,
          displayColor: darkTextColor,
        );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      primaryColor: activeTheme.primary,
      scaffoldBackgroundColor: activeTheme.isDarkTheme ? activeTheme.backgroundGradient.first : AppColors.darkBackground,
      colorScheme: ColorScheme.dark(
        primary: activeTheme.primary,
        onPrimary: Colors.white,
        secondary: activeTheme.secondary,
        onSecondary: Colors.white,
        surface: cardColor,
        onSurface: darkTextColor,
        onSurfaceVariant: darkTextSecondaryColor,
        error: activeTheme.danger,
        onError: Colors.white,
      ),
      iconTheme: IconThemeData(color: darkTextColor),
      fontFamily: (fontFamily != 'Default' && fontFamily != 'Chilanka (Chillar)')
          ? fontFamily
          : (fontFamily == 'Chilanka (Chillar)' ? GoogleFonts.chilanka().fontFamily : null),
      textTheme: _buildTextTheme(baseTextTheme, fontFamily),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: activeTheme.onBackgroundText),
        actionsIconTheme: IconThemeData(color: activeTheme.onBackgroundText),
        titleTextStyle: TextStyle(
          color: activeTheme.onBackgroundText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: borderColor),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: cardSoftColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: activeTheme.primary, width: 1.5),
        ),
      ),
    );
  }
}
