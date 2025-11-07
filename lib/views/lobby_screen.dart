// lib/views/lobby_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:secret_sorcerer/controllers/firebase.dart';
import 'package:secret_sorcerer/controllers/lobby_controller.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/constants/app_spacing.dart';
import 'package:secret_sorcerer/widgets/buttons/primary_button.dart';

class LobbyScreen extends StatefulWidget {
  final String code;
  const LobbyScreen({super.key, required this.code});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _firebase = FirebaseController();
  final _lobbyController = LobbyController();
  late String playerId;
  bool _attemptedAutoJoin = false;

  @override
  void initState() {
    super.initState();
    _initLobby();
  }

  Future<void> _initLobby() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No signed-in user found.');
    playerId = user.uid;
    await _lobbyController.init(widget.code);
  }

  Future<void> _leave(Map<String, dynamic> data) async {
    final isHost = data['creatorId'] == playerId;
    if (isHost) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        await _lobbyController.leaveLobby(data);
        if (mounted) context.go('/home');
      });
    } else {
      await _lobbyController.leaveLobby(data);
      if (mounted) context.go('/home');
    }
  }

  //Host starts the game
  Future<void> _start(List<String> ids) async {
    await _lobbyController.startGame(ids);
    if (mounted) context.go('/game/${widget.code}');
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: _firebase.watchLobby(widget.code),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        //lobby fallback
        if (!snap.data!.exists) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/home');
          });
          return const SizedBox.shrink();
        }

        final data = snap.data!.data()!;
        final status = data['status'] ?? 'waiting';
        final creatorId = data['creatorId'] as String;
        final ids = List<String>.from((data['players'] ?? []).cast<String>());
        final nicknames = Map<String, dynamic>.from(data['nicknames'] ?? {});
        final isHost = creatorId == playerId;
        final canStart = ids.length > 1;

        //join if somehow not in players list
        if (!_attemptedAutoJoin && !ids.contains(playerId)) {
          _attemptedAutoJoin = true;
          _firebase.joinLobby(widget.code, playerId);
        }

        //kick everyone out of my lobby
        if (status == 'closing') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/home');
          });
        }

        //move to game screen
        if (status == 'playing') {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/game/${widget.code}');
          });
        }

        //ALL UI
        final hostName = nicknames[creatorId] ?? 'Host';
        final otherPlayers = ids.where((id) => id != creatorId).toList();

        return Scaffold(
          backgroundColor: AppColors.primaryBrand,
          appBar: AppBar(
            backgroundColor: AppColors.primaryBrand,
            elevation: 0,
            centerTitle: true,
            title: const Text('Lobby', style: TextStyles.subheading),
            leading: IconButton(
              icon: const Icon(
                Icons.cancel,
                color: AppColors.customAccent,
                size: AppSpacing.iconSizeLarge,
              ),
              onPressed: () => _leave(data),
            ),
          ),
          body: SafeArea(
            child: Padding(
              padding: AppSpacing.screen,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  //Lobby Code Banner
                  Text(
                    'Lobby Code:',
                    style: TextStyles.subheading.copyWith(
                      color: AppColors.textAccent,
                      fontWeight: FontWeight.w700,
                      fontSize: 26,
                    ),
                  ),
                  AppSpacing.gapS,
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 20,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryBrand,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusL),
                    ),
                    child: Text(
                      widget.code,
                      style: TextStyles.title.copyWith(
                        fontSize: 36,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textAccent,
                        letterSpacing: 2,
                      ),
                    ),
                  ),
                  AppSpacing.gapL,

                  //Host section
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'HOST:',
                      style: TextStyles.bodyLarge.copyWith(
                        color: AppColors.textAccent,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  AppSpacing.gapS,
                  Column(
                    children: [
                      Image.asset(
                        'assets/images/wizard_hat.png',
                        width: 80,
                        height: 80,
                        fit: BoxFit.contain,
                      ),
                      AppSpacing.gapXS,
                      Text(
                        hostName,
                        style: TextStyles.body.copyWith(
                          color: AppColors.textAccent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  AppSpacing.gapL,

                  //Player list below host
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        children: [
                          if (otherPlayers.isNotEmpty)
                            Wrap(
                              spacing: 16,
                              runSpacing: 16,
                              alignment: WrapAlignment.center,
                              children: otherPlayers.map((uid) {
                                final name = nicknames[uid] ?? 'Unknown';
                                return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Image.asset(
                                      'assets/images/wizard_hat.png',
                                      width: 70,
                                      height: 70,
                                      fit: BoxFit.contain,
                                    ),
                                    AppSpacing.gapXS,
                                    Text(
                                      name,
                                      style: TextStyles.bodySmall.copyWith(
                                        color: AppColors.textAccent,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList(),
                            )
                          else
                            Text(
                              'Waiting for players...',
                              style: TextStyles.body.copyWith(
                                color: Colors.white70,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          AppSpacing.spaceL,

                          //Start button (host only)
                          if (isHost)
                            SizedBox(
                              width: 220,
                              height: AppSpacing.buttonHeightMedium,
                              child: Opacity(
                                opacity: canStart ? 1 : 0.6,
                                child: IgnorePointer(
                                  ignoring: !canStart,
                                  child: PrimaryButton(
                                    label: 'Start Game',
                                    onPressed: () => _start(ids),
                                  ),
                                ),
                              ),
                            )
                          else
                            Text(
                              'Waiting for host to start...',
                              style: TextStyles.body.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
