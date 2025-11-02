import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'pill_button.dart';

class InfoRow extends StatelessWidget {
  final String title;
  final String? value; // <- now optional
  final String actionLabel; // <- customizable action text
  final Color? actionColor; // <- optional color override
  final VoidCallback onPress;

  const InfoRow({
    super.key,
    required this.title,
    this.value, // <- optional
    required this.onPress,
    this.actionLabel = 'Edit', // <- default label
    this.actionColor, // <- optional
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = (value != null && value!.trim().isNotEmpty);

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyles.bodyLarge.copyWith(color: Colors.white),
              ),
              if (hasValue) ...[
                AppSpacing.gapXS,
                Text(
                  value!,
                  style: TextStyles.body.copyWith(
                    color: AppColors.customAccent,
                  ),
                ),
              ],
            ],
          ),
        ),
        AppSpacing.gapWL,
        PillButton.small(
          label: actionLabel,
          onPressed: onPress,
          // If your PillButton supports a color prop, pass it here. Otherwise, keep default.
          // color: actionColor ?? AppColors.secondaryBrand,
        ),
      ],
    );
  }
}
