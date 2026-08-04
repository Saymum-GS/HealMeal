// ============================================================================
// HealMeal Design System Configuration
// ============================================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

// -- Assets ------------------------------------------------------------------

class AppAssets {
  static String logo = 'assets/images/healmeal_logo.webp';
}

// -- Colors ------------------------------------------------------------------

class AppColors {
  // -- Primary healthcare colors --
  static const Color primary = Color(0xFF006C67); // Deep Teal/Green for health
  static const Color primaryDark = Color(0xFF004D49);
  static const Color primaryLight = Color(0xFFE0F2F1);
  static const Color brandBlue = Color(0xFF1A56DB);

  // -- Functional Colors --
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFE11D48);
  static const Color info = Color(0xFF3B82F6);

  // -- Functional Backgrounds --
  static const Color successBg = Color(0xFFECFDF5);
  static const Color warningBg = Color(0xFFFFFBEB);
  static const Color errorBg = Color(0xFFFFE4E6);
  static const Color infoBg = Color(0xFFEFF6FF);

  // -- Neutral Colors (Light Mode) --
  static const Color white = Color(0xFFFFFFFF);
  static const Color surface = Color(0xFFF8FAFC);
  static const Color subtle = Color(0xFFF1F5F9);
  static const Color border = Color(0xFFE2E8F0);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color muted = Color(0xFF94A3B8);

  // -- Neutral Colors (Dark Mode) --
  static const Color darkBg = Color(0xFF0F172A);
  static const Color darkSurface = Color(0xFF1E293B);
  static const Color darkCard = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPri = Color(0xFFF8FAFC);
  static const Color darkTextSec = Color(0xFFCBD5E1);
  static const Color darkMuted = Color(0xFF94A3B8);

  // -- Legacy/Compatibility --
  static const Color accentGold = Color(0xFFF59E0B);
  static const Color accentBlue = Color(0xFF3B82F6);
  static const Color accentTeal = Color(0xFF14B8A6);
  static const Color accentOrange = Color(0xFFF97316);
  static const Color accentRed = Color(0xFFEF4444);
  static const Color accentPurple = Color(0xFF8B5CF6);
  static const Color brandRed = error;
  static const Color brandRedLight = Color(0xFFFFE4E6);
  static const Color brandBlueLight = Color(0xFFEBF0FD);
  static const Color primaryMid = Color(0xFF93AFFE);
  static const Color secondary = textSecondary;
  static const Color textDark = Color(0xFF020617);
  static const Color brandBlueDark = Color(0xFF1041A3);

  static const Gradient primaryGradient = LinearGradient(
    colors: [primary, primaryDark],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // -- Simple Shadows --
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.04),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.02),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];
}

// -- Spacing & Radius --------------------------------------------------------

class AppSpacing {
  static double get xs => 4.w;
  static double get sm => 6.w;
  static double get md => 10.w;
  static double get lg => 14.w;
  static double get xl => 18.w;
  static double get xxl => 20.w;
  static double get xxxl => 24.w;
}

class AppRadius {
  static BorderRadius get sm => BorderRadius.circular(8.r);
  static BorderRadius get md => BorderRadius.circular(12.r);
  static BorderRadius get lg => BorderRadius.circular(16.r);
  static BorderRadius get xl => BorderRadius.circular(24.r);
  static BorderRadius get pill => BorderRadius.circular(99.r);
}

// -- Text Styles -------------------------------------------------------------

class AppTextStyles {
  static final String _bengaliFont = 'NotoSansBengali';

  static TextStyle get displayHero => GoogleFonts.dmSans(
    fontSize: 32.sp,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.0,
    height: 1.1,
  );

  static TextStyle get h1 => TextStyle(
    fontFamily: _bengaliFont,
    fontSize: 24.sp,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: -0.5,
  );

  static TextStyle get h2 => TextStyle(
    fontFamily: _bengaliFont,
    fontSize: 20.sp,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static TextStyle get h3 => TextStyle(
    fontFamily: _bengaliFont,
    fontSize: 16.sp,
    fontWeight: FontWeight.w600,
    height: 1.4,
  );

  static TextStyle get bodyLarge => TextStyle(
    fontFamily: _bengaliFont,
    fontSize: 16.sp,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodyMedium => TextStyle(
    fontFamily: _bengaliFont,
    fontSize: 14.sp,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static TextStyle get bodySmall => TextStyle(
    fontFamily: _bengaliFont,
    fontSize: 12.sp,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static TextStyle get bodyXSmall => TextStyle(
    fontFamily: _bengaliFont,
    fontSize: 11.sp,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );

  static TextStyle get labelLarge => TextStyle(
    fontFamily: _bengaliFont,
    fontSize: 14.sp,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get labelMedium => TextStyle(
    fontFamily: _bengaliFont,
    fontSize: 12.sp,
    fontWeight: FontWeight.w600,
  );

  static TextStyle get labelSmall => TextStyle(
    fontFamily: _bengaliFont,
    fontSize: 11.sp,
    fontWeight: FontWeight.w600,
  );

  // -- Price Styles --
  static TextStyle get priceLarge => GoogleFonts.dmSans(
    fontSize: 24.sp,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
  );

  static TextStyle get priceMedium =>
      GoogleFonts.dmSans(fontSize: 18.sp, fontWeight: FontWeight.w700);

  static TextStyle get priceSmall =>
      GoogleFonts.dmSans(fontSize: 14.sp, fontWeight: FontWeight.w600);
}

// -- Theme Extension ---------------------------------------------------------

extension ThemeColorsExt on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get colorTextPrimary =>
      isDarkMode ? AppColors.darkTextPri : AppColors.textPrimary;
  Color get colorTextSecondary =>
      isDarkMode ? AppColors.darkTextSec : AppColors.textSecondary;
  Color get colorTextMuted =>
      isDarkMode ? AppColors.darkMuted : AppColors.muted;
  Color get colorBorder => isDarkMode ? AppColors.darkBorder : AppColors.border;
  Color get colorSurface =>
      isDarkMode ? AppColors.darkSurface : AppColors.surface;
  Color get colorCard => isDarkMode ? AppColors.darkCard : AppColors.white;
  Color get colorBg => isDarkMode ? AppColors.darkBg : AppColors.surface;
}
