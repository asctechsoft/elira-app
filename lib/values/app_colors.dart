import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF2B7EFB);
  static const secondary = Color(0xFF7B4FDB);
  static const gradientStart = Color(0xFF2B7EFB);
  static const gradientEnd = Color(0xFF7B4FDB);

  static const background = Color(0xFFEFF5FF);
  static const surface = Colors.white;
  static const cardBg = Color(0xFFF8FBFF);

  static const textPrimary = Color(0xFF1A2B6D);
  static const textSecondary = Color(0xFF6B7280);
  static const textHint = Color(0xFF9CA3AF);

  static const success = Color(0xFF22C55E);
  static const error = Color(0xFFEF4444);
  static const disabled = Color(0xFFD5DEEA);
  static const splashScript = Color(0xFF8BB8F0);
  static const proAccent = Color(0xFFF59E0B);

  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient backgroundGradient = LinearGradient(
    colors: [Color(0xFFD6EAFF), Color(0xFFEFF5FF), Color(0xFFEEEBFF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient heroBannerGradient = LinearGradient(
    colors: [Color(0xFF1A6EF8), Color(0xFF5B3BD6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // Quick action card colors
  static const actionEnhance = Color(0xFFD4F7EC);
  static const actionRemove = Color(0xFFFFE8E8);
  static const actionRetouch = Color(0xFFEDE8FF);
  static const actionFilters = Color(0xFFE8F0FF);
  static const actionBackground = Color(0xFFE0F7E0);
  static const actionAiMagic = Color(0xFFEDE8FF);
}
