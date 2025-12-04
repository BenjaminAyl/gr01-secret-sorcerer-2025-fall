import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/controllers/firebase.dart';
import 'package:secret_sorcerer/controllers/friends_controller.dart';
import 'package:secret_sorcerer/controllers/user_auth.dart';
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
  final UserAuth _userAuth = UserAuth();

  List<Map<String, dynamic>> _allUsers = [];
  AppUser? _currentUser;

  @override
  void initState() {
    super.initState();
    _loadUsersAndCurrentUser();
  }

  Future<void> _loadUsersAndCurrentUser() async {
    // Make sure loadAllUsers returns avatarColor & hatColor per user
    final users = await _firebaseController.loadAllUsers();
    final current = await _userAuth.getCurrentUser();

    if (!mounted) return;
    setState(() {
      _allUsers = users;
      _currentUser = current;
    });
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
                    constraints: const BoxConstraints(
                      maxWidth: AppSpacing.cardWidthLarge,
                    ),
                    child: TabBar(
                      labelColor: AppColors.customAccent,
                      unselectedLabelColor: AppColors.textAccentSecondary,
                      labelStyle: TextStyles.bookSectionHeading.copyWith(
                        color: AppColors.customAccent,
                      ),
                      unselectedLabelStyle: TextStyles.bookSectionHeading
                          .copyWith(color: AppColors.textAccentSecondary),
                      indicatorColor: AppColors.customAccent,
                      tabs: const [
                        Tab(child: Text('Global')),
                        Tab(child: Text('Friends')),
                      ],
                    ),
                  ),
                  AppSpacing.gapL,
                  SizedBox(
                    height: AppSpacing.buttonHeightLarge * 7.5,
                    width: AppSpacing.cardWidthLarge,
                    child: TabBarView(
                      children: [
                        // GLOBAL leaderboard
                        LeaderboardWindow(leaderboardData: _allUsers),

                        // FRIENDS leaderboard
                        StreamBuilder<List<AppUser>>(
                          stream: _friendsController.watchFriends(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                    ConnectionState.waiting &&
                                _allUsers.isEmpty) {
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }

                            // Copy so we can safely mutate
                            final friends = [...(snapshot.data ?? [])];

                            // Inject current user at the top if not already in list
                            if (_currentUser != null &&
                                !friends.any(
                                  (f) => f.uid == _currentUser!.uid,
                                )) {
                              friends.insert(0, _currentUser!);
                            }

                            if (_allUsers.isNotEmpty) {
                              final friendIds = friends
                                  .map((f) => f.uid)
                                  .toSet();

                              // Users that are both in global list and friend list
                              final filtered = _allUsers
                                  .where(
                                    (u) => friendIds.contains(
                                      u['id'] ?? u['uid'] ?? '',
                                    ),
                                  )
                                  .toList();

                              // Add any missing friends with default stats/style
                              final presentIds = filtered
                                  .map((e) => e['id'] ?? e['uid'] ?? '')
                                  .toSet();

                              for (final f in friends) {
                                if (!presentIds.contains(f.uid)) {
                                  filtered.add({
                                    'id': f.uid,
                                    'Nickname': f.nickname.isNotEmpty
                                        ? f.nickname
                                        : (f.username.isNotEmpty
                                              ? f.username
                                              : 'Unknown'),
                                    'wins': 0,
                                    'losses': 0,
                                    'avatarColor': f.avatarColor,
                                    'hatColor': f.hatColor,
                                  });
                                }
                              }

                              return LeaderboardWindow(
                                leaderboardData: filtered,
                              );
                            }

                            // Fallback when global data hasn't loaded yet
                            final fallback = friends.map((f) {
                              return {
                                'id': f.uid,
                                'Nickname': f.nickname.isNotEmpty
                                    ? f.nickname
                                    : (f.username.isNotEmpty
                                          ? f.username
                                          : 'Unknown'),
                                'wins': 0,
                                'losses': 0,
                                'avatarColor': f.avatarColor,
                                'hatColor': f.hatColor,
                              };
                            }).toList();

                            if (fallback.isEmpty) {
                              return Center(
                                child: Text(
                                  'No friends to show',
                                  style: TextStyles.body,
                                ),
                              );
                            }

                            return LeaderboardWindow(leaderboardData: fallback);
                          },
                        ),
                      ],
                    ),
                  ),
                  AppSpacing.gapL,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
