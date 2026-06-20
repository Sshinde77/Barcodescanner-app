import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  static TextTheme textTheme({required Brightness brightness}) {
    final base = GoogleFonts.manropeTextTheme();
    final color = brightness == Brightness.dark
        ? AppColors.darkText
        : AppColors.lightText;
    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.w800,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
      titleLarge: base.titleLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.w700,
      ),
      titleMedium: base.titleMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w600,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        color: color,
        fontWeight: FontWeight.w500,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        color: color,
        fontWeight: FontWeight.w500,
      ),
      bodySmall: base.bodySmall?.copyWith(
        color: color,
        fontWeight: FontWeight.w500,
      ),
    );
  }
}
