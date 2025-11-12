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

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser?.uid;
    final myUid = _uid ?? "unknown";
    _game = WizardGameView(lobbyId: widget.code, myUid: myUid);

    // Switch from lobby music to game music
    AudioHelper.stop();
    
    Future.microtask(() async {
      await AudioHelper.fadeTo('TavernMusic.wav', delayMs: 900);
    });

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
        final status = lobby['status'];
        if (status == 'waiting') {
          WidgetsBinding.instance.addPostFrameCallback((_) => _goBackToLobby());
        }

        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: stateRef.snapshots(),
          builder: (context, stateSnap) {
            if (!stateSnap.hasData) {
              return const Scaffold(
                  body: Center(child: CircularProgressIndicator()));
            }
            if (!stateSnap.data!.exists) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _goBackToLobby());
              return const SizedBox.shrink();
            }

            final data = stateSnap.data!.data()!;
            final phase = data['phase'] ?? 'start';
            _game.phase = phase;

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
                          final showHMDiscard =
                              isHM && g.phase == 'hm_discard' && g.pendingCards.length == 3;
                          final showSCChoose =
                              isSC && g.phase == 'sc_choose' && g.pendingCards.length == 2;

                          // Responsive card builder with staggered fade/scale
                          Widget cardWidget(String type, VoidCallback onTap, int index) {
                            final cardHeight = height * 0.18;
                            final cardWidth  = width  * 0.25;
                            final asset = type == 'charm'
                                ? 'assets/images/game-assets/board/charmCard.png'
                                : 'assets/images/game-assets/board/curseCard.png';

                            return _StaggerFadeScale(
                              delayMs: 150 * index,
                              durationMs: 400,
                              beginScale: 0.9,
                              endScale: 1.0,
                              child: InkWell(
                                onTap: onTap,
                                child: Container(
                                  margin: EdgeInsets.symmetric(horizontal: width * 0.015),
                                  padding: EdgeInsets.all(width * 0.02),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: Colors.white24),
                                  ),
                                  child: Image.asset(
                                    asset,
                                    height: cardHeight,
                                    width: cardWidth,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              ),
                            );
                          }

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

                          Widget buildCardOverlay(
                            String title,
                            List<String> cards,
                            bool isHMPhase,
                          ) {
                            return AnimatedOpacity(
                              opacity: 1,
                              duration: const Duration(milliseconds: 300),
                              child: Container(
                                width: double.infinity,
                                height: double.infinity,
                                color: Colors.black.withOpacity(0.65),
                                child: Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        title,
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: height * 0.025,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      SizedBox(height: height * 0.02),
                                      SizedBox(
                                        width: width * 0.9, // keep margin each side
                                        child: FittedBox(
                                          fit: BoxFit.scaleDown, // shrink if needed
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: List.generate(cards.length, (i) {
                                              final type = cards[i];
                                              return cardWidget(
                                                type,
                                                () => isHMPhase
                                                    ? g.headmasterDiscard(i)
                                                    : g.spellcasterChoose(i),
                                                i,
                                              );
                                            }),
                                          ),
                                        ),
                                      ),

                                    ],
                                  ),
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
                                    icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
                                    style: ButtonStyle(
                                      backgroundColor: MaterialStateProperty.all(
                                        Colors.black.withOpacity(0.4),
                                      ),
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
                                        if (mounted) context.go('/lobby/${widget.code}');
                                      }
                                    },
                                  ),
                                ),

                              Align(
                                alignment: Alignment.topCenter,
                                child: Padding(
                                  padding: EdgeInsets.only(top: height * 0.02),
                                  child: rolePill(
                                    isHM
                                        ? 'You are the Headmaster'
                                        : (isSC ? 'You are the Spellcaster' : 'Waiting for others...'),
                                  ),
                                ),
                              ),

                              // Overlays
                              if (showHMDiscard)
                                buildCardOverlay('Choose 1 spell to discard', g.pendingCards, true),

                              if (showSCChoose)
                                buildCardOverlay('Choose 1 spell to cast', g.pendingCards, false),

                              // Spectator hint
                              if (!showHMDiscard && !showSCChoose)
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
      case 'hm_discard':
        return 'Headmaster is discarding 1 card...';
      case 'sc_choose':
        return 'Spellcaster is choosing a card to enact...';
      case 'resolving':
        return 'Resolving policy and rotating Headmaster...';
      default:
        return 'Waiting...';
    }
  }
}

//Simple helper to add a start delay and fade/scale animation to any child.
class _StaggerFadeScale extends StatefulWidget {
  final Widget child;
  final int delayMs;
  final int durationMs;
  final double beginScale;
  final double endScale;

  const _StaggerFadeScale({
    required this.child,
    required this.delayMs,
    required this.durationMs,
    this.beginScale = 0.9,
    this.endScale = 1.0,
  });

  @override
  State<_StaggerFadeScale> createState() => _StaggerFadeScaleState();
}

class _StaggerFadeScaleState extends State<_StaggerFadeScale>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: widget.durationMs),
    );
    _opacity = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _scale = Tween<double>(begin: widget.beginScale, end: widget.endScale)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));

    // Start after delay
    Future.delayed(Duration(milliseconds: widget.delayMs), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    AudioHelper.stop();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: ScaleTransition(
        scale: _scale,
        child: widget.child,
      ),
    );
  }
}
