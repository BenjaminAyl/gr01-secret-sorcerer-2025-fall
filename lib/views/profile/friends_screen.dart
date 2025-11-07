import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/models/user_model.dart';
import 'package:secret_sorcerer/widgets/friends/friends_switch.dart';
import 'package:secret_sorcerer/widgets/friends/friends_list.dart';
import 'package:secret_sorcerer/widgets/friends/friend_requests_list.dart';
import 'package:secret_sorcerer/widgets/buttons/pill_button.dart';

class ManageFriendsScreen extends StatefulWidget {
  const ManageFriendsScreen({super.key});

  @override
  State<ManageFriendsScreen> createState() => _ManageFriendsScreenState();
}

enum FriendTab { friends, requests }

class _ManageFriendsScreenState extends State<ManageFriendsScreen> {
  final _usernameCtrl = TextEditingController();
  FriendTab _currentTab = FriendTab.friends;

  // Mock data — TODO: replace with actual lists of friends and friend requests
final List<AppUser> _friends = [
  AppUser(uid: '1', username: 'marco', nickname: 'Marco', email: 'marco@example.com'),
  AppUser(uid: '2',username: 'ben', nickname: 'Ben', email: 'ben@example.com'),
  AppUser(uid: '3',username: 'bella', nickname: 'Bella', email: 'bella@example.com'),
  AppUser(uid: '4',username: 'liam', nickname: 'Liam', email: 'liam@example.com'),
  AppUser(uid: '5',username: 'pranjal', nickname: 'Pranjal', email: 'pranjal@example.com'),
];

final List<AppUser> _requests = [
  AppUser(uid: '6',username: 'ava', nickname: 'Ava', email: 'ava@example.com'),
  AppUser(uid: '7',username: 'ethan', nickname: 'Ethan', email: 'ethan@example.com'),
];

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryBG,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryBG,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back,
            color: AppColors.customAccent,
            size: AppSpacing.iconSizeLarge,
          ),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ),
        title: const Text('Manage Friends', style: TextStyles.subheading),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: AppSpacing.screen,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Add Friend ---
              Text(
                'Add Friend',
                style: TextStyles.bodyLarge,
              ),
              AppSpacing.gapS,
              TextField(
                controller: _usernameCtrl,
                style: const TextStyle(color: AppColors.secondaryBrand),
                decoration: InputDecoration(
                  hintText: 'Username',
                  hintStyle: const TextStyle(color: AppColors.customAccent),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: AppSpacing.item,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusM),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              AppSpacing.gapM,
              Center(
                child: SizedBox(
                  width: AppSpacing.cardWidthNarrow,
                  child: PillButton.small(
                    label: 'Send Friend Request',
                    onPressed: () {
                      // TODO: send friend request _usernameCtrl
                      
                      // TODO: on successfully sent freiend request show "sent" message, maybe make a noise?
                    },
                  ),
                ),
              ),

              AppSpacing.gapXXL,

              // --- Switch (acts like tabs) ---
              Center(
                child: FriendsSwitch(
                  value: _currentTab,
                  onChanged: (tab) => setState(() => _currentTab = tab),
                  friendsLabel: 'Friends',
                  requestsLabel: 'Requests',
                ),
              ),

              AppSpacing.gapL,

              // --- Content area that switches ---
              if (_currentTab == FriendTab.friends)
                FriendsList(
                  friends: _friends,
                  onRemove: (AppUser friend) {
                    // TODO: remove friend
                  },
                )
              else
                FriendRequestsList(
                  requests: _requests,
                  onAccept: (AppUser friendRequest) {
                    // TODO: accept request
                  },
                  onDecline: (AppUser friendRequest) {
                    // TODO: decline request
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
