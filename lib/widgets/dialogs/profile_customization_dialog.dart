import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/widgets/buttons/pill_button.dart';
import 'package:secret_sorcerer/widgets/dialogs/hat_selection_dialog.dart';

/// Result returned when the user taps "Save" in the profile customization dialog.
class ProfileCustomizationResult {
  final String hatColor;
  ProfileCustomizationResult({required this.hatColor});
}

class ProfileCustomizationDialog extends StatefulWidget {
  final String currentHatColor;
  final Future<void> Function()? onChangeProfilePicture;

  const ProfileCustomizationDialog({
    super.key,
    required this.currentHatColor,
    this.onChangeProfilePicture,
  });

  @override
  State<ProfileCustomizationDialog> createState() =>
      _ProfileCustomizationDialogState();
}

class _ProfileCustomizationDialogState
    extends State<ProfileCustomizationDialog> {
  late String _tempHatColor;

  @override
  void initState() {
    super.initState();
    _tempHatColor = widget.currentHatColor;
  }

  Future<void> _chooseHat() async {
    final selectedHat = await showDialog<String>(
      context: context,
      builder: (_) => HatSelectionDialog(currentHatColor: _tempHatColor),
    );

    if (selectedHat != null) {
      setState(() {
        _tempHatColor = selectedHat;
      });
    }
  }

  Future<void> _changeProfilePicture() async {
    if (widget.onChangeProfilePicture != null) {
      await widget.onChangeProfilePicture!();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile picture editing not available.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.primaryBrand,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),

      title: null,
      titlePadding: EdgeInsets.zero,

      // WIDEN DIALOG
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),

      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 10),
      content: SizedBox(
        width: 350, // wider dialog
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 240,
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
                      'assets/images/hats/$_tempHatColor.png',
                      height: AppSpacing.hatHeightLarge,
                      width: AppSpacing.hatWidthLarge,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            Column(
              children: [
                PillButton.small(label: 'Choose hat', onPressed: _chooseHat),
                const SizedBox(height: 10),
                PillButton.small(
                  label: 'Change profile picture',
                  onPressed: _changeProfilePicture,
                ),
              ],
            ),

            const SizedBox(height: 12),
            Text(
              'Adjust your hat and picture, then save or discard.',
              style: TextStyles.body.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),

      // CENTERED ACTION BUTTONS
      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.only(bottom: 10),

      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(
              context,
            ).pop(ProfileCustomizationResult(hatColor: _tempHatColor));
          },
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
