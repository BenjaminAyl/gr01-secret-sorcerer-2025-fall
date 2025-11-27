import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/models/hats.dart';

class HatSelectionDialog extends StatefulWidget {
  final String currentHatColor;

  const HatSelectionDialog({super.key, required this.currentHatColor});

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

      // Centered title
      titlePadding: const EdgeInsets.only(top: 16),
      title: Center(
        child: Text(
          'Choose Hat',
          style: TextStyles.title,
          textAlign: TextAlign.center,
        ),
      ),

      contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),

      content: SizedBox(
        width: 340, // wider dialog so grid/text aren't squeezed
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Gap at the top above the avatar
            const SizedBox(height: 20),

            // Avatar + hat preview
            SizedBox(
              width: 220,
              height: 180,
              child: Stack(
                alignment: Alignment.center,
                clipBehavior: Clip.none,
                children: [
                  const CircleAvatar(
                    radius: AppSpacing.avatarMedium,
                    backgroundColor: AppColors.secondaryBrand,
                    child: Icon(
                      Icons.person,
                      size: AppSpacing.avatarMedium,
                      color: Colors.white,
                    ),
                  ),
                  Transform.translate(
                    offset: const Offset(0, -66),
                    child: Image.asset(
                      'assets/images/hats/${_previewHat}.png',
                      height: AppSpacing.hatHeightLarge,
                      width: AppSpacing.hatWidthLarge,
                    ),
                  ),
                ],
              ),
            ),

            // Small gap below avatar before text
            const SizedBox(height: 4),

            Text(
              'Try on different hats then press "OK"',
              style: TextStyles.body.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            // Hat grid
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
                final isSelected = hatKey == _previewHat;

                return InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  onTap: () {
                    setState(() {
                      _previewHat = hatKey;
                    });
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.secondaryBrand.withOpacity(0.2)
                          : Colors.white.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(
                        AppSpacing.radiusCard,
                      ),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.secondaryBrand
                            : Colors.white24,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(8),
                    child: Image.asset(
                      'assets/images/hats/$hatKey.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),

      // Centered Cancel / OK buttons
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
            style: TextStyle(color: AppColors.textAccent, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
