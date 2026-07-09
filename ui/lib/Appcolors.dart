import 'package:flutter/material.dart';


/// Central color palette so every screen/widget stays visually consistent.
class AppColors {
  AppColors._();

  static const Color primaryDark = Color(0xFF4C3FE0);
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFF9B8CF9);

  static const Color background = Color(0xFFF6F5FC);
  static const Color surface = Colors.white;

  static const Color textDark = Color(0xFF241C4B);
  static const Color textMuted = Color(0xFF6B6685);

  static const Color mapFill = Color(0xFFE3DEFB);
  static const Color mapBorder = Color(0xFF9B8CF9);
  static const Color mapSelected = Color(0xFFFF7A59);

  // Party colors used consistently across timeline + seat chart.
  static const Map<String, Color> partyColors = {
    'BJP': Color(0xFFFF7A00),
    'INC': Color(0xFF1E90D6),
    'AAP': Color(0xFF2ECC71),
    'Others': Color(0xFFB0B0C3),
  };

  static Color colorForParty(String party) =>
      partyColors[party] ?? const Color(0xFF8C86A8);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primaryLight],
  );
}


/// Central color palette so every screen/widget stays visually consistent.
class AppColors {
  AppColors._();

  static const Color primaryDark = Color(0xFF4C3FE0);
  static const Color primary = Color(0xFF6C5CE7);
  static const Color primaryLight = Color(0xFF9B8CF9);

  static const Color background = Color(0xFFF6F5FC);
  static const Color surface = Colors.white;

  static const Color textDark = Color(0xFF241C4B);
  static const Color textMuted = Color(0xFF6B6685);

  static const Color mapFill = Color(0xFFE3DEFB);
  static const Color mapBorder = Color(0xFF9B8CF9);
  static const Color mapSelected = Color(0xFFFF7A59);

  // Party colors used consistently across timeline + seat chart.
  static const Map<String, Color> partyColors = {
    'BJP': Color(0xFFFF7A00),
    'INC': Color(0xFF1E90D6),
    'AAP': Color(0xFF2ECC71),
    'Others': Color(0xFFB0B0C3),
  };

  static Color colorForParty(String party) =>
      partyColors[party] ?? const Color(0xFF8C86A8);

  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryDark, primaryLight],
  );
}