import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/utils/audio_helper.dart';

class BackNavButtonSound extends StatelessWidget {
  final IconData icon;

  const BackNavButtonSound({
    super.key,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(
        icon,
        color: AppColors.customAccent,
        size: AppSpacing.iconSizeLarge,
      ),
      tooltip: 'Back',
      onPressed: () async {
        AudioHelper.playSFX("backButton.wav");
        await Future.delayed(const Duration(milliseconds: 120));
        if (context.mounted) context.pop();
      },
    );
  }
}
