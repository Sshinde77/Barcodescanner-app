import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF14B8A6);
  static const Color accent = Color(0xFF06B6D4);
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color danger = Color(0xFFEF4444);
  static const Color info = Color(0xFF0EA5E9);

  static const Color lightBackground = Color(0xFFF8F9FC);
  static const Color lightSurface = Colors.white;
  static const Color lightMuted = Color(0xFFE9EDF7);
  static const Color lightBorder = Color(0xFFE1E7F0);
  static const Color lightText = Color(0xFF111827);
  static const Color lightTextMuted = Color(0xFF6B7280);

  static const Color darkBackground = Color(0xFF121420);
  static const Color darkSurface = Color(0xFF171A2A);
  static const Color darkMuted = Color(0xFF20253A);
  static const Color darkBorder = Color(0xFF2B3046);
  static const Color darkText = Color(0xFFF8FAFC);
  static const Color darkTextMuted = Color(0xFF9CA3AF);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, secondary],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient darkHeroGradient = LinearGradient(
    colors: [Color(0xFF1E1B4B), Color(0xFF0F172A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
