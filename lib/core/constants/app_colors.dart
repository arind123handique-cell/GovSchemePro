import 'package:flutter/material.dart';

/// Government ERP color palette as specified in the product brief.
class AppColors {
  AppColors._();

  static const Color primary = Color(0xFF0F4C81);
  static const Color secondary = Color(0xFFEAF3FA);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFED6C02);
  static const Color danger = Color(0xFFD32F2F);

  static const Color background = Color(0xFFF5F7FA);
  static const Color surface = Colors.white;
  static const Color textPrimary = Color(0xFF1A2027);
  static const Color textSecondary = Color(0xFF5A6473);
  static const Color border = Color(0xFFDDE3EA);

  /// Colors used for charts and status chips.
  static const List<Color> chartPalette = <Color>[
    Color(0xFF0F4C81),
    Color(0xFF2E7D32),
    Color(0xFFED6C02),
    Color(0xFFD32F2F),
    Color(0xFF6A1B9A),
    Color(0xFF00838F),
    Color(0xFF558B2F),
    Color(0xFF455A64),
  ];
}
