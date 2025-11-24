import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/utils/audio_helper.dart';

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
        onPressed: () {
          AudioHelper.playSFX('enterButton.wav'); 
          onPressed(); 
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.secondaryBrand,
          foregroundColor: Colors.white,
          minimumSize: Size(double.infinity, height),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusButton),
            side: BorderSide(
              color: AppColors.customAccent, 
              width: 2.0, 
            ),
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
