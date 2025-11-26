import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/models/hats.dart';

class HatSelectionDialog extends StatefulWidget {
  final String currentHatColor; // starting hat

  const HatSelectionDialog({super.key, required this.currentHatColor});

  @override
  State<HatSelectionDialog> createState() => _HatSelectionDialogState();
}

class _HatSelectionDialogState extends State<HatSelectionDialog> {
  late String _previewHat; // current hat being "tried on"

  @override
  void initState() {
    super.initState();
    _previewHat = widget.currentHatColor;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.primaryBrand,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      titleTextStyle: TextStyles.title,
      title: const Text('Choose Hat'),
      content: SizedBox(
        width: double.minPositive,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar + hat preview
            SizedBox(
              width: 220,
              height: 200,
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

            const SizedBox(height: 8),

            Text(
              'Try on different hats before choosing one.',
              style: TextStyles.body.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 16),

            // Hat grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
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
                          : Colors.black.withOpacity(0.1),
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
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(_previewHat),
          child: const Text('OK', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
