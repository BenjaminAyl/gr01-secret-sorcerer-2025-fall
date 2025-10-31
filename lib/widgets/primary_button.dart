import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  final double? width;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.width,
    this.height = AppSpacing.buttonHeightLarge,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width ?? AppSpacing.cardWidthNarrow,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryBrand,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
          ),
          elevation: 0,
        ),
        child: Text(
          label,
          style: TextStyles.subheading,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
