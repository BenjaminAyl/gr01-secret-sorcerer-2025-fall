import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';

class TextStyles {
  // Display / Title styles
  static final TextStyle title = GoogleFonts.quintessential(
    textStyle: const TextStyle(
      fontSize: 48,
      fontWeight: FontWeight.w500,
      color: AppColors.textAccent,
    ),
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
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textAccent,
  );

  static const TextStyle body = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textAccent,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.textAccent,
  );

  // Labels, captions, UI elements
  static const TextStyle label = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textAccent,
    letterSpacing: 0.5,
  );

  static const TextStyle inputText = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.primaryBrand,
    letterSpacing: 0.5,
  );
}
