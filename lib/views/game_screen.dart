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

// NEW OVERLAY IMPORTS
import 'package:secret_sorcerer/views/overlays/policy_overlay.dart';
import 'package:secret_sorcerer/views/overlays/voting_overlay.dart';
import 'package:secret_sorcerer/views/overlays/executive_overlays.dart';

class GameScreen extends StatefulWidget {
  final String code;
  const GameScreen({super.key, required this.code});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with TickerProviderStateMixin {
  final _firebase = FirebaseController();
  late final WizardGameView _game;
  String? _creatorId;
  String? _uid;
  bool _navigatedOut = false;

  // local “I clicked” flag so the UI confirms instantly
  bool _myVoteCastLocal = false;

  @override
  void initState() {
    super.initState();

    _uid = FirebaseAuth.instance.currentUser?.uid;
    final myUid = _uid ?? "unknown";
    _game = WizardGameView(lobbyId: widget.code, myUid: myUid);

    // Switch from lobby music to game music
    AudioHelper.crossfade('TavernMusic.wav');
  }

  @override
  Widget build(BuildContext context) {
    final lobbyRef =
        FirebaseFirestore.instance.collection('lobbies').doc(widget.code);
    final stateRef =
        FirebaseFirestore.instance.collection('states').doc(widget.code);

    final size = MediaQuery.of(context).size;
    final width = size.width;
    final height = size.height;

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: lobbyRef.snapshots(),
      builder: (context, lobbySnap) {
        if (!lobbySnap.hasData || lobbySnap.hasError) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final lobbyData = lobbySnap.data?.data();
        if (lobbyData == null) return const SizedBox.shrink();

        final lobby = lobbySnap.data!.data()!;
        _creatorId ??= lobby['creatorId'] as String?;

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: stateRef.snapshots(),
          builder: (context, stateSnap) {
            if (!stateSnap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            // If state doc was deleted then go return to lobby
            if (!stateSnap.data!.exists) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted && !_navigatedOut) {
                  _navigatedOut = true;
                  context.go('/lobby/${widget.code}');
                }
              });
              return const SizedBox.shrink();
            }

            final rawState = stateSnap.data!.data();
            if (rawState == null) {
              return const SizedBox.shrink();
            }

            // Safety: sometimes phase might not be set yet
            final phase = rawState['phase'] ?? 'start';
            _game.phase = phase;
            _game.executivePower = rawState['executivePower'];
            _game.executiveActive = rawState['executiveActive'] == true;
            _game.executiveTarget = rawState['executiveTarget'];
            _game.pendingExecutiveCards =
                List<String>.from(rawState['pendingExecutiveCards'] ?? []);

            // Reset optimistic flag when voting ends
            if (phase != 'voting' &&
                phase != 'voting_results' &&
                _myVoteCastLocal) {
              _myVoteCastLocal = false;
            }

            return Scaffold(
              backgroundColor: AppColors.primaryBrand,
              body: SafeArea(
                child: Stack(
                  children: [
                    GameWidget(
                      game: _game,
                      overlayBuilderMap: {
                        'ControlsOverlay': (context, game) {
                          final g = game as WizardGameView;
                          final isHM = g.isHeadmasterClient;
                          final isSC = g.isSpellcasterClient;

                          final clientUid = _uid ?? '';
                          final isDeadClient = g.dead[clientUid] == true;
                          final isHost = _uid == _creatorId;

                          final showHMDiscard =
                              isHM && g.phase == 'hm_discard' && g.pendingCards.length == 3;

                          final showSCChoose =
                              isSC && g.phase == 'sc_choose' && g.pendingCards.length == 2;

                          //Dead players do NOT see the vote screen, but DO see results
                          final showVoting =
                              (g.phase == 'voting' && !isHM && !isDeadClient) ||
                              (g.phase == 'voting_results' && !isHM);

                          // Executive power text + upcoming warning
                          final String? nextExecHint = _nextExecutiveWarning(g);
                          final String? activeExecText =
                              (g.executivePower == 'investigate' &&
                                      g.phase == 'executive_investigate')
                                  ? 'Executive Power active: Investigate Loyalty – Headmaster, tap a hat to inspect a wizard.'
                                  : (g.executivePower == 'peek3' &&
                                          g.phase == 'executive_peek3')
                                      ? 'Executive Power active: Foresight – Headmaster, view the next three spells.'
                                      : (g.executivePower == 'choose_next_hm' &&
                                              g.phase == 'executive_choose_hm')
                                          ? 'Executive Power active: Choose the next Headmaster – tap a wizard’s hat.'
                                          : (g.executivePower == 'kill' &&
                                                  g.phase == 'executive_kill')
                                              ? 'Executive Power active: Cast a lethal spell – tap a wizard to eliminate them.'
                                              : null;

                          Widget rolePill(String text) {
                            return Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: width * 0.04,
                                vertical: height * 0.012,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.secondaryBrand.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Text(
                                text,
                                style: TextStyles.bodySmall.copyWith(
                                  color: AppColors.textAccent,
                                  fontSize: height * 0.02,
                                ),
                              ),
                            );
                          }

                          return Stack(
                            children: [
                              // Top-left back button (host only)
                              if (_uid == _creatorId)
                                Positioned(
                                  top: height * 0.02,
                                  left: width * 0.03,
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.arrow_back_ios_new,
                                      color: Colors.white,
                                    ),
                                    style: ButtonStyle(
                                      backgroundColor:
                                          MaterialStateProperty.all(Colors.black.withOpacity(0.4)),
                                      padding: MaterialStateProperty.all(
                                        EdgeInsets.all(width * 0.025),
                                      ),
                                    ),
                                    onPressed: () async {
                                      final confirmed = await showDialog<bool>(
                                        context: context,
                                        builder: (context) => AlertDialog(
                                          backgroundColor: Colors.black87,
                                          title: const Text(
                                            "End Game?",
                                            style: TextStyle(color: Colors.white),
                                          ),
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
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.amberAccent,
                                              ),
                                              child: const Text("Yes, return"),
                                            ),
                                          ],
                                        ),
                                      );
                                      if (confirmed == true) {
                                        await FirebaseFirestore.instance
                                            .collection('states')
                                            .doc(widget.code)
                                            .delete();
                                        await _firebase.resetLobby(widget.code);
                                      }
                                    },
                                  ),
                                ),

                              // Top-center role + exec info
                              Align(
                                alignment: Alignment.topCenter,
                                child: Padding(
                                  padding: EdgeInsets.only(top: height * 0.02),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      rolePill(
                                        isHM
                                            ? 'You are the Headmaster'
                                            : (isSC
                                                ? 'You are the Spellcaster'
                                                : 'Waiting for others...'),
                                      ),
                                      if (activeExecText != null)
                                        Padding(
                                          padding: EdgeInsets.only(top: height * 0.008),
                                          child: Text(
                                            activeExecText,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.amberAccent,
                                              fontSize: height * 0.018,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        )
                                      else if (nextExecHint != null)
                                        Padding(
                                          padding: EdgeInsets.only(top: height * 0.008),
                                          child: Text(
                                            nextExecHint,
                                            textAlign: TextAlign.center,
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: height * 0.017,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ),

                              // POLICY CARD OVERLAY (HM discard / SC choose)
                              if (showHMDiscard || showSCChoose)
                                PolicyOverlay(
                                  game: g,
                                  height: height,
                                  width: width,
                                  isHMPhase: showHMDiscard,
                                ),

                              // VOTING OVERLAY
                              if (showVoting)
                                VotingOverlay(
                                  game: g,
                                  height: height,
                                  width: width,
                                  myVoteCastLocal: _myVoteCastLocal,
                                  onVote: (yes) async {
                                    if (_myVoteCastLocal || g.iVoted) return;
                                    setState(() {
                                      _myVoteCastLocal = true;
                                    });
                                    await g.castVote(yes);
                                  },
                                ),

                              // EXECUTIVE: INVESTIGATE
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
                                  onContinue: () => _firebase.endExecutive(widget.code),
                                ),

                              if (g.phase == 'executive_peek3')
                                ExecutivePeek3Overlay(
                                  game: g,
                                  isHeadmaster: isHM,
                                  height: height,
                                  width: width,
                                  onContinue: () => _firebase.endExecutive(widget.code),
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
                                      _firebase.confirmNextHeadmaster(widget.code),
                                ),

                              if (g.phase == 'executive_kill')
                                ExecutiveKillOverlay(
                                  isHeadmaster: isHM,
                                  height: height,
                                ),

                              //EXECUTIVE KILL RESULT – host only actually resolves
                              if (g.phase == 'executive_kill_result' ||
                                  g.phase == 'executive_kill_result_arch')
                                ExecutiveKillResultOverlay(
                                  game: g,
                                  height: height,
                                  width: width,
                                  isArch: g.phase == 'executive_kill_result_arch',
                                  isHost: isHost,
                                  onContinue: isHost
                                      ? () async {
                                          if (g.phase == 'executive_kill_result_arch') {
                                            // GAME OVER
                                            await FirebaseFirestore.instance
                                                .collection('states')
                                                .doc(widget.code)
                                                .delete();
                                            await _firebase.resetLobby(widget.code);
                                          } else {
                                            await _firebase.finalizeKill(widget.code);
                                          }
                                        }
                                      : null,
                                ),

                              // Spectator hint (only if no blocking overlays)
                              if (!showHMDiscard &&
                                  !showSCChoose &&
                                  !showVoting &&
                                  g.phase != 'executive_investigate' &&
                                  g.phase != 'executive_investigate_result' &&
                                  g.phase != 'executive_peek3' &&
                                  g.phase != 'executive_choose_hm' &&
                                  g.phase != 'executive_kill' &&
                                  g.phase != 'executive_kill_result' &&
                                  g.phase != 'executive_kill_result_arch')
                                Align(
                                  alignment: Alignment.bottomCenter,
                                  child: Padding(
                                    padding: EdgeInsets.only(bottom: height * 0.05),
                                    child: Text(
                                      _spectatorHint(g),
                                      style: TextStyle(
                                        color: Colors.white54,
                                        fontSize: height * 0.018,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },

                      },
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

  String _spectatorHint(WizardGameView g) {
    switch (g.phase) {
      case 'start':
        return 'Headmaster: pick a Spellcaster by tapping a hat.';
      case 'voting':
        return 'Voting in progress…';
      case 'hm_discard':
        return 'Headmaster is discarding 1 card...';
      case 'sc_choose':
        return 'Spellcaster is choosing a card to enact...';
      case 'executive_investigate':
        return 'Headmaster is using Investigate Loyalty…';
      case 'executive_investigate_result':
        return 'Investigation complete – resolving…';
      case 'executive_peek3':
        return 'Headmaster is peeking at the next three spells…';
      case 'executive_choose_hm':
        return 'Headmaster is choosing the next Headmaster…';
      case 'executive_kill':
        return 'A lethal spell is about to be cast…';
      case 'resolving':
        return 'Resolving policy and rotating Headmaster...';
      default:
        return 'Waiting...';
    }
  }

  String? _nextExecutiveWarning(WizardGameView g) {
    final int playerCount = g.players.length;
    final int curses = g.curses;

    // Never show warning DURING an executive power
    if (g.executiveActive == true) return null;

    // 5–6 PLAYERS
    if (playerCount >= 1 && playerCount <= 6) {
      if (curses == 2) {
        return "If the next Curse is enacted: Foresee three spells.";
      }
      if (curses == 3) {
        return "If the next Curse is enacted: Execute a wizard.";
      }
    }

    // 7–8 PLAYERS
    if (playerCount >= 7 && playerCount <= 8) {
      if (curses == 1) {
        return "If the next Curse is enacted: Investigate Loyalty.";
      }
      if (curses == 2) {
        return "If the next Curse is enacted: Foresee three spells.";
      }
      if (curses == 3) {
        return "If the next Curse is enacted: Execute a wizard.";
      }
    }

    // 9–10 PLAYERS
    if (playerCount >= 9 && playerCount <= 10) {
      if (curses == 0) {
        return "If the next Curse is enacted: Investigate Loyalty.";
      }
      if (curses == 1) {
        return "If the next Curse is enacted: Investigate Loyalty.";
      }
      if (curses == 2) {
        return "If the next Curse is enacted: Foresee three spells.";
      }
      if (curses == 3) {
        return "If the next Curse is enacted: Execute a wizard.";
      }
    }

    return null;
  }
}
