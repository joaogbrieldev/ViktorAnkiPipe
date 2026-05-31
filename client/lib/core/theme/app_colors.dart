import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF007AFF);
  static const secondary = Color(0xFF5856D6);
  static const tertiary = Color(0xFF9E3D00);
  static const background = Color(0xFFF2F2F7);
  static const surface = Color(0xFFFFFFFF);
  static const onSurface = Color(0xFF1A1B1F);
  static const onSurfaceVariant = Color(0xFF414755);
  static const outline = Color(0xFF717786);
  static const outlineVariant = Color(0xFFC1C6D7);
  static const error = Color(0xFFBA1A1A);
  static const searchFill = Color(0xFFE9E9EB);

  static Color get ocrHighlight => primary.withAlpha(26); // 10% opacity
}
