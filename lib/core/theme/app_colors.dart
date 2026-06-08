import 'package:flutter/material.dart';

class AppColors {
  // === DARK THEME ===
  static const background = Color(0xFF0A0A0F);
  static const surface = Color(0xFF14141C);
  static const cardBg = Color(0xFF1C1C28);
  static const cardBorder = Color(0xFF2A2A3A);

  // === LIGHT THEME ===
  static const backgroundLight = Color(0xFFF5F5FF);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const cardBgLight = Color(0xFFFFFFFF);
  static const cardBorderLight = Color(0xFFE5E7EB);

  // Brand (same in both themes)
  static const primary = Color(0xFF6366F1);
  static const primaryLight = Color(0xFF818CF8);
  static const primaryDark = Color(0xFF4F46E5);
  static const primaryContainer = Color(0xFFEEF2FF);

  // Semantic
  static const success = Color(0xFF10B981);
  static const successBg = Color(0xFF0D2E22);
  static const successBgLight = Color(0xFFECFDF5);
  static const warning = Color(0xFFF59E0B);
  static const warningBg = Color(0xFF2E1F0A);
  static const warningBgLight = Color(0xFFFEFCE8);
  static const error = Color(0xFFEF4444);
  static const errorBg = Color(0xFF2E0F0F);
  static const errorBgLight = Color(0xFFFEF2F2);

  // Text — dark
  static const textPrimary = Color(0xFFF0EDE8);
  static const textSecondary = Color(0xFF9CA3AF);
  static const textMuted = Color(0xFF4B5563);

  // Text — light
  static const textPrimaryLight = Color(0xFF111827);
  static const textSecondaryLight = Color(0xFF6B7280);
  static const textMutedLight = Color(0xFF9CA3AF);

  // Category colors (vibrant, same in both themes)
  static const catFood = Color(0xFFFF6B6B);
  static const catTransport = Color(0xFF4ECDC4);
  static const catShopping = Color(0xFFA78BFA);
  static const catEntertainment = Color(0xFFF59E0B);
  static const catBills = Color(0xFF60A5FA);
  static const catHealth = Color(0xFFFC8181);
  static const catEducation = Color(0xFF34D399);
  static const catInvestment = Color(0xFF10B981);
  static const catIncome = Color(0xFF10B981);
  static const catAtm = Color(0xFF94A3B8);
  static const catSendMoney = Color(0xFFEC4899);
  static const catOther = Color(0xFF6B7280);
}

// BuildContext extension for adaptive colors
extension SpendLensTheme on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get bgColor => isDark ? AppColors.background : AppColors.backgroundLight;
  Color get surfaceColor => isDark ? AppColors.surface : AppColors.surfaceLight;
  Color get cardColor => isDark ? AppColors.cardBg : AppColors.cardBgLight;
  Color get cardBorderColor => isDark ? AppColors.cardBorder : AppColors.cardBorderLight;

  Color get textPrimary => isDark ? AppColors.textPrimary : AppColors.textPrimaryLight;
  Color get textSecondary => isDark ? AppColors.textSecondary : AppColors.textSecondaryLight;
  Color get textMuted => isDark ? AppColors.textMuted : AppColors.textMutedLight;

  Color get successBgColor => isDark ? AppColors.successBg : AppColors.successBgLight;
  Color get warningBgColor => isDark ? AppColors.warningBg : AppColors.warningBgLight;
  Color get errorBgColor => isDark ? AppColors.errorBg : AppColors.errorBgLight;
}
