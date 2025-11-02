import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/widgets/primary_button.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBrand,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBrand,
        leading: IconButton(
          icon: const Icon(
            Icons.cancel,
            color: AppColors.customAccent,
            size: AppSpacing.iconSizeLarge,
          ),
          onPressed: () => context.go('/home'),
          tooltip: 'Back',
        ),
        centerTitle: true,
        title: const Text('Profile', style: TextStyles.heading),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: AppSpacing.screen,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSpacing.gapM,
                // TODO: replace avatar with the user's avatar
                const CircleAvatar(
                  radius: AppSpacing.avatarMedium, // from constants
                  backgroundColor: AppColors.secondaryBrand,
                  child: Icon(
                    Icons.person,
                    size: AppSpacing.iconSizeLarge,
                    color: Colors.white,
                  ),
                ),
                AppSpacing.gapM,

                // User name + username
                const Text('Name', style: TextStyles.bodyLarge),
                AppSpacing.gapXS,
                const Text('@username', style: TextStyles.body),

                AppSpacing.gapXXL,

                // Profile buttons
                PrimaryButton(
                  label: 'Edit Profile',
                  onPressed: () => context.push('/profile/edit'),
                ),
                AppSpacing.buttonSpacing,
                PrimaryButton(
                  label: 'Manage Friends',
                  onPressed: () => context.push('/profile/friends'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
