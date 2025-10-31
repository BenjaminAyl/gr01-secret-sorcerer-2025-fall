import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';

// NEW: use the extracted widgets
import 'package:secret_sorcerer/widgets/info_row.dart';
import 'package:secret_sorcerer/widgets/pill_button.dart';

class EditProfileScreen extends StatelessWidget {
  const EditProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryBrand,
      appBar: AppBar(
        backgroundColor: AppColors.primaryBrand,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.customAccent,
            size: AppSpacing.iconSizeLarge,
          ),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        title: const Text('Edit Profile', style: TextStyles.subheading),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: AppSpacing.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Avatar with "Edit" pill
                Center(
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      const CircleAvatar(
                        radius: 56,
                        backgroundColor: AppColors.secondaryBrand,
                        child: Icon(
                          Icons.person,
                          size: 56,
                          color: Colors.white,
                        ),
                      ),
                      Positioned(
                        right: -18,
                        top: -10,
                        child: PillButton.small(
                          label: 'Edit',
                          onPressed: () {
                            // TODO: context.push('/profile/avatar');
                          },
                        ),
                      ),
                    ],
                  ),
                ),

                AppSpacing.gapXXL,

                // Rows
                InfoRow(
                  title: 'Display Name',
                  value: 'Name',
                  onPress: () {
                    // TODO: context.push('/profile/edit/display-name');
                  },
                ),

                AppSpacing.gapXL,

                InfoRow(
                  title: 'Username',
                  value: '@username',
                  onPress: () {
                    // TODO: context.push('/profile/edit/username');
                  },
                ),

                AppSpacing.gapXL,

                InfoRow(
                  title: 'Password',
                  value: '••••••••',
                  onPress: () {
                    // TODO: context.push('/profile/edit/password');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
