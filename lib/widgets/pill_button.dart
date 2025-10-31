import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';

class PillButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final EdgeInsets padding;
  final double radius;
  final double fontSize;

  const PillButton._({
    required this.label,
    required this.onPressed,
    required this.padding,
    required this.radius,
    required this.fontSize,
  });

  factory PillButton.small({
    required String label,
    required VoidCallback onPressed,
  }) {
    return PillButton._(
      label: label,
      onPressed: onPressed,
      padding: AppSpacing.pillButton,
      radius: AppSpacing.radiusL,
      fontSize: 14,
    );
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.secondaryBrand,
        foregroundColor: Colors.white,
        padding: padding,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
      child: Text(
        label,
        style: TextStyles.bodySmall.copyWith(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
