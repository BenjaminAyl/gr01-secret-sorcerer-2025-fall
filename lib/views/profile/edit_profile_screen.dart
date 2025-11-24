import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/models/user_model.dart';
import 'package:secret_sorcerer/widgets/account/edit_nickname.dart';
import 'package:secret_sorcerer/widgets/account/edit_password.dart';
import 'package:secret_sorcerer/widgets/account/edit_username.dart';
import 'package:secret_sorcerer/widgets/buttons/back_nav_button.dart';
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

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final userAuth = UserAuth();
    final AppUser? currentUser = await userAuth.getCurrentUser();
    // TODO: update userAuth to use firestore to store current user
    if (!mounted) return;
    setState(() => _user = currentUser);
  }

  Future<void> _editNickname() async {
    await showDialog<void>(
      context: context,
      builder: (_) => EditNicknameDialog(
        initial: _user?.nickname ?? '',
        save: (nickname) async {
          // TODO: Implement nickname update logic later
          return null; // returning null means "no error" for now
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
          // TODO: Implement username update logic later
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
          // TODO: Implement password verification later
          return true; // temporary success
        },
        changePassword: (newPassword) async {
          // TODO: Implement password change logic later
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
        leading: BackNavButtonSound(icon: Icons.arrow_back),
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
                            // TODO: push avatar editor route
                            // context.push('/profile/avatar');
                          },
                        ),
                      ),
                    ],
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
