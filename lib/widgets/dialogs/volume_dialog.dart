import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/widgets/buttons/pill_button.dart';
import 'package:secret_sorcerer/utils/audio_helper.dart';

Future<void> showVolumeDialog(BuildContext context) async {
  // Grab current values from AudioHelper
  double music = AudioHelper.musicVolume;
  double sfx = AudioHelper.sfxVolume;

  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) {
      return AlertDialog(
        backgroundColor: AppColors.secondaryBG,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusL),
        ),
        title: const Text(
          'Volume',
          style: TextStyles.heading,
          textAlign: TextAlign.center,
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            String pct(double v) => '${(v * 100).round()}%';

            Future<void> resetToDefault() async {
              setState(() {
                music = 1.0;
                sfx = 1.0;
              });

              await AudioHelper.resetVolumes(); // loads + saves
            }

            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // MUSIC SLIDER
                const Text('Music', style: TextStyles.bodyLarge),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: music,
                        onChanged: (value) async {
                          setState(() => music = value);
                          await AudioHelper.setVolume(value);
                        },
                        min: 0,
                        max: 1,
                        divisions: 20,
                        activeColor: AppColors.secondaryBrand,
                        inactiveColor:
                            AppColors.secondaryBrand.withOpacity(0.3),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        pct(music),
                        style: TextStyles.bodySmall,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),

                AppSpacing.gapM,

                // SFX SLIDER
                const Text('Sound Effects', style: TextStyles.bodyLarge),
                Row(
                  children: [
                    Expanded(
                      child: Slider(
                        value: sfx,
                        onChanged: (value) async {
                          setState(() => sfx = value);
                          await AudioHelper.setSfxVolume(value);
                        },
                        min: 0,
                        max: 1,
                        divisions: 20,
                        activeColor: AppColors.secondaryBrand,
                        inactiveColor:
                            AppColors.secondaryBrand.withOpacity(0.3),
                      ),
                    ),
                    SizedBox(
                      width: 40,
                      child: Text(
                        pct(sfx),
                        style: TextStyles.bodySmall,
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),

                AppSpacing.gapL,

                // RESET BUTTON
                Center(
                  child: PillButton.small(
                    label: 'Reset to default',
                    onPressed: resetToDefault,
                  ),
                ),
              ],
            );
          },
        ),
      );
    },
  );
}
