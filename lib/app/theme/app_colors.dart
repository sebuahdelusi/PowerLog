import 'package:flutter/material.dart';

class AppColors {
  // Primary palette — electric / energy theme
  static const Color primary = Color(0xFF00E5FF);       // Cyan accent
  static const Color primaryDark = Color(0xFF00B8D4);
  static const Color secondary = Color(0xFFFFD600);      // Yellow/gold accent
  static const Color accent = Color(0xFF76FF03);          // Electric green

  // Backgrounds
  static const Color background = Color(0xFF0D1117);     // Deep dark
  static const Color surface = Color(0xFF161B22);        // Card/surface
  static const Color surfaceLight = Color(0xFF21262D);   // Elevated surface

  // Text
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);

  // Feedback
  static const Color success = Color(0xFF3FB950);
  static const Color warning = Color(0xFFD29922);
  static const Color error = Color(0xFFF85149);
  static const Color info = Color(0xFF58A6FF);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF00E5FF), Color(0xFF2979FF)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF161B22), Color(0xFF1C2333)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
