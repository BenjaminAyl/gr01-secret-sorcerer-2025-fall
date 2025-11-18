import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/controllers/firebase.dart';
import 'package:secret_sorcerer/controllers/user_auth.dart';
import 'package:secret_sorcerer/models/user_model.dart';
import 'package:secret_sorcerer/views/leaderboard/leaderboard_window.dart';
import 'package:secret_sorcerer/widgets/buttons/primary_button.dart';

class LeaderboardView extends StatefulWidget {
  const LeaderboardView({super.key});

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> {

  final FirebaseController _firebaseController = FirebaseController();
  List<Map<String, dynamic>> _allUsers = [];

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await _firebaseController.loadAllUsers();
    setState(() => _allUsers = users);
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryBG,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryBG,
        leading: IconButton(
          icon: const Icon(
            Icons.cancel,
            color: AppColors.customAccent,
            size: AppSpacing.iconSizeLarge,
          ),
          onPressed: () => context.go('/home'),
        ),
        centerTitle: true,
        title: const Text('Leaderboard', style: TextStyles.heading),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: AppSpacing.screen,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppSpacing.gapXXL,
                LeaderboardWindow(
                  leaderboardData: _allUsers
                ),
                AppSpacing.gapXXL,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
