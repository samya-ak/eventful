import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF10212F);
  static const Color secondary = Color(0xFF293743);
  static const Color button = Color(0xFF2E4751);
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color success = Color(
    0xFF3CB371,
  ); // A more muted green (MediumSeaGreen)
  static const Color error = Color(
    0xFFD9534F,
  ); // Muted red (Bootstrap's $danger)

  // Helper methods for alpha values
  static Color whiteWithAlpha(double opacity) =>
      white.withAlpha((opacity * 255).round());

  static Color blackWithAlpha(double opacity) =>
      black.withAlpha((opacity * 255).round());
}
