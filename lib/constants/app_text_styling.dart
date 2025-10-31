import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';

class TextStyles {
  // Display / Title styles
  static const TextStyle title = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: AppColors.textAccent,
  );

  static const TextStyle heading = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.textAccent,
  );

  static const TextStyle subheading = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textAccent,
  );

  // Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textAccent,
  );

  static const TextStyle body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textAccent,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textAccent,
  );

  // Labels, captions, UI elements
  static const TextStyle label = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textAccent,
    letterSpacing: 0.5,
  );
}
