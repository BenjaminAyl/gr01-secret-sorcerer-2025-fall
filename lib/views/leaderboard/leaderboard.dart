import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/controllers/firebase.dart';
import 'package:secret_sorcerer/controllers/friends_controller.dart';
import 'package:secret_sorcerer/models/user_model.dart';
import 'package:secret_sorcerer/views/leaderboard/leaderboard_window.dart';
import 'package:secret_sorcerer/widgets/buttons/back_nav_button.dart';

class LeaderboardView extends StatefulWidget {
  const LeaderboardView({super.key});

  @override
  State<LeaderboardView> createState() => _LeaderboardViewState();
}

class _LeaderboardViewState extends State<LeaderboardView> {
  final FirebaseController _firebaseController = FirebaseController();
  final FriendsController _friendsController = FriendsController();
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
        leading: BackNavButtonSound(icon: Icons.cancel),
        centerTitle: true,
        title: const Text('Leaderboard', style: TextStyles.heading),
      ),
      body: SafeArea(
        child: Align(
          alignment: Alignment.topCenter,
          child: Padding(
            padding: AppSpacing.screen,
            child: DefaultTabController(
              length: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSpacing.gapM,
                  Container(
                    constraints: const BoxConstraints(maxWidth: AppSpacing.cardWidthLarge),
                    child: TabBar(
                        labelColor: AppColors.customAccent,
                        unselectedLabelColor: AppColors.textAccentSecondary,
                        // Use the same font as leaderboard player names for exact match
                        labelStyle: TextStyles.bookSectionHeading.copyWith(color: AppColors.customAccent),
                        unselectedLabelStyle: TextStyles.bookSectionHeading.copyWith(color: AppColors.textAccentSecondary),
                        indicatorColor: AppColors.customAccent,
                      tabs: [
                        Tab(child: Text('Global')),
                        Tab(child: Text('Friends')),
                      ],
                    ),
                  ),
                  AppSpacing.gapL,
                  SizedBox(
                    height: AppSpacing.buttonHeightLarge * 6,
                    width: AppSpacing.cardWidthLarge,
                    child: TabBarView(
                      children: [
                        // Global leaderboard (uses already loaded _allUsers)
                        LeaderboardWindow(leaderboardData: _allUsers),

                        // Friends leaderboard: build from friends stream and existing _allUsers
                        StreamBuilder<List<AppUser>>(
                          stream: _friendsController.watchFriends(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            final friends = snapshot.data ?? [];

                            // If we have global users loaded, filter them by friend uids to show wins/losses
                            if (_allUsers.isNotEmpty) {
                              final friendIds = friends.map((f) => f.uid).toSet();
                              final filtered = _allUsers.where((u) => friendIds.contains(u['id'] ?? u['uid'] ?? '')).toList();
                              // If some friends weren't present in _allUsers, add basic fallbacks
                              final presentIds = filtered.map((e) => e['id'] ?? e['uid'] ?? '').toSet();
                              for (final f in friends) {
                                if (!presentIds.contains(f.uid)) {
                                  filtered.add({
                                    'id': f.uid,
                                        'Nickname': (f.nickname.isNotEmpty ? f.nickname : (f.username.isNotEmpty ? f.username : 'Unknown')),
                                    'wins': 0,
                                    'losses': 0,
                                  });
                                }
                              }
                              return LeaderboardWindow(leaderboardData: filtered);
                            }

                            // Fallback: no global data yet — show minimal friend entries
                            final fallback = friends.map((f) => {
                              'id': f.uid,
                                  'Nickname': (f.nickname.isNotEmpty ? f.nickname : (f.username.isNotEmpty ? f.username : 'Unknown')),
                              'wins': 0,
                              'losses': 0,
                            }).toList();
                            if (fallback.isEmpty) {
                              return Center(
                                child: Text('No friends to show', style: TextStyles.body),
                              );
                            }
                            return LeaderboardWindow(leaderboardData: fallback);
                          },
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapXXL,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
