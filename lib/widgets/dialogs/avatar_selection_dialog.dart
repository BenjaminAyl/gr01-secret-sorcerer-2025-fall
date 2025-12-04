import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/models/avatars.dart';
import 'package:secret_sorcerer/widgets/avatar/avatar_display.dart';

class AvatarSelectionDialog extends StatefulWidget {
  final String currentAvatarColor; // Firestore field: avatarColor
  final int level; // user's current level

  const AvatarSelectionDialog({super.key, required this.currentAvatarColor, required this.level});

  @override
  State<AvatarSelectionDialog> createState() => _AvatarSelectionDialogState();
}

class _AvatarSelectionDialogState extends State<AvatarSelectionDialog> {
  late String _previewAvatarColor;

  @override
  void initState() {
    super.initState();
    _previewAvatarColor = widget.currentAvatarColor;
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
          'Choose Avatar',
          style: TextStyles.title,
          textAlign: TextAlign.center,
        ),
      ),

      contentPadding: const EdgeInsets.fromLTRB(16, 0, 16, 0),

      content: SizedBox(
        width: 340,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 20),

            // Avatar preview with NO BACKGROUND, using shared widget
            AvatarDisplay(
              avatarColor: _previewAvatarColor,
              hatColor: null, // no hats here
              radius: AppSpacing.avatarMedium,
            ),

            const SizedBox(height: 4),

            Text(
              'Choose your avatar then press "OK"',
              style: TextStyles.body.copyWith(
                color: Colors.white.withOpacity(0.8),
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 10),

            // Avatar grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
              ),
              itemCount: AvatarColors.values.length,
              itemBuilder: (context, index) {
                final avatarEnum = AvatarColors.values[index];
                final avatarKey = avatarColorToString(avatarEnum);
                final isSelected = avatarKey == _previewAvatarColor;
                final avatarMeta = avatarColorInfo[avatarEnum]!;
                final isUnlocked = widget.level >= avatarMeta.requiredLevel;
                return InkWell(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                  onTap: isUnlocked
                      ? () {
                          setState(() {
                            _previewAvatarColor = avatarKey;
                          });
                        }
                      : null, // locked → disable tap
                  child: Stack(
                    children: [
                      // Avatar box
                      Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.secondaryBrand.withOpacity(0.2)
                              : Colors.white.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.customAccent
                                : Colors.white24,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        padding: const EdgeInsets.all(8),
                        child: Opacity(
                          opacity: isUnlocked ? 1.0 : 0.25, // fade locked avatars
                          child: Image.asset(
                            'assets/images/avatars/$avatarKey.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      // 🔒 LOCK OVERLAY + level requirement
                      if (!isUnlocked)
                        Positioned.fill(
                          child: Container(
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppSpacing.radiusCard),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.lock,
                                  color: Colors.white.withOpacity(0.9),
                                  size: 32,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "Lvl ${avatarMeta.requiredLevel}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
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
          onPressed: () => Navigator.of(context).pop(_previewAvatarColor),
          child: const Text(
            'OK',
            style: TextStyle(color: AppColors.textAccent, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
