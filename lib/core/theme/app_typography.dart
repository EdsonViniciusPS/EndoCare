import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:endocare/core/theme/app_colors.dart';

/// Tipografia acolhedora e legível do EndoCare usando `google_fonts`.
///
/// Combina **Nunito** (arredondada e humana, alinhada ao logotipo EndoCare)
/// para títulos com **Plus Jakarta Sans** para leitura clara e confortável.
abstract final class AppTypography {
  static TextTheme buildTextTheme({
    Color primaryTextColor = AppColors.textPrimary,
    Color secondaryTextColor = AppColors.textSecondary,
  }) {
    return TextTheme(
      displayLarge: GoogleFonts.nunito(
        fontSize: 34,
        fontWeight: FontWeight.w800,
        height: 1.2,
        letterSpacing: -0.5,
        color: primaryTextColor,
      ),
      displayMedium: GoogleFonts.nunito(
        fontSize: 28,
        fontWeight: FontWeight.w800,
        height: 1.25,
        letterSpacing: -0.3,
        color: primaryTextColor,
      ),
      displaySmall: GoogleFonts.nunito(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        height: 1.28,
        color: primaryTextColor,
      ),
      headlineLarge: GoogleFonts.nunito(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.3,
        color: primaryTextColor,
      ),
      headlineMedium: GoogleFonts.nunito(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        height: 1.32,
        color: primaryTextColor,
      ),
      headlineSmall: GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: primaryTextColor,
      ),
      titleLarge: GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.w700,
        height: 1.35,
        color: primaryTextColor,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: primaryTextColor,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        height: 1.4,
        color: primaryTextColor,
      ),
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: primaryTextColor,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: secondaryTextColor,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.45,
        color: secondaryTextColor,
      ),
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        height: 1.3,
        letterSpacing: 0.1,
        color: primaryTextColor,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        height: 1.3,
        color: secondaryTextColor,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        height: 1.25,
        letterSpacing: 0.2,
        color: secondaryTextColor,
      ),
    );
  }
}
