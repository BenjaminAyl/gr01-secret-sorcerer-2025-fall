import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/controllers/firebase.dart';
import 'package:secret_sorcerer/controllers/user_auth.dart';
import 'package:secret_sorcerer/models/user_model.dart';
import 'package:secret_sorcerer/utils/current_style.dart';
import 'package:secret_sorcerer/widgets/account/edit_nickname.dart';
import 'package:secret_sorcerer/widgets/account/edit_password.dart';
import 'package:secret_sorcerer/widgets/account/edit_username.dart';
import 'package:secret_sorcerer/widgets/avatar/avatar_display.dart';
import 'package:secret_sorcerer/widgets/buttons/back_nav_button.dart';
import 'package:secret_sorcerer/widgets/buttons/pill_button.dart';
import 'package:secret_sorcerer/widgets/dialogs/profile_customization_dialog.dart';
import 'package:secret_sorcerer/widgets/info_row.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  AppUser? _user;

  // Start with cached values (no flash)
  String _hatColor = CurrentStyle.hatColor;
  String _avatarColor = CurrentStyle.avatarColor;

  final FirebaseController firebaseController = FirebaseController();
  final userAuth = UserAuth();

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  /// Fetch full user object from Firestore
  Future<void> _loadUser() async {
    final AppUser? currentUser = await userAuth.getCurrentUser();
    if (!mounted) return;

    if (currentUser != null) {
      // Update the UI based on Firestore data
      setState(() {
        _user = currentUser;
        _hatColor = currentUser.hatColor;
        _avatarColor = currentUser.avatarColor;
      });

      // 🔥 Keep cache in sync with Firestore values
      CurrentStyle.update(
        hat: currentUser.hatColor,
        avatar: currentUser.avatarColor,
        nickname: currentUser.nickname,
        username: currentUser.username,
      );
    }
  }

  /// Avatar/Hat customization
  Future<void> _openProfileCustomization() async {
    final result = await showDialog<ProfileCustomizationResult>(
      context: context,
      builder: (_) => ProfileCustomizationDialog(
        currentHatColor: _hatColor,
        currentAvatarColor: _avatarColor,
        onChangeProfilePicture: _editProfilePicture,
      ),
    );

    if (result == null) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Update Firestore where needed
    if (result.hatColor != _hatColor) {
      await firebaseController.editHat(uid, result.hatColor);
    }

    if (result.avatarColor != _avatarColor) {
      await firebaseController.editAvatar(uid, result.avatarColor);
    }

    // Update local UI instantly
    setState(() {
      _hatColor = result.hatColor;
      _avatarColor = result.avatarColor;
    });

    // 🔥 Update global cached style
    CurrentStyle.update(hat: result.hatColor, avatar: result.avatarColor);

    // Refresh nickname/username/email from Firestore
    await _loadUser();
  }

  /// Temporary profile picture edit
  Future<void> _editProfilePicture() async {
    showDialog(
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
            onPressed: () => Navigator.pop(context),
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

          // 🔥 Update cache
          CurrentStyle.updateNickname(nickname);

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

          // 🔥 Update cache
          CurrentStyle.updateUsername(username);

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
        verifyCurrent: (currentPassword) async => true,
        changePassword: (newPassword) async => null,
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

                // Avatar + hat + Edit button
                Center(
                  child: SizedBox(
                    width: 220,
                    height: 200,
                    child: Stack(
                      alignment: Alignment.center,
                      clipBehavior: Clip.none,
                      children: [
                        AvatarDisplay(
                          avatarColor: _avatarColor,
                          hatColor: _hatColor,
                          radius: AppSpacing.avatarMedium,
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: Transform.translate(
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
