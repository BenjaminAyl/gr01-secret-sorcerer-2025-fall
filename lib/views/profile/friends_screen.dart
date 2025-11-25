import 'package:flutter/material.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:secret_sorcerer/models/user_model.dart';
import 'package:secret_sorcerer/widgets/buttons/back_nav_button.dart';
import 'package:secret_sorcerer/widgets/friends/friends_switch.dart';
import 'package:secret_sorcerer/widgets/friends/friends_list.dart';
import 'package:secret_sorcerer/widgets/friends/friend_requests_list.dart';
import 'package:secret_sorcerer/controllers/friends_controller.dart';
import 'package:secret_sorcerer/controllers/firebase.dart';
import 'package:secret_sorcerer/utils/audio_helper.dart';
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
  Map<String, String?> _friendLobbyMap = {};
  String _lastFriendIds = '';
  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>> _friendSubscriptions = {};
  final Map<String, StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>> _lobbySubscriptions = {};

  @override
  void dispose() {
    // cancel any friend document subscriptions
    for (final sub in _friendSubscriptions.values) {
      sub.cancel();
    }
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

                    // Update subscriptions so we track each friend's currentLobby in realtime.
                    final ids = friends.map((f) => f.uid).join(',');
                    if (ids != _lastFriendIds) {
                      _lastFriendIds = ids;
                      _updateFriendSubscriptions(friends);
                    }
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
                      friendLobbyMap: _friendLobbyMap,
                      onJoin: (AppUser friend) async {
                        final fb = FirebaseController();
                        final me = fb.currentUser;
                        if (me == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please sign in first')),
                          );
                          return;
                        }

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Checking friend lobby...')),
                        );

                        final lobbyId = await fb.getUserCurrentLobby(friend.uid);
                        if (lobbyId == null || lobbyId.trim().isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Friend is not hosting a lobby')),
                          );
                          return;
                        }

                        try {
                          // Verify lobby document exists before attempting join
                          final lobbyDoc = await FirebaseFirestore.instance.collection('lobbies').doc(lobbyId).get();
                          if (!lobbyDoc.exists) {
                            // Lobby no longer exists — clear the local map so UI updates immediately
                            if (mounted) setState(() => _friendLobbyMap[friend.uid] = null);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Lobby no longer exists')),
                            );
                            return;
                          }

                          await fb.joinLobby(lobbyId, me.uid);
                          if (context.mounted) {
                            AudioHelper.playSFX('hostJoin.wav');
                            context.go('/lobby/$lobbyId');
                          }
                        } catch (e) {
                          // Provide clearer message for missing document update
                          final msg = e.toString().contains('No document to update')
                              ? 'Lobby no longer exists or was closed'
                              : 'Failed to join lobby: $e';
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(msg)),
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

  void _updateFriendSubscriptions(List<AppUser> friends) {
    final fb = FirebaseFirestore.instance;

    final newIds = friends.map((f) => f.uid).toSet();

    // Cancel subscriptions for removed friends
    final removed = _friendSubscriptions.keys.where((k) => !newIds.contains(k)).toList();
    for (final id in removed) {
      _friendSubscriptions[id]?.cancel();
      _friendSubscriptions.remove(id);
      // also cancel any lobby subscription for this friend
      _lobbySubscriptions[id]?.cancel();
      _lobbySubscriptions.remove(id);
      _friendLobbyMap.remove(id);
    }

    // Add subscriptions for new friends
    for (final f in friends) {
      if (_friendSubscriptions.containsKey(f.uid)) continue;
      final sub = fb.collection('users').doc(f.uid).snapshots().listen((doc) {
        final data = doc.data() ?? {};
        final lobby = data['currentLobby'];
        final lobbyStr = lobby == null ? null : lobby.toString();

        // Update friendLobbyMap
        if (mounted) {
          setState(() {
            _friendLobbyMap[f.uid] = lobbyStr;
          });
        }

        // Manage lobby doc subscription for this friend's currentLobby
        try {
          final existingLobbySub = _lobbySubscriptions[f.uid];
          // if friend has a lobby, ensure we subscribe to that lobby doc to detect deletion
          if (lobbyStr != null && lobbyStr.trim().isNotEmpty) {
            // If there is an existing lobby sub for a different lobbyId, cancel it
            existingLobbySub?.cancel();
            _lobbySubscriptions.remove(f.uid);

            final lobbySub = fb.collection('lobbies').doc(lobbyStr).snapshots().listen((lDoc) {
              // If lobby doc no longer exists, clear the friend's lobby entry so UI updates
              if (!lDoc.exists) {
                if (mounted) {
                  setState(() {
                    _friendLobbyMap[f.uid] = null;
                  });
                }
                // cancel this lobby subscription
                try {
                  _lobbySubscriptions[f.uid]?.cancel();
                } catch (_) {}
                try {
                  _lobbySubscriptions.remove(f.uid);
                } catch (_) {}
              }
            }, onError: (_) {});
            _lobbySubscriptions[f.uid] = lobbySub;
          } else {
            // No lobby currently — cancel any existing lobby sub
            existingLobbySub?.cancel();
            _lobbySubscriptions.remove(f.uid);
          }
        } catch (e) {
          // Defensive fallback: if _lobbySubscriptions is unexpectedly undefined at runtime,
          // ignore lobby subscription management to avoid crashing the app.
        }
      }, onError: (_) {});
      _friendSubscriptions[f.uid] = sub;
    }
  }

}
