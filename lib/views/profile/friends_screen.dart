import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/models/user_model.dart';
import 'package:secret_sorcerer/widgets/buttons/back_nav_button.dart';
import 'package:secret_sorcerer/widgets/friends/friends_switch.dart';
import 'package:secret_sorcerer/widgets/friends/friends_list.dart';
import 'package:secret_sorcerer/widgets/friends/friend_requests_list.dart';
import 'package:secret_sorcerer/controllers/friends_controller.dart';
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
  final FriendsController _controller = FriendsController();

  // Streams for friends and incoming requests
  Stream<List<AppUser>>? _friendsStream;
  Stream<List<AppUser>>? _requestsStream;

  @override
  void dispose() {
    _usernameCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _friendsStream = _controller.watchFriends();
    _requestsStream = _controller.watchIncomingRequests();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondaryBG,
      appBar: AppBar(
        backgroundColor: AppColors.secondaryBG,
        centerTitle: true,
        leading: BackNavButtonSound(icon: Icons.arrow_back),
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
                    onPressed: () async {
                      final username = _usernameCtrl.text.trim();
                      try {
                        await _controller.sendFriendRequestToUsername(username);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Friend request sent')),
                        );
                        _usernameCtrl.clear();
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString())),
                        );
                      }
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
                // Friends stream
                StreamBuilder<List<AppUser>>(
                  stream: _friendsStream,
                  builder: (context, snapshot) {
                    final friends = snapshot.data ?? [];
                    return FriendsList(
                      friends: friends,
                      onRemove: (AppUser friend) async {
                        try {
                          await _controller.removeFriend(friend.uid);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Friend removed')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                    );
                  },
                )
              else
                // Incoming friend requests stream
                StreamBuilder<List<AppUser>>(
                  stream: _requestsStream,
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Center(
                          child: Text('Error loading requests: ${snapshot.error}'),
                        ),
                      );
                    }

                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final requests = snapshot.data ?? [];
                    return FriendRequestsList(
                      requests: requests,
                      onAccept: (AppUser friendRequest) async {
                        try {
                          await _controller.acceptFriendRequest(fromUid: friendRequest.uid);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Friend added')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                      onDecline: (AppUser friendRequest) async {
                        try {
                          await _controller.declineFriendRequest(fromUid: friendRequest.uid);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Request declined')),
                          );
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(e.toString())),
                          );
                        }
                      },
                    );
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }
}
