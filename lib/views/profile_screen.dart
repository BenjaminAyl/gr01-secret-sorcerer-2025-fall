import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/controllers/user_auth.dart';
import 'package:secret_sorcerer/models/user_model.dart';
import 'package:secret_sorcerer/widgets/primary_button.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _user;
  final userAuth = UserAuth();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final currentUser = await userAuth.getCurrentUser();
    setState(() => _user = currentUser);
  }

  @override
  Widget build(BuildContext context) {
    final nickname = _user?.nickname ?? '';
    final username = '@${_user?.username ?? ''}';
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
                const CircleAvatar(
                  radius: AppSpacing.avatarMedium,
                  backgroundColor: AppColors.secondaryBrand,
                  child: Icon(
                    Icons.person,
                    size: AppSpacing.iconSizeLarge,
                    color: Colors.white,
                  ),
                ),
                AppSpacing.gapM,

                // User name + username
                Text(nickname, style: TextStyles.bodyLarge),
                AppSpacing.gapXS,
                Text(username, style: TextStyles.body),

                AppSpacing.gapXXL,
                PrimaryButton(
                  label: 'Edit Profile',
                  onPressed: () => context.push('/profile/edit'),
                ),
                AppSpacing.buttonSpacing,
                PrimaryButton(
                  label: 'Manage Friends',
                  onPressed: () => context.push('/profile/friends'),
                ),
                AppSpacing.buttonSpacing,
                PrimaryButton(
                  label: 'Log Out',
                  onPressed: () async {
                    await userAuth.signOut();
                    if (!context.mounted) return;
                    context.push('/'); 
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
