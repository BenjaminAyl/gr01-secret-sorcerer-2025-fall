import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/controllers/firebase.dart';
import 'package:secret_sorcerer/models/hats.dart';
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
    // TODO: update userAuth to use firestore to store current user
    if (!mounted) return;
    setState(() {
      _user = currentUser;
      _hatColor = currentUser?.hatColor ?? 'hatDefault';
      }
    );
  }

  Future<void> _editHat() async {
    showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        titleTextStyle: TextStyles.title,
        backgroundColor: AppColors.primaryBrand,
        title: const Text("Choose Hat Color"),
        content: SizedBox(
          width: double.minPositive,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            shrinkWrap: true,
            itemCount: HatColors.values.length,
            itemBuilder: (_, index) {
              final color = HatColors.values[index];
              return ListTile(
                title: Image.asset('assets/images/hats/${hatColorToString(color)}.png',
                  height: 50,
                  width: 50,
                ),
                onTap: () async {
                  await firebaseController.editHat(FirebaseAuth.instance.currentUser!.uid, hatColorToString(color));
                  await _loadUser();
                  Navigator.of(context).pop();
                  },
              );
            },
          ),
        ),
      );
    },
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
                        right: 40,
                        top: -26,
                        child: Image.asset('assets/images/hats/${_hatColor}.png',
                          height: 50,
                          width: 50,
                          ),

                      ),
                      Positioned(
                        right: -18,
                        top: -10,
                        child: PillButton.small(
                          label: 'Edit',
                          onPressed: () async {
                            await _editHat();
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
