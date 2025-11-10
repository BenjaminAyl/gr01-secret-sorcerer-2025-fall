import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:secret_sorcerer/constants/app_colours.dart';
import 'package:secret_sorcerer/constants/app_text_styling.dart';
import 'package:secret_sorcerer/controllers/firebase.dart';
import 'package:secret_sorcerer/controllers/game_controller.dart';
import 'package:secret_sorcerer/views/game_view.dart';

class GameScreen extends StatefulWidget {
  final String code;
  const GameScreen({super.key, required this.code});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  final _firebase = FirebaseController();
  final _controller = GameController();
  late final WizardGameView _game;
  String? _creatorId;
  String? _uid;
  bool _navigatedOut = false;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    final myUid = _uid ?? "unknown";
    _game = WizardGameView(lobbyId: widget.code, myUid: myUid);

  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _maybeStartHostTimer() {
    if (_creatorId != null && _uid == _creatorId) {
      _controller.startCountdown(widget.code, () {});
    }
  }

  void _goBackToLobby() {
    if (_navigatedOut || !mounted) return;
    _navigatedOut = true;
    context.go('/lobby/${widget.code}');
  }

  @override
  Widget build(BuildContext context) {
    final lobbyRef =
        FirebaseFirestore.instance.collection('lobbies').doc(widget.code);
    final stateRef =
        FirebaseFirestore.instance.collection('states').doc(widget.code);

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: lobbyRef.snapshots(),
      builder: (context, lobbySnap) {
        if (!lobbySnap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        if (!lobbySnap.data!.exists) {
          WidgetsBinding.instance.addPostFrameCallback((_) => _goBackToLobby());
          return const SizedBox.shrink();
        }

        final lobby = lobbySnap.data!.data()!;
        _creatorId ??= lobby['creatorId'] as String?;
        final status = lobby['status'];

        if (status == 'waiting') {
          WidgetsBinding.instance.addPostFrameCallback((_) => _goBackToLobby());
        }

        _maybeStartHostTimer();

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: stateRef.snapshots(),
          builder: (context, stateSnap) {
            if (!stateSnap.hasData) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (!stateSnap.data!.exists) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _goBackToLobby());
              return const SizedBox.shrink();
            }

            final data = stateSnap.data!.data()!;
            final phase = data['phase'] ?? 'countdown';
            final time = (data['time'] ?? 10) as int;
            _game.updateCountdown(time);

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
                          final hasSC = g.spellcasterIndex != null;

                          return Align(
                            alignment: Alignment.bottomCenter,
                            child: Padding(
                              padding:
                                  const EdgeInsets.only(bottom: 40, left: 16, right: 16),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 10),
                                    decoration: BoxDecoration(
                                      color: AppColors.secondaryBrand.withOpacity(0.7),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Text(
                                      isHM
                                          ? 'You are the Headmaster'
                                          : isSC
                                              ? 'You are the Spellcaster'
                                              : 'Waiting for others...',
                                      style: TextStyles.bodySmall.copyWith(
                                        color: AppColors.textAccent,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 16),

                                  if (isSC)
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.tealAccent,
                                            foregroundColor: Colors.black,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 32, vertical: 16),
                                          ),
                                          onPressed: () => g.castSpell(true),
                                          child: const Text('Charm',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                        const SizedBox(width: 20),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.redAccent,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(30),
                                            ),
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 32, vertical: 16),
                                          ),
                                          onPressed: () => g.castSpell(false),
                                          child: const Text('Curse',
                                              style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600)),
                                        ),
                                      ],
                                    )
                                  else if (isHM && !hasSC)
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.customAccent,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 40, vertical: 16),
                                      ),
                                      onPressed: () => g.endTurn(),
                                      child: const Text('End Turn',
                                          style: TextStyle(
                                              fontSize: 18,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white)),
                                    )
                                  else
                                    const SizedBox(height: 60),
                                ],
                              ),
                            ),
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
}
