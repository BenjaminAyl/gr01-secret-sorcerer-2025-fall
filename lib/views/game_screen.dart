import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/controllers/firebase.dart';
import 'package:secret_sorcerer/views/game_view.dart';
import 'package:secret_sorcerer/utils/audio_helper.dart';
import 'package:secret_sorcerer/views/overlays/game_notification_bar.dart';
import 'package:secret_sorcerer/views/overlays/role_scroll_overlay.dart';
import 'package:secret_sorcerer/views/overlays/policy_overlay.dart';
import 'package:secret_sorcerer/views/overlays/voting_overlay.dart';
import 'package:secret_sorcerer/views/overlays/executive_overlays.dart';
import 'package:secret_sorcerer/views/overlays/turn_counter_overlay.dart';
import 'package:secret_sorcerer/views/overlays/auto_warning_overlay.dart';
import 'package:secret_sorcerer/views/overlays/game_win_overlay.dart';
import 'package:secret_sorcerer/views/overlays/deck_discard_overlay.dart';


class GameScreen extends StatefulWidget {
  final String code;
  const GameScreen({super.key, required this.code});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with TickerProviderStateMixin {
  final _firebase = FirebaseController();
  late final WizardGameView _game;
  String? _creatorId;
  String? _uid;
  bool _navigatedOut = false;

  bool _myVoteCastLocal = false;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;

    _game = WizardGameView(
      lobbyId: widget.code,
      myUid: _uid!,
    );

    AudioHelper.crossfade("TavernMusic.wav");
  }

  @override
  Widget build(BuildContext context) {
    final lobbyRef = FirebaseFirestore.instance
        .collection('lobbies')
        .doc(widget.code);

    final stateRef = FirebaseFirestore.instance
        .collection('states')
        .doc(widget.code);

    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return StreamBuilder(
      stream: lobbyRef.snapshots(),
      builder: (context, lobbySnap) {
        if (!lobbySnap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        _creatorId ??= lobbySnap.data!.data()?['creatorId'];

        return StreamBuilder(
          stream: stateRef.snapshots(),
          builder: (context, stateSnap) {
            if (!stateSnap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // If the state was deleted -> return to lobby
            if (!stateSnap.data!.exists) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!_navigatedOut) {
                  _navigatedOut = true;
                  context.go('/lobby/${widget.code}');
                }
              });
              return const SizedBox.shrink();
            }

            final rawState = stateSnap.data!.data();
            if (rawState == null) return const SizedBox.shrink();

            // Assign live state fields
            _game.phase = rawState['phase'] ?? 'start';
            _game.executivePower = rawState['executivePower'];
            _game.executiveActive = rawState['executiveActive'] == true;
            _game.executiveTarget = rawState['executiveTarget'];
            _game.pendingExecutiveCards =
                List<String>.from(rawState['pendingExecutiveCards'] ?? []);

            if (_game.phase != 'voting' &&
                _game.phase != 'voting_results') {
              _myVoteCastLocal = false;
            }

            if (_game.phase == 'auto_warning') {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!_game.overlays.isActive('auto_warning')) {
                  _game.overlays.add('auto_warning');
                }
              });
            } else {
              _game.overlays.remove('auto_warning');
            }
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_game.overlays.isActive('turn_counter')) {
                _game.overlays.add('turn_counter');
              }
            });
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (!_game.overlays.isActive('deck_discard')) {
                _game.overlays.add('deck_discard');
              }
            });
            final winnerTeam = rawState['winnerTeam'];
            final bool isGameOver =
                _game.phase == 'game_over' && winnerTeam != null;

            return Scaffold(
              backgroundColor: AppColors.primaryBrand,
              body: SafeArea(
                child: Stack(
                  children: [
                    GameWidget(
                      game: _game,
                      overlayBuilderMap: {
                        'auto_warning': (context, game) =>
                            const AutoWarningOverlay(),
                        'turn_counter': (context, game) =>
                            TurnCounterOverlay(game: game as WizardGameView),
                        'deck_discard': (context, game) =>
                            DeckDiscardOverlay(game: game as WizardGameView),

                        'ControlsOverlay': (context, game) {
                          final g = game as WizardGameView;
                          final isHM = g.isHeadmasterClient;
                          final isSC = g.isSpellcasterClient;
                          final isDead = g.dead[_uid] == true;
                          final isHost = _uid == _creatorId;

                          final showHMDiscard =
                              isHM &&
                              g.phase == 'hm_discard' &&
                              g.pendingCards.length == 3;

                          final showSCChoose =
                              isSC &&
                              g.phase == 'sc_choose' &&
                              g.pendingCards.length == 2;

                          final showVoting =
                            (!isHM && g.phase == 'voting' && !isDead) ||
                            (g.phase == 'voting_results');


                          Widget topHUD = Column(
                            children: [
                              SizedBox(height: height * 0.012),
                              Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: width * 0.05,
                                  vertical: height * 0.01,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.secondaryBrand.withOpacity(0.75),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Text(
                                  isHM
                                      ? "You are the Headmaster"
                                      : isSC
                                          ? "You are the Spellcaster"
                                          : "Waiting...",
                                  style: TextStyles.bodySmall.copyWith(
                                    fontSize: height * 0.02,
                                    color: AppColors.textAccent,
                                  ),
                                ),
                              ),
                              SizedBox(height: height * 0.005),
                              GameNotificationBar(
                                game: g,
                                isHM: isHM,
                                isSC: isSC,
                                width: width,
                                height: height,
                              ),
                            ],
                          );

                          final bool showScroll =
                              !showHMDiscard &&
                              !showSCChoose &&
                              !showVoting &&
                              g.phase != 'executive_investigate' &&
                              g.phase != 'executive_investigate_result' &&
                              g.phase != 'executive_peek3' &&
                              g.phase != 'executive_choose_hm' &&
                              g.phase != 'executive_choose_hm_result' &&
                              g.phase != 'executive_kill' &&
                              g.phase != 'executive_kill_result' &&
                              g.phase != 'executive_kill_result_arch' &&
                              !isDead &&
                              g.phase != 'auto_warning';

                          return Stack(
                            children: [
                              // Unified BACK button (host + client)
                            Positioned(
                              top: height * 0.015,
                              left: width * 0.02,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.arrow_back_ios_new,
                                  color: Colors.white,
                                ),
                                onPressed: () async {
                                  if (isHost) {
                                    // Host flow
                                    final ok = await _confirmEndGame(context);
                                    if (ok == true) {
                                      await FirebaseFirestore.instance
                                          .collection('states')
                                          .doc(widget.code)
                                          .delete();
                                      await _firebase.resetLobby(widget.code);
                                    }
                                  } else {
                                    // Client flow
                                    final ok = await _confirmLeaveGame(context);
                                    if (ok == true) {
                                      await _firebase.clientTerminateGame(widget.code);
                                    }
                                  }
                                },
                              ),
                            ),



                              Align(
                                alignment: Alignment.topCenter,
                                child: topHUD,
                              ),

                              if (showHMDiscard)
                                PolicyOverlay(
                                  game: g,
                                  height: height,
                                  width: width,
                                  isHMPhase: true,
                                ),

                              if (showSCChoose)
                                PolicyOverlay(
                                  game: g,
                                  height: height,
                                  width: width,
                                  isHMPhase: false,
                                ),

                              if (showVoting)
                                VotingOverlay(
                                  game: g,
                                  height: height,
                                  width: width,
                                  myVoteCastLocal: _myVoteCastLocal,
                                  onVote: (yes) async {
                                    if (_myVoteCastLocal ||
                                        g.iVoted) return;
                                    setState(() {
                                      _myVoteCastLocal = true;
                                    });
                                    await g.castVote(yes);
                                  },
                                ),

                              Positioned.fill(
                                child: _buildExecutiveStack(
                                  g,
                                  width,
                                  height,
                                  isHM,
                                  isHost,
                                ),
                              ),

                              if (showScroll)
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: RoleScrollOverlay(
                                    game: g,
                                    myUid: _uid!,
                                    height: height,
                                    width: width,
                                  ),
                                ),
                            ],
                          );
                        }
                      },
                    ),

                    if (isGameOver)
                      Positioned.fill(
                        child: GameWinOverlay(
                          game: _game,
                          width: width,
                          height: height,
                          isHost: _uid == _creatorId,
                          winnerTeam: winnerTeam!,
                          onHostReturn: _uid == _creatorId
                              ? () async {
                                  await FirebaseFirestore.instance
                                      .collection('states')
                                      .doc(widget.code)
                                      .delete();
                                  await _firebase.resetLobby(
                                      widget.code);
                                }
                              : null,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<bool?> _confirmEndGame(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text("End Game?",
            style: TextStyle(color: Colors.white)),
        content: const Text(
          "Send everyone back to the lobby?",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Yes, return"),
          ),
        ],
      ),
    );
  }
    Future<bool?> _confirmLeaveGame(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.black87,
        title: const Text("Leave Game?",
            style: TextStyle(color: Colors.white)),
        content: const Text(
          "Leaving will end the game for everyone.",
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("End Game"),
          ),
        ],
      ),
    );
  }


  Widget _buildExecutiveStack(
    WizardGameView g,
    double width,
    double height,
    bool isHM,
    bool isHost,
  ) {
    return Stack(
      children: [
        if (g.phase == 'executive_investigate')
          ExecutiveInvestigateOverlay(
            isHeadmaster: isHM,
            height: height,
          ),

        if (g.phase == 'executive_investigate_result')
          ExecutiveInvestigateResultOverlay(
            game: g,
            isHeadmaster: isHM,
            height: height,
            onContinue: () => _firebase.endExecutive(g.lobbyId),
          ),

        if (g.phase == 'executive_peek3')
          ExecutivePeek3Overlay(
            game: g,
            isHeadmaster: isHM,
            height: height,
            width: width,
            onContinue: () => _firebase.endExecutive(g.lobbyId),
          ),

        if (g.phase == 'executive_choose_hm')
          ExecutiveChooseHeadmasterOverlay(
            isHeadmaster: isHM,
            height: height,
          ),

        if (g.phase == 'executive_choose_hm_result')
          ExecutiveChooseHeadmasterResultOverlay(
            game: g,
            isHeadmaster: isHM,
            height: height,
            onConfirm: () =>
                _firebase.confirmNextHeadmaster(g.lobbyId),
          ),

        if (g.phase == 'executive_kill')
          ExecutiveKillOverlay(
            isHeadmaster: isHM,
            height: height,
          ),

        if (g.phase == 'executive_kill_result' ||
            g.phase == 'executive_kill_result_arch')
          ExecutiveKillResultOverlay(
            game: g,
            height: height,
            width: width,
            isArch: g.phase ==
                'executive_kill_result_arch',
            isHost: isHost,
            onContinue: isHost
                ? () async {
                    if (g.phase ==
                        'executive_kill_result_arch') {
                      await _firebase.setGameOver(
                        lobbyId: g.lobbyId,
                        winningTeam: "order",
                      );
                      return;
                    }

                    await _firebase.finalizeKill(
                        g.lobbyId);
                  }
                : null,
          ),
      ],
    );
  }
}
