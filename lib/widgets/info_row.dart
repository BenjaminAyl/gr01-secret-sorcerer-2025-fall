import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'buttons/pill_button.dart';

class InfoRow extends StatelessWidget {
  final String title;
  final String? value;
  final String? actionLabel;     // made optional
  final Color? actionColor;
  final VoidCallback? onPress;   // made optional

  const InfoRow({
    super.key,
    required this.title,
    this.value,
    this.onPress,
    this.actionLabel,
    this.actionColor,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = (value != null && value!.trim().isNotEmpty);
    final hasButton = onPress != null;

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyles.bodyLarge.copyWith(color: AppColors.textAccent),
              ),
              if (hasValue) ...[
                AppSpacing.gapXS,
                Text(
                  value!,
                  style: TextStyles.body.copyWith(
                    color: AppColors.textAccentSecondary,
                  ),
                ),
              ],
            ],
          ),
        ),

        if (hasButton) ...[
          AppSpacing.gapWL,
          PillButton.small(
            label: actionLabel ?? 'Edit',
            onPressed: onPress!,
          ),
        ],
      ],
    );
  }
}
