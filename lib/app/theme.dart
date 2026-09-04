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
    final baseTextTheme = ThemeData.light().textTheme.apply(
          bodyColor: activeTheme.text,
          displayColor: activeTheme.text,
        );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.background,
      colorScheme: ColorScheme.fromSeed(
        seedColor: activeTheme.primary,
        primary: activeTheme.primary,
        surface: activeTheme.card,
        brightness: Brightness.light,
      ),
      fontFamily: (fontFamily != 'Default' && fontFamily != 'Chilanka (Chillar)')
          ? fontFamily
          : (fontFamily == 'Chilanka (Chillar)' ? GoogleFonts.chilanka().fontFamily : null),
      textTheme: _buildTextTheme(baseTextTheme, fontFamily),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: activeTheme.onBackgroundText),
        titleTextStyle: TextStyle(
          color: activeTheme.onBackgroundText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: activeTheme.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: activeTheme.border),
        ),
      ),
    );
  }

  static ThemeData get darkTheme {
    final activeTheme = ThemeManager.instance.activeThemeConfig;
    final fontFamily = ThemeManager.instance.fontFamily;
    final baseTextTheme = ThemeData.dark().textTheme.apply(
          bodyColor: activeTheme.text,
          displayColor: activeTheme.text,
        );

    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: AppColors.darkBackground,
      colorScheme: ColorScheme.fromSeed(
        seedColor: activeTheme.primary,
        primary: activeTheme.primary,
        surface: activeTheme.card,
        brightness: Brightness.dark,
      ),
      fontFamily: (fontFamily != 'Default' && fontFamily != 'Chilanka (Chillar)')
          ? fontFamily
          : (fontFamily == 'Chilanka (Chillar)' ? GoogleFonts.chilanka().fontFamily : null),
      textTheme: _buildTextTheme(baseTextTheme, fontFamily),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: activeTheme.onBackgroundText),
        titleTextStyle: TextStyle(
          color: activeTheme.onBackgroundText,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
      cardTheme: CardThemeData(
        color: activeTheme.card,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: activeTheme.border),
        ),
      ),
    );
  }
}


