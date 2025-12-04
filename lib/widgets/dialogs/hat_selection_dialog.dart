import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/models/hats.dart';

class HatSelectionDialog extends StatefulWidget {
  final String currentHatColor;
  final int level;

  const HatSelectionDialog({
    super.key,
    required this.currentHatColor,
    required this.level
  });

  @override
  State<HatSelectionDialog> createState() => _HatSelectionDialogState();
}

class _HatSelectionDialogState extends State<HatSelectionDialog> {
  late String _previewHat;

  @override
  void initState() {
    super.initState();
    _previewHat = widget.currentHatColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.primaryBrand,
      alignment: Alignment.center,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),

      // Title
      titlePadding: const EdgeInsets.only(top: 16),
      title: Center(
        child: Text(
          'Choose Hat',
          style: TextStyles.title,
        ),
      ),

      contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),

      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),

            // 🔥 HAT-ONLY PREVIEW
            SizedBox(
              width: 180,
              height: 130,
              child: Center(
                child: Image.asset(
                  'assets/images/hats/$_previewHat.png',
                  height: AppSpacing.hatHeightLarge,
                  width: AppSpacing.hatWidthLarge,
                  fit: BoxFit.contain,
                ),
              ),
            ),

            const SizedBox(height: 8),

            Text(
              'Choose a hat and press "OK"',
              style: TextStyles.body.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            // Hat selection grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: HatColors.values.length,
              itemBuilder: (context, index) {
                final hatEnum = HatColors.values[index];
                final hatKey = hatColorToString(hatEnum);
                final hatMeta = hatColorInfo[hatEnum]!;
                final isUnlocked = widget.level >= hatMeta.requiredLevel;
                final isSelected = hatKey == _previewHat;

                return InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  onTap: isUnlocked
                      ? () {
                          setState(() {
                            _previewHat = hatKey;
                          });
                        }
                      : null,
                  child: Stack(
                    children: [
                      // --- Hat tile ---
                      Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.secondaryBrand.withOpacity(0.20)
                              : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.secondaryBrand
                                : Colors.white24,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Opacity(
                          opacity: isUnlocked ? 1.0 : 0.25, // fade locked hats
                          child: Image.asset(
                            'assets/images/hats/$hatKey.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      // --- Lock overlay + level ---
                      if (!isUnlocked)
                        Positioned.fill(
                          child: Container(
                            alignment: Alignment.center,
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 30,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Lvl ${hatMeta.requiredLevel}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                );

              },
            ),
          ],
        ),
      ),

      // Buttons
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.only(bottom: 12, top: 4),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Cancel',
            style: TextStyle(
              color: AppColors.textAccentSecondary,
              fontSize: 16,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_previewHat),
          child: const Text(
            'OK',
            style: TextStyle(
              color: AppColors.textAccent,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }
}
