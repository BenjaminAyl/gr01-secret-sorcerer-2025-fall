import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/widgets/avatar/avatar_display.dart';
import 'package:secret_sorcerer/widgets/buttons/pill_button.dart';
import 'package:secret_sorcerer/widgets/dialogs/hat_selection_dialog.dart';
import 'package:secret_sorcerer/widgets/dialogs/avatar_selection_dialog.dart';

/// Result returned when the user taps "Save" in the profile customization dialog.
class ProfileCustomizationResult {
  final String hatColor;
  final String avatarColor;

  ProfileCustomizationResult({
    required this.hatColor,
    required this.avatarColor,
  });
}

class ProfileCustomizationDialog extends StatefulWidget {
  final String currentHatColor;
  final String currentAvatarColor; // Firestore field: avatarColor
  final Future<void> Function()? onChangeProfilePicture;

  const ProfileCustomizationDialog({
    super.key,
    required this.currentHatColor,
    required this.currentAvatarColor,
    this.onChangeProfilePicture,
  });

  @override
  State<ProfileCustomizationDialog> createState() =>
      _ProfileCustomizationDialogState();
}

class _ProfileCustomizationDialogState
    extends State<ProfileCustomizationDialog> {
  late String _tempHatColor;
  late String _tempAvatarColor;

  @override
  void initState() {
    super.initState();
    _tempHatColor = widget.currentHatColor;
    _tempAvatarColor = widget.currentAvatarColor;
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

  Future<void> _chooseAvatar() async {
    final selectedAvatarColor = await showDialog<String>(
      context: context,
      builder: (_) =>
          AvatarSelectionDialog(currentAvatarColor: _tempAvatarColor),
    );

    if (selectedAvatarColor != null) {
      setState(() {
        _tempAvatarColor = selectedAvatarColor;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.primaryBrand,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
      ),
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
      contentPadding: const EdgeInsets.fromLTRB(24, 24, 24, 20),

      // ^ slightly smaller top padding, we add our own spacer below
      content: SizedBox(
        width: 350,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 🔥 Extra top space so the hat doesn’t hit the top border
            const SizedBox(height: 48),

            /// Top avatar preview
            AvatarDisplay(
              avatarColor: _tempAvatarColor,
              hatColor: _tempHatColor,
              radius: AppSpacing.avatarMedium,
            ),

            const SizedBox(height: 12),

            /// Buttons
            PillButton.small(label: 'Change hat', onPressed: _chooseHat),

            const SizedBox(height: 12),

            PillButton.small(label: 'Change avatar', onPressed: _chooseAvatar),

            const SizedBox(height: 22),

            Text(
              'Adjust your avatar and hat, then save or discard.',
              style: TextStyles.body.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),
          ],
        ),
      ),

      actionsAlignment: MainAxisAlignment.center,
      actionsPadding: const EdgeInsets.only(bottom: 14),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(
              ProfileCustomizationResult(
                hatColor: _tempHatColor,
                avatarColor: _tempAvatarColor,
              ),
            );
          },
          child: const Text('Save', style: TextStyle(color: Colors.white)),
        ),
      ],
    );
  }
}
