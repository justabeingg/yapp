import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  AppTextStyles._();

  static TextStyle displayLarge = GoogleFonts.spaceGrotesk(
    fontSize: 36, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary, letterSpacing: -1.5,
  );
  static TextStyle displayMedium = GoogleFonts.spaceGrotesk(
    fontSize: 28, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -1.0,
  );
  static TextStyle headlineLarge = GoogleFonts.spaceGrotesk(
    fontSize: 22, fontWeight: FontWeight.w700,
    color: AppColors.textPrimary, letterSpacing: -0.5,
  );
  static TextStyle headlineMedium = GoogleFonts.spaceGrotesk(
    fontSize: 18, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static TextStyle titleMedium = GoogleFonts.spaceGrotesk(
    fontSize: 16, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
  static TextStyle bodyLarge = GoogleFonts.dmSans(
    fontSize: 16, fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );
  static TextStyle bodyMedium = GoogleFonts.dmSans(
    fontSize: 14, fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );
  static TextStyle labelLarge = GoogleFonts.dmSans(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary, letterSpacing: 0.5,
  );
  static TextStyle labelSmall = GoogleFonts.dmSans(
    fontSize: 11, fontWeight: FontWeight.w500,
    color: AppColors.textMuted, letterSpacing: 0.8,
  );
  static TextStyle username = GoogleFonts.spaceGrotesk(
    fontSize: 14, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );
}
