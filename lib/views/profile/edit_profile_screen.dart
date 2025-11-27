import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/controllers/firebase.dart';
import 'package:secret_sorcerer/models/user_model.dart';
import 'package:secret_sorcerer/widgets/account/edit_nickname.dart';
import 'package:secret_sorcerer/widgets/account/edit_password.dart';
import 'package:secret_sorcerer/widgets/account/edit_username.dart';
import 'package:secret_sorcerer/widgets/buttons/back_nav_button.dart';
import 'package:secret_sorcerer/widgets/dialogs/profile_customization_dialog.dart';
import 'package:secret_sorcerer/widgets/info_row.dart';
import 'package:secret_sorcerer/widgets/buttons/pill_button.dart';
import 'package:secret_sorcerer/controllers/user_auth.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  AppUser? _user;
  String _hatColor = 'hatDefault';
  final FirebaseController firebaseController = FirebaseController();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userAuth = UserAuth();
    final AppUser? currentUser = await userAuth.getCurrentUser();
    if (!mounted) return;
    setState(() {
      _user = currentUser;
      _hatColor = currentUser?.hatColor ?? 'hatDefault';
    });
  }

  Future<void> _openProfileCustomization() async {
    final result = await showDialog<ProfileCustomizationResult>(
      context: context,
      builder: (_) => ProfileCustomizationDialog(
        currentHatColor: _hatColor,
        onChangeProfilePicture: _editProfilePicture,
      ),
    );

    if (result != null && mounted) {
      if (result.hatColor != _hatColor) {
        await firebaseController.editHat(
          FirebaseAuth.instance.currentUser!.uid,
          result.hatColor,
        );
      }
      await _loadUser();
    }
  }

  Future<void> _editProfilePicture() async {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.primaryBrand,
        titleTextStyle: TextStyles.title,
        title: const Text('Edit Profile Picture'),
        content: Text(
          'Profile picture editing will be available soon.',
          style: TextStyles.body.copyWith(
            color: Colors.white.withOpacity(0.85),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK', style: TextStyle(color: Colors.white70)),
          ),
        ],
      ),
    );
  }

  Future<void> _editNickname() async {
    await showDialog<void>(
      context: context,
      builder: (_) => EditNicknameDialog(
        initial: _user?.nickname ?? '',
        save: (nickname) async {
          await UserAuth.updateNickname(nickname);
          await _loadUser();
          return null;
        },
      ),
    );
  }

  Future<void> _editUsername() async {
    await showDialog<void>(
      context: context,
      builder: (_) => EditUsernameDialog(
        initial: _user?.username ?? '',
        save: (username) async {
          await UserAuth().changeUsername(
            newUsername: username,
            oldUsername: _user?.username ?? '',
          );
          await _loadUser();
          return null;
        },
      ),
    );
  }

  Future<void> _editPassword() async {
    await showDialog<void>(
      context: context,
      builder: (_) => EditPasswordDialog(
        verifyCurrent: (currentPassword) async {
          return true; // temporary success
        },
        changePassword: (newPassword) async {
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nickname = _user?.nickname ?? '';
    final username = '@${_user?.username ?? ''}';
    final email = _user?.email ?? '';

    return Scaffold(
      backgroundColor: AppColors.secondaryBG,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryBG,
        centerTitle: true,
        leading: const BackNavButtonSound(icon: Icons.arrow_back),
        title: const Text('Edit Profile', style: TextStyles.subheading),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: AppSpacing.screen,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 40),

                // Avatar + hat + single "Edit" button
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        // Avatar
                        const Align(
                          alignment: Alignment.center,
                          child: CircleAvatar(
                            radius: AppSpacing.avatarMedium,
                            backgroundColor: AppColors.secondaryBrand,
                            child: Icon(
                              Icons.person,
                              size: AppSpacing.avatarMedium,
                              color: Colors.white,
                            ),
                          ),
                        ),

                        // Bigger hat overlay
                        Align(
                          alignment: Alignment.center,
                          child: Transform.translate(
                            offset: const Offset(0, -66),
                            child: Image.asset(
                              'assets/images/hats/$_hatColor.png',
                              height: AppSpacing.hatHeightLarge,
                              width: AppSpacing.hatWidthLarge,
                            ),
                          ),
                        ),

                        // Edit button at top-right of avatar, overlapping
                        Align(
                          alignment: Alignment.centerRight,
                          child: Transform.translate(
                            // shift left a bit and up by ~avatar radius
                            offset: Offset(-8, -AppSpacing.avatarMedium * 0.8),
                            child: PillButton.small(
                              label: 'Edit',
                              onPressed: _openProfileCustomization,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                AppSpacing.gapXXL,

                InfoRow(title: 'Email', value: email),

                AppSpacing.gapXL,

                InfoRow(
                  title: 'Nickname',
                  value: nickname,
                  onPress: _editNickname,
                ),

                AppSpacing.gapXL,

                InfoRow(
                  title: 'Username',
                  value: username,
                  onPress: _editUsername,
                ),

                AppSpacing.gapXL,

                InfoRow(
                  title: 'Password',
                  value: '••••••••',
                  onPress: _editPassword,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
