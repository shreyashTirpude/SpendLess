import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle _baseStyle({
    required double fontSize,
    required FontWeight fontWeight,
    Color color = AppColors.textPrimary,
  }) {
    return GoogleFonts.dmSans(
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      height: 1.5,
    );
  }

  // Display styles
  static TextStyle displayLarge = _baseStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
  );

  static TextStyle displayMedium = _baseStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
  );

  static TextStyle displaySmall = _baseStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
  );

  // Heading styles
  static TextStyle headingLarge = _baseStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
  );

  static TextStyle headingMedium = _baseStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
  );

  static TextStyle headingSmall = _baseStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
  );

  // Body styles
  static TextStyle bodyLarge = _baseStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
  );

  static TextStyle bodyMedium = _baseStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
  );

  static TextStyle bodySmall = _baseStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
  );

  // Label styles
  static TextStyle labelLarge = _baseStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
  );

  static TextStyle labelMedium = _baseStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
  );

  static TextStyle labelSmall = _baseStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
  );

  // Caption
  static TextStyle caption = _baseStyle(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
}
