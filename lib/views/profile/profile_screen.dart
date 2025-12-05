import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/controllers/firebase.dart';
import 'package:secret_sorcerer/controllers/user_auth.dart';
import 'package:secret_sorcerer/models/game_player.dart';
import 'package:secret_sorcerer/models/user_model.dart';
import 'package:secret_sorcerer/utils/audio_helper.dart';
import 'package:secret_sorcerer/utils/current_style.dart';
import 'package:secret_sorcerer/widgets/avatar/avatar_display.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
  }

  Future<void> _loadUserInfo() async {
    final currentUser = await userAuth.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _user = currentUser;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_user == null && !CurrentStyle.isLoaded) {
      return const Scaffold(
        backgroundColor: AppColors.secondaryBG,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final String hatColor = CurrentStyle.hatColor;
    final String avatarColor = CurrentStyle.avatarColor;

    final String nickname = CurrentStyle.isLoaded
        ? CurrentStyle.nickname
        : (_user?.nickname ?? '');

    final String rawUsername = CurrentStyle.isLoaded
        ? CurrentStyle.username
        : (_user?.username ?? '');

    final int currentLevel = CurrentStyle.isLoaded
        ? CurrentStyle.currentLevel
        : (_user?.currentLevel ?? 1);

    final int exp = CurrentStyle.isLoaded
        ? CurrentStyle.currentExp
        : (_user?.exp ?? 0);

    final String username = '@$rawUsername';

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
        child: SingleChildScrollView(
          padding: AppSpacing.screen,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppSpacing.gapM,

              // Avatar preview
              SizedBox(
                width: 220,
                height: 140,
                child: Center(
                  child: AvatarDisplay(
                    avatarColor: avatarColor,
                    hatColor: hatColor,
                    radius: AppSpacing.avatarMedium,
                  ),
                ),
              ),

              AppSpacing.gapM,

              // Name + username
              Text(nickname, style: TextStyles.bodyLarge),
              AppSpacing.gapXS,
              Text(username, style: TextStyles.body),

              AppSpacing.gapM,

              // XP BAR moved below nickname/username
              Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text("Lv $currentLevel", style: TextStyles.body),
                      Text("Lv ${currentLevel + 1}", style: TextStyles.body),
                    ],
                  ),

                  AppSpacing.gapXS,

                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      height: 18,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade800,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor: (exp.clamp(0, 100)).toDouble() / 100,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.customAccent,
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              AppSpacing.gapL,

              PrimaryButton(
                label: 'Edit Profile',
                onPressed: () async {
                  await context.push('/profile/edit');
                  await _loadUserInfo();
                  if (mounted) setState(() {});
                },
              ),

              AppSpacing.buttonSpacing,
              PrimaryButton(
                label: 'Manage Friends',
                onPressed: () async {
                  await context.push('/profile/friends');
                  await _loadUserInfo();
                },
              ),

              AppSpacing.buttonSpacing,
              PrimaryButton(
                label: 'Log Out',
                onPressed: () async {
                  await userAuth.signOut();
                  CurrentStyle.reset();
                  if (!context.mounted) return;
                  context.push('/');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
