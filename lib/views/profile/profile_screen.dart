import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/controllers/user_auth.dart';
import 'package:secret_sorcerer/models/user_model.dart';
import 'package:secret_sorcerer/utils/audio_helper.dart';
import 'package:secret_sorcerer/widgets/buttons/back_nav_button.dart';
import 'package:secret_sorcerer/widgets/buttons/primary_button.dart';
import 'package:secret_sorcerer/widgets/dialogs/volume_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  AppUser? _user;
  final userAuth = UserAuth();
  String _hatColor = 'hatDefault';

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final currentUser = await userAuth.getCurrentUser();
    setState(() {
      _user = currentUser;
      _hatColor = currentUser?.hatColor ?? 'hatDefault';
      });
  }

  @override
  Widget build(BuildContext context) {
    final nickname = _user?.nickname ?? '';
    final username = '@${_user?.username ?? ''}';
    return Scaffold(
      backgroundColor: AppColors.secondaryBG,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryBG,
        leading: BackNavButtonSound(icon: Icons.cancel),
        centerTitle: true,
        title: const Text('Profile', style: TextStyles.heading),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.volume_up,
              color: AppColors.customAccent,
              size: AppSpacing.iconSizeLarge,
            ),
            tooltip: 'Volume settings',
            onPressed: () {
              AudioHelper.playSFX("enterButton.wav");
              showVolumeDialog(context);
            },
          ),
        ],
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
                SizedBox(
                  height: 140,   // give enough room for hat + avatar
                  child: Stack(
                    clipBehavior: Clip.none,   // important
                    children: [
                      Positioned(
                        top: 40,  // Move avatar down
                        left: 0,
                        right: 0,
                        child: CircleAvatar(
                          radius: AppSpacing.avatarMedium,
                          backgroundColor: AppColors.secondaryBrand,
                          child: Icon(
                            Icons.person,
                            size: AppSpacing.iconSizeLarge,
                            color: Colors.white,
                          ),
                        ),
                      ),

                      Positioned(
                        top: 0,  // hat sits above the avatar now
                        left: 0,
                        right: 0,
                        child: Image.asset(
                          'assets/images/hats/$_hatColor.png',
                          height: 50,
                          width: 50,
                        ),
                      ),
                    ],
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
